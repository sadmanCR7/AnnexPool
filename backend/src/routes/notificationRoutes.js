import express from 'express';
import {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  registerFcmToken,
} from '../controllers/notificationController.js';
import { protect } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/', protect, getNotifications);
router.get('/unread-count', protect, getUnreadCount);
router.put('/read-all', protect, markAllAsRead);
router.post('/fcm-token', protect, registerFcmToken);
router.put('/:id/read', protect, markAsRead);

export default router;
