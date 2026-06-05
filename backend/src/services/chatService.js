import Chat from '../models/Chat.js';
import RideOffer from '../models/RideOffer.js';
import RideRequest from '../models/RideRequest.js';

export const participantUserId = (participant) => {
  const user = participant?.user;
  if (!user) return '';
  if (typeof user === 'string') return user;
  return (user._id ?? user).toString();
};

const refUserId = (value) => (value?._id ?? value)?.toString();

/** Who started the chat: rider on offers, driver/co-rider on requests (legacy fallback). */
export const getChatInitiatorRole = (chat) => (chat.rideRequest ? 'driver' : 'rider');

export const isChatInitiator = (chat, userId) => {
  const uid = userId.toString();
  if (chat.initiatorUser) {
    return chat.initiatorUser.toString() === uid;
  }
  const initiatorRole = getChatInitiatorRole(chat);
  const participant = chat.participants.find((p) => participantUserId(p) === uid);
  return participant?.role === initiatorRole;
};

export const getParticipant = (chat, userId) =>
  chat.participants.find((p) => participantUserId(p) === userId.toString());

export const getOtherParticipant = (chat, userId) => {
  const uid = userId.toString();
  return chat.participants.find((p) => {
    const participantId = participantUserId(p);
    return participantId && participantId !== uid;
  });
};

export const getRouteLabel = (chat) => {
  const ride = chat.rideOffer || chat.rideRequest;
  if (!ride) return 'Ride chat';
  const source = ride.source || 'Unknown';
  const destination = ride.destination || 'Unknown';
  return `${source} ➔ ${destination}`;
};

const populateRideRefs = (query) =>
  query
    .populate('rideOffer', 'source destination travelDate travelTime status driver passengers')
    .populate('rideRequest', 'source destination travelDate travelTime status rider responders');

export const formatParticipantNameForViewer = (
  chat,
  targetUser,
  populatedUser,
  viewerUserId
) => {
  void chat;
  void targetUser;
  void viewerUserId;
  return populatedUser?.name || 'User';
};

export const formatParticipantName = (chat, user, populatedUser) =>
  formatParticipantNameForViewer(chat, user, populatedUser, participantUserId(user));

export const canViewerSeeOtherProfile = (chat, viewerUserId, otherParticipant) => {
  void chat;
  void viewerUserId;
  if (!otherParticipant) return false;
  return true;
};

export const canViewerSeeOtherAvatar = (chat, otherParticipant) => {
  void chat;
  if (!otherParticipant) return false;
  return true;
};

export const userCanAccessChat = async (chat, userId) => {
  const uid = userId.toString();
  if (chat.participants?.some((p) => participantUserId(p) === uid)) {
    return true;
  }

  if (chat.rideOffer) {
    const offer =
      chat.rideOffer?.driver != null
        ? chat.rideOffer
        : await RideOffer.findById(chat.rideOffer);
    if (!offer) return false;
    if (refUserId(offer.driver) === uid) return true;
    if (offer.passengers.some((p) => refUserId(p.rider) === uid)) return true;
  }

  if (chat.rideRequest) {
    const request =
      chat.rideRequest?.rider != null
        ? chat.rideRequest
        : await RideRequest.findById(chat.rideRequest).select('rider responders');
    if (!request) return false;
    const riderId = refUserId(request.rider);
    if (riderId === uid) return true;

    // Accept responder if their chat field matches OR is unset (race condition on creation)
    const isResponder = request.responders?.some((r) => {
      if (refUserId(r.user) !== uid) return false;
      if (!r.chat) return true; // chat link not yet persisted
      return refUserId(r.chat) === chat._id.toString();
    });
    if (isResponder) return true;

    // Fallback: check the driver participant slot
    const driver = chat.participants.find((p) => p.role === 'driver');
    return driver ? participantUserId(driver) === uid : false;
  }

  return false;
};

/** Ensure both ride participants exist on the chat document. */
export const repairChatParticipants = async (chat) => {
  if (chat.participants && chat.participants.length >= 2 && chat.participants.every(p => p.user)) {
    return chat;
  }
  if (chat.rideOffer) {
    const offer =
      chat.rideOffer?.driver != null
        ? chat.rideOffer
        : await RideOffer.findById(chat.rideOffer);
    if (!offer) return chat;

    const driverId = refUserId(offer.driver);
    const initiatedBy = refUserId(chat.initiatorUser);
    const existingRider = chat.participants.find(
      (p) => p.role === 'rider' && participantUserId(p) !== driverId
    );
    const passengerFromOffer = offer.passengers?.find(
      (p) => p.rider?.toString() !== driverId
    )?.rider?.toString();
    const riderId =
      participantUserId(existingRider) ||
      (initiatedBy !== driverId ? initiatedBy : null) ||
      passengerFromOffer;

    const nextParticipants = [];
    if (driverId) {
      nextParticipants.push({ user: driverId, role: 'driver', identityRevealed: true });
    }
    if (riderId && riderId !== driverId) {
      nextParticipants.push({ user: riderId, role: 'rider', identityRevealed: true });
    }

    const currentSignature = chat.participants
      .map((p) => `${participantUserId(p)}:${p.role}:${p.identityRevealed === true}`)
      .sort()
      .join('|');
    const nextSignature = nextParticipants
      .map((p) => `${p.user}:${p.role}:true`)
      .sort()
      .join('|');
    let changed = false;

    if (nextParticipants.length >= 2 && currentSignature !== nextSignature) {
      chat.participants = nextParticipants;
      changed = true;
    }
    if (!chat.initiatorUser && riderId) {
      chat.initiatorUser = riderId;
      changed = true;
    }
    if (changed) {
      chat.markModified('participants');
      await chat.save();
    }
    return chat;
  }

  if (chat.rideRequest) {
    const request =
      chat.rideRequest?.responders != null
        ? chat.rideRequest
        : await RideRequest.findById(chat.rideRequest).select('rider responders');
    if (!request) return chat;

    const riderId = refUserId(request.rider);
    const initiatedBy = refUserId(chat.initiatorUser);
    const existingResponder = chat.participants.find(
      (p) => participantUserId(p) && participantUserId(p) !== riderId
    );
    // Find the responder linked to THIS chat (or the first one if chat link unset)
    const responderFromRequest =
      request.responders?.find((r) => r.chat?.toString() === chat._id.toString())?.user?.toString() ||
      (chat.participants.length === 0 ? request.responders?.[0]?.user?.toString() : null);
    const driverId =
      participantUserId(existingResponder) ||
      (initiatedBy !== riderId ? initiatedBy : null) ||
      responderFromRequest;

    const nextParticipants = [];
    if (riderId) {
      nextParticipants.push({ user: riderId, role: 'rider', identityRevealed: true });
    }
    if (driverId && driverId !== riderId) {
      nextParticipants.push({ user: driverId, role: 'driver', identityRevealed: true });
    }

    const currentSignature = chat.participants
      .map((p) => `${participantUserId(p)}:${p.role}:${p.identityRevealed === true}`)
      .sort()
      .join('|');
    const nextSignature = nextParticipants
      .map((p) => `${p.user}:${p.role}:true`)
      .sort()
      .join('|');
    let changed = false;

    if (nextParticipants.length >= 2 && currentSignature !== nextSignature) {
      chat.participants = nextParticipants;
      changed = true;
    }
    if (!chat.initiatorUser && driverId) {
      chat.initiatorUser = driverId;
      changed = true;
    }
    if (changed) {
      chat.markModified('participants');
      await chat.save();
    }
  }

  return chat;
};

export const getOrCreateChat = async (rideOfferId, riderId, options = {}) => {
  void options;
  const offer = await RideOffer.findById(rideOfferId);
  if (!offer) throw new Error('Ride offer not found');

  if (offer.driver.toString() === riderId.toString()) {
    throw new Error('You cannot chat on your own ride offer');
  }

  const passenger = offer.passengers.find((p) => p.rider.toString() === riderId.toString());
  if (!passenger) throw new Error('Join the ride before starting a chat');

  let chat = await Chat.findOne({
    rideOffer: rideOfferId,
    'participants.user': riderId,
  });

  let isNew = false;
  if (!chat) {
    chat = await Chat.create({
      rideOffer: rideOfferId,
      isAnonymous: false,
      initiatorUser: riderId,
      participants: [
        { user: offer.driver, role: 'driver', identityRevealed: true },
        { user: riderId, role: 'rider', identityRevealed: true },
      ],
    });
    isNew = true;
  } else {
    chat.participants.forEach((participant) => {
      participant.identityRevealed = true;
    });
    chat.isAnonymous = false;
    if (!chat.initiatorUser) {
      chat.initiatorUser = riderId;
    }
    chat.markModified('participants');
    await chat.save();
  }

  return { chat, isNew };
};

export const getOrCreateChatForRequest = async (rideRequestId, myUserId, options = {}) => {
  void options;
  const request = await RideRequest.findById(rideRequestId).populate('rider');
  if (!request) throw new Error('Ride request not found');

  if (request.rider._id.toString() === myUserId.toString()) {
    throw new Error('You cannot chat on your own ride request');
  }

  let chat = await Chat.findOne({
    rideRequest: rideRequestId,
    'participants.user': myUserId,
  });

  let isNew = false;
  if (!chat) {
    chat = await Chat.create({
      rideRequest: rideRequestId,
      isAnonymous: false,
      initiatorUser: myUserId,
      participants: [
        { user: request.rider._id, role: 'rider', identityRevealed: true },
        { user: myUserId, role: 'driver', identityRevealed: true },
      ],
    });
    isNew = true;
  } else {
    chat.participants.forEach((participant) => {
      participant.identityRevealed = true;
    });
    chat.isAnonymous = false;
    if (!chat.initiatorUser) {
      chat.initiatorUser = myUserId;
    }
    chat.markModified('participants');
    await chat.save();
  }

  return { chat, isNew };
};

export const revealParticipantIdentity = async (chatId, userId) => {
  const chat = await Chat.findById(chatId);
  if (!chat) throw new Error('Chat not found');

  if (!isChatInitiator(chat, userId)) {
    throw new Error('Only the person who started this chat can reveal their identity');
  }

  const participant = getParticipant(chat, userId);
  if (!participant) throw new Error('Not a participant');

  participant.identityRevealed = true;
  chat.markModified('participants');
  await chat.save();
  return chat;
};

export { populateRideRefs };
