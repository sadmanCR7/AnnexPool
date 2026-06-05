import express from 'express';
import {
  getMyChats,
  startChatForRide,
  startChatAsDriver,
  startChatForRequest,
  getChatMessages,
  blockChatUser,
  reportChatUser,
  revealIdentity,
} from '../controllers/chatController.js';
import { protect } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/', protect, getMyChats);
router.post('/ride/:rideOfferId', protect, startChatForRide);
router.post('/ride/:rideOfferId/rider/:riderId', protect, startChatAsDriver);
router.post('/request/:rideRequestId', protect, startChatForRequest);
router.get('/:id/messages', protect, getChatMessages);
router.post('/:id/block', protect, blockChatUser);
router.post('/:id/report', protect, reportChatUser);
router.put('/:id/reveal', protect, revealIdentity);

export default router;
