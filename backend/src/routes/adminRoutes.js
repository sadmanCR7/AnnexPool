import express from 'express';
import { protect } from '../middlewares/authMiddleware.js';
import { adminOnly } from '../middlewares/adminMiddleware.js';
import {
  getAnalytics,
  getUsers,
  verifyStudentId,
  verifyFemaleRider,
  unverifyStudentId,
  banUser,
  getReports,
  reviewReport,
  getAllOffers,
  getAllRequests,
  adminCancelOffer,
  getActiveSOS,
  resolveSOS,
} from '../controllers/adminController.js';

const router = express.Router();

router.use(protect, adminOnly);

router.get('/analytics', getAnalytics);
router.get('/users', getUsers);
router.put('/users/:id/verify-student', verifyStudentId);
router.put('/users/:id/unverify-student', unverifyStudentId);
router.put('/users/:id/verify-female', verifyFemaleRider);
router.put('/users/:id/ban', banUser);
router.get('/reports', getReports);
router.put('/reports/:id', reviewReport);
router.get('/rides/offers', getAllOffers);
router.get('/rides/requests', getAllRequests);
router.put('/rides/offers/:id/cancel', adminCancelOffer);
router.get('/sos', getActiveSOS);
router.put('/sos/:id/resolve', resolveSOS);

export default router;
