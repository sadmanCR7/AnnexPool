import express from 'express';
import {
  createRideRequest,
  getRideRequests,
  getMyRideRequests,
  getMyRespondedRequests,
  cancelRideRequest,
  completeRideRequest,
  handleRideRequestResponder,
} from '../controllers/rideRequestController.js';
import { protect } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/mine', protect, getMyRideRequests);
router.get('/responded', protect, getMyRespondedRequests);
router.put('/:id/cancel', protect, cancelRideRequest);
router.put('/:id/complete', protect, completeRideRequest);
router.put('/:requestId/responders/:responderId', protect, handleRideRequestResponder);

router.route('/')
  .post(protect, createRideRequest)
  .get(protect, getRideRequests);

export default router;
