import express from 'express';
import {
  submitRating,
  getUserRatings,
  getPendingRating,
} from '../controllers/ratingController.js';
import { protect } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.post('/', protect, submitRating);
router.get('/user/:userId', protect, getUserRatings);
router.get('/pending/:rideOfferId', protect, getPendingRating);

export default router;
