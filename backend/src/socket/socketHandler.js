import { verifyToken } from '../utils/jwt.js';
import User from '../models/User.js';
import Chat from '../models/Chat.js';
import { saveMessage } from '../controllers/chatController.js';
import { participantUserId, userCanAccessChat, repairChatParticipants, populateRideRefs } from '../services/chatService.js';

const onlineUsers = new Map();

export const initSocket = (io) => {
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('Authentication required'));

      const decoded = verifyToken(token);
      const user = await User.findById(decoded.id).select('-password');
      if (!user) return next(new Error('User not found'));

      socket.user = user;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user._id.toString();
    onlineUsers.set(userId, socket.id);
    socket.join(`user:${userId}`);
    io.emit('user_online', { userId: socket.user._id, online: true });

    socket.on('join_chat', async ({ chatId }) => {
      if (!chatId) return;

      let chat = await populateRideRefs(
        Chat.findById(chatId).populate('participants.user', 'name avatarUrl')
      );
      if (!chat) return;

      // Repair participants first to ensure they are synchronized with ride request/offer state
      chat = await repairChatParticipants(chat);
      // Re-populate after repair to ensure we have the latest participant users
      chat = await populateRideRefs(
        Chat.findById(chat._id).populate('participants.user', 'name avatarUrl')
      );

      // Verify access after repair
      let canAccess = chat.participants.some(
        (p) => participantUserId(p) === userId
      );
      if (!canAccess) {
        canAccess = await userCanAccessChat(chat, userId);
      }
      if (!canAccess) return;

      // Leave other chat rooms so messages from other conversations are not received.
      for (const room of socket.rooms) {
        if (room.startsWith('chat:')) {
          socket.leave(room);
        }
      }

      socket.join(`chat:${chatId}`);
      socket.data.activeChatId = chatId.toString();
      socket.emit('joined_chat', { chatId: chatId.toString() });
    });

    socket.on('leave_chat', ({ chatId }) => {
      if (!chatId) return;
      socket.leave(`chat:${chatId}`);
      if (socket.data.activeChatId === chatId.toString()) {
        socket.data.activeChatId = null;
      }
    });

    socket.on('send_message', async ({ chatId, content }) => {
      try {
        if (!content?.trim() || !chatId) return;
        await saveMessage(chatId, socket.user._id, content, io, socket.id);
      } catch (err) {
        socket.emit('chat_error', { message: err.message });
      }
    });

    socket.on('typing_start', ({ chatId }) => {
      socket.to(`chat:${chatId}`).emit('typing', {
        chatId,
        userId: socket.user._id,
        isTyping: true,
      });
    });

    socket.on('typing_stop', ({ chatId }) => {
      socket.to(`chat:${chatId}`).emit('typing', {
        chatId,
        userId: socket.user._id,
        isTyping: false,
      });
    });

    socket.on('disconnect', () => {
      onlineUsers.delete(socket.user._id.toString());
      io.emit('user_online', { userId: socket.user._id, online: false });
    });
  });
};

export const isUserOnline = (userId) => onlineUsers.has(userId.toString());
