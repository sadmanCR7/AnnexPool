import Chat from '../models/Chat.js';
import Message from '../models/Message.js';
import Report from '../models/Report.js';
import RideOffer from '../models/RideOffer.js';
import RideRequest from '../models/RideRequest.js';
import Rating from '../models/Rating.js';
import {
  getOrCreateChat,
  getOrCreateChatForRequest,
  formatParticipantNameForViewer,
  getRouteLabel,
  participantUserId,
  isChatInitiator,
  getParticipant,
  revealParticipantIdentity,
  canViewerSeeOtherProfile,
  canViewerSeeOtherAvatar,
  getOtherParticipant,
  userCanAccessChat,
  repairChatParticipants,
  populateRideRefs,
} from '../services/chatService.js';
import { createNotification } from '../services/notificationService.js';

const populateChat = (query) =>
  query
    .populate('rideOffer', 'source destination travelDate travelTime status driver passengers')
    .populate('rideRequest', 'source destination travelDate travelTime status rider responders')
    .populate('participants.user', 'name avatarUrl role isStudentIdVerified');

const chatStartedText = (chat) => `Chat started for the route ${getRouteLabel(chat)}`;
const chatClosedText = (chat) => `Chat closed for the route ${getRouteLabel(chat)}`;
const isSystemRouteMessage = (content) =>
  content.startsWith('Chat started for the route') ||
  content.startsWith('Chat closed for the route') ||
  content.startsWith('Accepted the request for the route') ||
  content.startsWith('Declined the request for the route');

// @desc    List user's chats
// @route   GET /api/chats
export const getMyChats = async (req, res) => {
  try {
    // Find chats where user is in participants
    const directChats = await populateRideRefs(
      populateChat(
        Chat.find({
          'participants.user': req.user._id,
          blockedBy: { $ne: req.user._id },
        }).sort({ lastMessageAt: -1, updatedAt: -1 })
      )
    );

    // Also find chats linked to rides user is part of (driver/passenger/rider/responder)
    const RideOffer = (await import('../models/RideOffer.js')).default;
    const RideRequest = (await import('../models/RideRequest.js')).default;

    const offerIds = await RideOffer.find({
      $or: [
        { driver: req.user._id },
        { 'passengers.rider': req.user._id },
      ],
    }).distinct('_id');

    const requestIds = await RideRequest.find({
      $or: [
        { rider: req.user._id },
        { 'responders.user': req.user._id },
      ],
    }).distinct('_id');

    const rideChats = await populateRideRefs(
      populateChat(
        Chat.find({
          $or: [
            { rideOffer: { $in: offerIds } },
            { rideRequest: { $in: requestIds } },
          ],
          blockedBy: { $ne: req.user._id },
        }).sort({ lastMessageAt: -1, updatedAt: -1 })
      )
    );

    // Merge, dedup by chat id
    const chatMap = new Map();
    for (const c of directChats) chatMap.set(c._id.toString(), c);
    for (const c of rideChats) {
      if (!chatMap.has(c._id.toString())) chatMap.set(c._id.toString(), c);
    }
    const initialChats = [...chatMap.values()];

    const accessibleIds = [];
    for (const chat of initialChats) {
      const repaired = await repairChatParticipants(chat);
      if (await userCanAccessChat(repaired, req.user._id)) {
        accessibleIds.push(repaired._id.toString());
      }
    }

    const order = new Map(accessibleIds.map((id, index) => [id, index]));
    const accessible = accessibleIds.length
      ? await populateRideRefs(
          populateChat(
            Chat.find({
              _id: { $in: accessibleIds },
              blockedBy: { $ne: req.user._id },
            })
          )
        )
      : [];
    accessible.sort(
      (a, b) => order.get(a._id.toString()) - order.get(b._id.toString())
    );

    const formatted = accessible.map((chat) => {
      const userId = req.user._id.toString();
      const initiator = isChatInitiator(chat, userId);
      const other = getOtherParticipant(chat, userId);
      const routeLabel = getRouteLabel(chat);
      const showAvatar = canViewerSeeOtherAvatar(chat, other);

      return {
        _id: chat._id,
        rideOffer: chat.rideOffer,
        rideRequest: chat.rideRequest,
        routeLabel,
        isAnonymous: false,
        isInitiator: initiator,
        lastMessage: chat.lastMessage,
        lastMessageAt: chat.lastMessageAt,
        otherParticipant: other
          ? {
              _id: other.user._id,
              displayName: formatParticipantNameForViewer(
                chat,
                other.user,
                other.user,
                userId
              ),
              role: other.role,
              avatarUrl: showAvatar ? other.user.avatarUrl : null,
              identityRevealed: other.identityRevealed === true,
              isStudentIdVerified: other.user.isStudentIdVerified === true,
            }
          : null,
      };
    });

    res.json(formatted);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get or create chat for a ride offer
// @route   POST /api/chats/ride/:rideOfferId
export const startChatForRide = async (req, res) => {
  try {
    const { chat, isNew } = await getOrCreateChat(req.params.rideOfferId, req.user._id);
    
    if (isNew) {
      await chat.populate('rideOffer rideRequest');
      await saveMessage(chat._id, req.user._id, chatStartedText(chat), req.app.get('io'));
    }
    
    const populated = await populateChat(Chat.findById(chat._id));
    res.status(201).json(populated);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// @desc    Get or create chat for a ride request
// @route   POST /api/chats/request/:rideRequestId
export const startChatForRequest = async (req, res) => {
  try {
    const kind = req.body?.kind === 'driver_offer' ? 'driver_offer' : 'co_rider';
    const { chat, isNew } = await getOrCreateChatForRequest(
      req.params.rideRequestId, 
      req.user._id,
      kind
    );

    const request = await RideRequest.findById(req.params.rideRequestId);
    if (request) {
      const existingResponder = request.responders.find(
        (responder) => responder.user.toString() === req.user._id.toString()
      );
      if (!existingResponder) {
        request.responders.push({
          user: req.user._id,
          chat: chat._id,
          kind: req.body?.kind === 'driver_offer' ? 'driver_offer' : 'co_rider',
          status: 'Pending',
        });
        await request.save();
      } else if (!existingResponder.chat) {
        existingResponder.chat = chat._id;
        await request.save();
      }

      await createNotification({
        userId: request.rider,
        type: 'ride',
        title: req.body?.kind === 'driver_offer' ? 'New Ride Offer' : 'New Co-rider Request',
        body: `${req.user.name} wants to join you on ${request.source} to ${request.destination}.`,
        data: { rideRequestId: request._id, responderId: req.user._id, chatId: chat._id },
      });
    }

    if (isNew) {
      await chat.populate('rideOffer rideRequest');
      await saveMessage(
        chat._id, 
        req.user._id, 
        chatStartedText(chat),
        req.app.get('io')
      );
    }

    const populated = await populateChat(Chat.findById(chat._id));
    res.status(201).json(populated);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// @desc    Get messages for a chat
// @route   GET /api/chats/:id/messages
export const getChatMessages = async (req, res) => {
  try {
    let chat = await populateRideRefs(
      populateChat(Chat.findById(req.params.id))
    );
    if (!chat) return res.status(404).json({ message: 'Chat not found' });

    // Repair participants first to ensure they are synchronized with ride request/offer state
    chat = await repairChatParticipants(chat);
    // Re-populate after repair to ensure we have the latest participant users
    chat = await populateRideRefs(populateChat(Chat.findById(chat._id)));

    const canAccess = await userCanAccessChat(chat, req.user._id);
    if (!canAccess) {
      return res.status(403).json({ message: 'You are not part of this chat' });
    }

    // If user has access but isn't in participants, add them directly
    const uid = req.user._id.toString();
    const inParticipants = chat.participants.some((p) => participantUserId(p) === uid);
    if (!inParticipants) {
      const existingRoles = chat.participants.map((p) => p.role);
      const role = existingRoles.includes('rider') ? 'driver' : 'rider';
      chat.participants.push({
        user: req.user._id,
        role,
        identityRevealed: true,
      });
      chat.markModified('participants');
      await chat.save();
      // Re-populate with updated participants
      chat = await populateRideRefs(populateChat(Chat.findById(chat._id)));
    }

    const participantIds = chat.participants.map((p) => participantUserId(p));

    const messages = await Message.find({
      chat: chat._id,
    })
      .populate('sender', 'name avatarUrl')
      .sort({ createdAt: 1 })
      .limit(200);

    const userId = req.user._id.toString();
    const initiator = isChatInitiator(chat, userId);
    const me = getParticipant(chat, userId);
    const other = getOtherParticipant(chat, userId);
    const routeLabel = getRouteLabel(chat);

    const formatted = messages.map((msg) => ({
      _id: msg._id,
      content: msg.content,
      createdAt: msg.createdAt,
      isSystem: isSystemRouteMessage(msg.content),
      isMine: !isSystemRouteMessage(msg.content) && msg.sender._id.toString() === userId,
      senderName:
        isSystemRouteMessage(msg.content)
          ? 'AnnexPool'
          :
        msg.sender._id.toString() === userId
          ? 'You'
          : formatParticipantNameForViewer(chat, msg.sender, msg.sender, userId),
      senderAvatarUrl: msg.sender.avatarUrl,
    }));

    const otherParticipant = other && other.user
      ? {
          _id: other.user._id,
          displayName: formatParticipantNameForViewer(
            chat,
            other.user,
            other.user,
            userId
          ),
          avatarUrl: canViewerSeeOtherAvatar(chat, other) ? other.user.avatarUrl : null,
          identityRevealed: other.identityRevealed === true,
          canViewProfile: canViewerSeeOtherProfile(chat, userId, other),
          isStudentIdVerified: other.user.isStudentIdVerified === true,
        }
      : null;

    res.json({
      chat: {
        _id: chat._id,
        isAnonymous: false,
        isInitiator: initiator,
        myIdentityRevealed: me?.identityRevealed === true,
        routeLabel,
        showAnonymousToOtherBadge: false,
        showAnonymousSenderNotice: false,
        isClosed: chat.closedAt != null,
        closedAt: chat.closedAt,
        rideOffer: chat.rideOffer,
        rideRequest: chat.rideRequest,
      },
      messages: formatted,
      otherParticipant,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Block user in chat context
// @route   POST /api/chats/:id/block
export const blockChatUser = async (req, res) => {
  try {
    const chat = await Chat.findById(req.params.id);
    if (!chat) return res.status(404).json({ message: 'Chat not found' });

    const other = getOtherParticipant(chat, req.user._id);
    if (!other) return res.status(400).json({ message: 'No other participant' });

    if (!chat.blockedBy.includes(req.user._id)) {
      chat.blockedBy.push(req.user._id);
      await chat.save();
    }

    res.json({ message: 'User blocked for this chat' });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Report user misconduct
// @route   POST /api/chats/:id/report
export const reportChatUser = async (req, res) => {
  try {
    const { reason, details } = req.body;
    if (!reason || !String(reason).trim()) {
      return res.status(400).json({ message: 'Reason is required' });
    }

    const chat = await Chat.findById(req.params.id);
    if (!chat) return res.status(404).json({ message: 'Chat not found' });

    const other = getOtherParticipant(chat, req.user._id);
    if (!other) return res.status(400).json({ message: 'No other participant' });

    const reportedUserId = participantUserId(other);

    await Report.create({
      reporter: req.user._id,
      reportedUser: reportedUserId,
      chat: chat._id,
      reason: String(reason).trim(),
      details,
    });

    await createNotification({
      userId: reportedUserId,
      type: 'system',
      title: 'Warning: Community Guidelines',
      body: `Your account was reported for: ${String(reason).trim()}. Please review our safety guidelines.`,
      data: { chatId: chat._id.toString() },
    });

    res.status(201).json({ message: 'Report submitted. Our team will review it.' });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// Used by socket handler
export const saveMessage = async (chatId, senderId, content, io, senderSocketId = null) => {
  const chat = await populateRideRefs(
    Chat.findById(chatId).populate('participants.user', 'name avatarUrl isStudentIdVerified')
  );
  if (!chat) throw new Error('Chat not found');

  if (chat.blockedBy.some((id) => id.toString() === senderId.toString())) {
    throw new Error('Chat is blocked');
  }

  // Removed closedAt check so users can chat indefinitely

  const senderIdStr = senderId.toString();
  let isParticipant = chat.participants.some(
    (p) => participantUserId(p) === senderIdStr
  );
  if (!isParticipant) {
    isParticipant = await userCanAccessChat(chat, senderId);
    if (isParticipant) {
      // User has legitimate access but isn't in participants array.
      // Add them directly rather than relying on repair (which may early-return).
      const existingRoles = chat.participants.map((p) => p.role);
      const role = existingRoles.includes('rider') ? 'driver' : 'rider';
      chat.participants.push({
        user: senderId,
        role,
        identityRevealed: true,
      });
      chat.markModified('participants');
      await chat.save();
      // Re-fetch so participants array is fully populated
      const refreshed = await populateRideRefs(
        Chat.findById(chatId).populate('participants.user', 'name avatarUrl isStudentIdVerified')
      );
      if (refreshed) Object.assign(chat, refreshed.toObject ? refreshed.toObject() : refreshed);
    }
  }
  if (!isParticipant) throw new Error('Not a participant');

  const message = await Message.create({
    chat: chatId,
    sender: senderId,
    content: content.trim(),
  });

  chat.lastMessage = content.trim().slice(0, 120);
  chat.lastMessageAt = new Date();
  await chat.save();

  const sender = chat.participants.find((p) => participantUserId(p) === senderIdStr);
  const chatIdStr = chatId.toString();
  const senderIsInitiator = isChatInitiator(chat, senderIdStr);
  const senderUser = sender?.user || null;
  const senderName = senderUser
    ? formatParticipantNameForViewer(chat, senderUser, senderUser, senderIdStr)
    : 'User';
  const payload = {
    _id: message._id.toString(),
    chatId: chatIdStr,
    content: message.content,
    createdAt: message.createdAt,
    senderId: senderIdStr,
    senderRevealed: sender?.identityRevealed === true,
    senderIsInitiator,
    routeLabel: getRouteLabel(chat),
    isAnonymous: chat.isAnonymous,
    senderName,
    senderAvatarUrl: senderUser?.avatarUrl,
    isSystem: isSystemRouteMessage(message.content),
  };

  if (io) {
    const room = io.to(`chat:${chatIdStr}`);
    const emitter = senderSocketId ? room.except(senderSocketId) : room;
    emitter.emit('message_received', payload);
    // Confirm to sender with server id (avoids duplicate optimistic + socket rows).
    if (senderSocketId) {
      io.to(senderSocketId).emit('message_sent', payload);
    }
  }

  const recipient = getOtherParticipant(chat, senderIdStr);
  if (recipient) {
    const routeName = getRouteLabel(chat);
    await createNotification({
      userId: participantUserId(recipient),
      type: 'chat',
      title: `New Message - ${routeName}`,
      body: `${senderName}: ${content.trim().slice(0, 80)}`,
      data: { chatId: chatIdStr },
    });
  }

  return payload;
};

// @desc    Driver starts chat with a passenger on their offer
// @route   POST /api/chats/ride/:rideOfferId/rider/:riderId
export const startChatAsDriver = async (req, res) => {
  try {
    const offer = await RideOffer.findById(req.params.rideOfferId);
    if (!offer || offer.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const passenger = offer.passengers.find(
      (p) => p.rider.toString() === req.params.riderId
    );
    if (!passenger) {
      return res.status(400).json({ message: 'Passenger not found on this ride' });
    }

    const { chat, isNew } = await getOrCreateChat(req.params.rideOfferId, req.params.riderId);
    
    if (isNew) {
      await saveMessage(
        chat._id,
        req.user._id,
        'Hi, I am the driver for this ride.',
        req.app.get('io')
      );
    }

    const populated = await populateChat(Chat.findById(chat._id));
    res.json(populated);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// @desc    Reveal own identity (chat initiator only; does not reveal the other person)
// @route   PUT /api/chats/:id/reveal
export const revealIdentity = async (req, res) => {
  try {
    const chat = await revealParticipantIdentity(req.params.id, req.user._id);

    const io = req.app.get('io');
    if (io) {
      io.to(`chat:${chat._id}`).emit('chat_updated', {
        chatId: chat._id.toString(),
        userId: req.user._id.toString(),
        identityRevealed: true,
      });
    }

    const populated = await populateChat(Chat.findById(chat._id));
    res.json(populated);
  } catch (error) {
    const status = error.message?.includes('Only the person who started') ? 403 : 400;
    res.status(status).json({ message: error.message || 'Server error' });
  }
};
