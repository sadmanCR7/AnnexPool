import Notification from '../models/Notification.js';
import { getIo } from '../config/io.js';

export const createNotification = async ({ userId, type, title, body, data = {} }) => {
  const notification = await Notification.create({
    user: userId,
    type,
    title,
    body,
    data,
  });

  const io = getIo();
  if (io) {
    io.to(`user:${userId}`).emit('notification', {
      _id: notification._id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      data: notification.data,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    });
  }

  return notification;
};

export const notifyMany = async (userIds, payload) => {
  const unique = [...new Set(userIds.map((id) => id.toString()))];
  return Promise.all(unique.map((userId) => createNotification({ userId, ...payload })));
};
