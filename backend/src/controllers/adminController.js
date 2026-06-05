import User from '../models/User.js';
import RideOffer from '../models/RideOffer.js';
import RideRequest from '../models/RideRequest.js';
import Report from '../models/Report.js';
import EmergencyAlert from '../models/EmergencyAlert.js';
import Rating from '../models/Rating.js';
import { createNotification } from '../services/notificationService.js';

// @route GET /api/admin/analytics
export const getAnalytics = async (req, res) => {
  try {
    const [
      totalUsers,
      totalDrivers,
      totalOffers,
      activeOffers,
      totalRequests,
      pendingReports,
      activeSos,
      totalRatings,
      bannedUsers,
      verifiedStudents,
    ] = await Promise.all([
      User.countDocuments({ role: { $ne: 'Admin' } }),
      User.countDocuments({ role: 'Driver+Rider' }),
      RideOffer.countDocuments(),
      RideOffer.countDocuments({ status: 'Active' }),
      RideRequest.countDocuments(),
      Report.countDocuments({ status: 'Pending' }),
      EmergencyAlert.countDocuments({ status: 'Active' }),
      Rating.countDocuments(),
      User.countDocuments({ isBanned: true }),
      User.countDocuments({ isStudentIdVerified: true }),
    ]);

    const recentUsers = await User.find({ role: { $ne: 'Admin' } })
      .sort({ createdAt: -1 })
      .limit(5)
      .select('name email role createdAt');

    res.json({
      totals: {
        users: totalUsers,
        drivers: totalDrivers,
        rideOffers: totalOffers,
        activeOffers,
        rideRequests: totalRequests,
        ratings: totalRatings,
        pendingReports,
        activeSos,
        bannedUsers,
        verifiedStudents,
      },
      recentUsers,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/admin/users
export const getUsers = async (req, res) => {
  try {
    const filter = { role: { $ne: 'Admin' } };
    if (req.query.search) {
      const q = new RegExp(req.query.search, 'i');
      filter.$or = [{ name: q }, { email: q }, { studentId: q }];
    }
    if (req.query.banned === 'true') filter.isBanned = true;

    const users = await User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 })
      .limit(100);

    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/admin/users/:id/verify-student
export const verifyStudentId = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.isStudentIdVerified = true;
    await user.save();
    res.json({ message: 'Student ID verified', user: { _id: user._id, isStudentIdVerified: true } });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/admin/users/:id/verify-female
export const verifyFemaleRider = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.isVerifiedFemale = true;
    await user.save();
    res.json({ message: 'Female rider verified', user: { _id: user._id, isVerifiedFemale: true } });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/admin/users/:id/unverify-student
export const unverifyStudentId = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.isStudentIdVerified = false;
    await user.save();
    res.json({ message: 'Student verification removed', user: { _id: user._id, isStudentIdVerified: false } });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/admin/users/:id/ban
export const banUser = async (req, res) => {
  try {
    const { ban = true } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (user.role === 'Admin') {
      return res.status(400).json({ message: 'Cannot ban an admin account' });
    }

    user.isBanned = ban;
    await user.save();

    if (ban) {
      await createNotification({
        userId: user._id,
        type: 'system',
        title: 'Account Suspended',
        body: 'Your account has been suspended by an administrator due to a violation of community guidelines.',
        data: { reason: 'banned' },
      });
    }

    res.json({ message: ban ? 'User banned' : 'User unbanned', user: { _id: user._id, isBanned: user.isBanned } });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/admin/reports
export const getReports = async (req, res) => {
  try {
    const filter = {};
    if (req.query.status) filter.status = req.query.status;

    const reports = await Report.find(filter)
      .populate('reporter', 'name email')
      .populate('reportedUser', 'name email')
      .sort({ createdAt: -1 })
      .limit(100);

    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/admin/reports/:id
export const reviewReport = async (req, res) => {
  try {
    const report = await Report.findByIdAndUpdate(
      req.params.id,
      { status: 'Reviewed' },
      { new: true }
    );
    if (!report) return res.status(404).json({ message: 'Report not found' });
    res.json({ message: 'Report marked as reviewed', report });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/admin/rides/offers
export const getAllOffers = async (req, res) => {
  try {
    const offers = await RideOffer.find()
      .populate('driver', 'name email phone')
      .sort({ createdAt: -1 })
      .limit(100);
    res.json(offers);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/admin/rides/requests
export const getAllRequests = async (req, res) => {
  try {
    const requests = await RideRequest.find()
      .populate('rider', 'name email')
      .sort({ createdAt: -1 })
      .limit(100);
    res.json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/admin/rides/offers/:id/cancel
export const adminCancelOffer = async (req, res) => {
  try {
    const offer = await RideOffer.findById(req.params.id);
    if (!offer) return res.status(404).json({ message: 'Ride offer not found' });

    offer.status = 'Cancelled';
    await offer.save();
    res.json({ message: 'Ride offer cancelled by admin', offer });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/admin/sos
export const getActiveSOS = async (req, res) => {
  try {
    const alerts = await EmergencyAlert.find({ status: 'Active' })
      .populate('user', 'name email phone')
      .sort({ createdAt: -1 });
    res.json(alerts);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route PUT /api/admin/sos/:id/resolve
export const resolveSOS = async (req, res) => {
  try {
    const alert = await EmergencyAlert.findByIdAndUpdate(
      req.params.id,
      { status: 'Resolved' },
      { new: true }
    );
    if (!alert) return res.status(404).json({ message: 'SOS alert not found' });
    res.json({ message: 'SOS resolved', alert });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};
