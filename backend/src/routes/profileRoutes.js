const express = require('express');
const { getProfile, updateProfile } = require('../controllers/profileController');
const { protect } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

const router = express.Router();

router.get('/', protect, getProfile);
// The 'photo' matches the form field name from frontend
router.put('/', protect, upload.single('photo'), updateProfile);

module.exports = router;