import express from 'express';
import {
  updateSafetyPreferences,
  getSafetyPreferences,
  triggerSOS,
  getMySOSAlerts,
  reportMisconduct,
} from '../controllers/safetyController.js';
import { protect } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/preferences', protect, getSafetyPreferences);
router.put('/preferences', protect, updateSafetyPreferences);
router.post('/sos', protect, triggerSOS);
router.get('/sos/mine', protect, getMySOSAlerts);
router.post('/report', protect, reportMisconduct);

export default router;
