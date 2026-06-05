import express from 'express';
import {
  createRideOffer,
  getRideOffers,
  getMyRideOffers,
  getMyJoinedOffers,
  joinRideOffer,
  handlePassengerRequest,
  cancelRideOffer,
  completeRideOffer,
} from '../controllers/rideOfferController.js';
import { protect } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/mine', protect, getMyRideOffers);
router.get('/joined', protect, getMyJoinedOffers);
router.post('/', protect, createRideOffer);
router.get('/', protect, getRideOffers);
router.post('/:id/join', protect, joinRideOffer);
router.put('/:offerId/passengers/:passengerId', protect, handlePassengerRequest);
router.put('/:id/cancel', protect, cancelRideOffer);
router.put('/:id/complete', protect, completeRideOffer);

export default router;
