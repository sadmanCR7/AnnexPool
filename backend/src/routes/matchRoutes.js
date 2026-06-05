import express from 'express';
import { getMatchSuggestions, getMatchesForRequest } from '../controllers/matchController.js';
import { protect } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/', protect, getMatchSuggestions);
router.get('/for-request/:id', protect, getMatchesForRequest);

export default router;
