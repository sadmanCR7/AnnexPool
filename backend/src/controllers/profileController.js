const User = require('../models/User');

// Get current user profile
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    
    res.status(200).json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error' });
  }
};

// Update profile (and handle photo upload)
exports.updateProfile = async (req, res) => {
  try {
    const { phone, department, batch, driverInfo, emergencyContacts } = req.body;
    
    let updateData = { phone, department, batch };

    // If a file was uploaded, add the path
    if (req.file) {
      updateData.profilePhoto = `/uploads/${req.file.filename}`;
    }

    // Parse JSON strings if sent via FormData
    if (driverInfo) updateData.driverInfo = JSON.parse(driverInfo);
    if (emergencyContacts) updateData.emergencyContacts = JSON.parse(emergencyContacts);

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    res.status(200).json({ success: true, user: updatedUser });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};