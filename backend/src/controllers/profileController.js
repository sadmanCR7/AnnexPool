import User from '../models/User.js';

// @desc    Get user profile
// @route   GET /api/users/profile
// @access  Private
export const getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (user) {
      res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        studentId: user.studentId,
        isStudentIdVerified: user.isStudentIdVerified,
        avatarUrl: user.avatarUrl,
        emergencyContacts: user.emergencyContacts,
        gender: user.gender,
        isVerifiedFemale: user.isVerifiedFemale,
        preferWomenOnlyRides: user.preferWomenOnlyRides,
        trustScore: user.trustScore,
        ratingCount: user.ratingCount,
      });
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get public profile (used for chat/requests)
// @route   GET /api/users/public/:id
// @access  Private (authenticated)
export const getPublicUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isAdmin = req.user.role === 'Admin';

    const data = {
      _id: user._id,
      name: user.name,
      avatarUrl: user.avatarUrl,
      role: user.role,
      phone: user.phone,
      studentId: user.studentId,
      isStudentIdVerified: user.isStudentIdVerified,
      isVerifiedFemale: user.isVerifiedFemale,
      gender: user.gender,
      trustScore: user.trustScore,
      ratingCount: user.ratingCount,
    };

    if (isAdmin && user.emergencyContacts && user.emergencyContacts.length > 0) {
      data.emergencyContact = user.emergencyContacts[0];
    }

    res.json(data);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
export const updateUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (user) {
      user.name = req.body.name || user.name;
      user.phone = req.body.phone || user.phone;
      user.studentId = req.body.studentId || user.studentId;
      user.avatarUrl = req.body.avatarUrl || user.avatarUrl;
      
      if (req.body.emergencyContacts) {
        user.emergencyContacts = req.body.emergencyContacts;
      }

      if (req.body.password) {
        user.password = req.body.password;
      }

      const updatedUser = await user.save();

      res.json({
        _id: updatedUser._id,
        name: updatedUser.name,
        email: updatedUser.email,
        role: updatedUser.role,
        phone: updatedUser.phone,
        studentId: updatedUser.studentId,
        isStudentIdVerified: updatedUser.isStudentIdVerified,
        avatarUrl: updatedUser.avatarUrl,
        emergencyContacts: updatedUser.emergencyContacts,
        gender: updatedUser.gender,
        isVerifiedFemale: updatedUser.isVerifiedFemale,
        preferWomenOnlyRides: updatedUser.preferWomenOnlyRides,
        trustScore: updatedUser.trustScore,
        ratingCount: updatedUser.ratingCount,
      });
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Upload profile avatar
// @route   POST /api/users/profile/avatar
// @access  Private
export const uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No image file provided' });
    }

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const avatarUrl = `/uploads/avatars/${req.file.filename}`;
    user.avatarUrl = avatarUrl;
    await user.save();

    res.json({
      avatarUrl,
      message: 'Profile photo uploaded successfully',
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};
