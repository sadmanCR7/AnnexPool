import express from 'express';
import {
  getUserProfile,
  getPublicUserProfile,
  updateUserProfile,
  uploadAvatar,
} from '../controllers/profileController.js';
import { protect } from '../middlewares/authMiddleware.js';
import { avatarUpload } from '../middlewares/uploadMiddleware.js';

const router = express.Router();

router.route('/profile')
  .get(protect, getUserProfile)
  .put(protect, updateUserProfile);

router.get('/public/:id', protect, getPublicUserProfile);

router.post(
  '/profile/avatar',
  protect,
  avatarUpload.single('avatar'),
  uploadAvatar
);

export default router;
