import Notification from '../models/Notification.js';
import User from '../models/User.js';

// @route GET /api/notifications
export const getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50);
    res.json(notifications);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/notifications/unread-count
export const getUnreadCount = async (req, res) => {
  try {
    const count = await Notification.countDocuments({ user: req.user._id, isRead: false });
    res.json({ count });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/notifications/:id/read
export const markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { isRead: true },
      { new: true }
    );
    if (!notification) return res.status(404).json({ message: 'Notification not found' });
    res.json(notification);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/notifications/read-all
export const markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany({ user: req.user._id, isRead: false }, { isRead: true });
    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route POST /api/notifications/fcm-token
export const registerFcmToken = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ message: 'FCM token is required' });

    await User.findByIdAndUpdate(req.user._id, { fcmToken: token });
    res.json({ message: 'FCM token registered (push delivery when Firebase is configured)' });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};
