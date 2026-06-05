import User from '../models/User.js';
import RideOffer from '../models/RideOffer.js';
import EmergencyAlert from '../models/EmergencyAlert.js';
import Report from '../models/Report.js';
import { createNotification, notifyMany } from '../services/notificationService.js';

// @route PUT /api/safety/preferences
export const updateSafetyPreferences = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (req.body.gender) user.gender = req.body.gender;
    if (typeof req.body.preferWomenOnlyRides === 'boolean') {
      user.preferWomenOnlyRides = req.body.preferWomenOnlyRides;
    }
    if (req.body.emergencyContacts) {
      user.emergencyContacts = req.body.emergencyContacts;
    }

    await user.save();
    res.json({
      gender: user.gender,
      isVerifiedFemale: user.isVerifiedFemale,
      preferWomenOnlyRides: user.preferWomenOnlyRides,
      emergencyContacts: user.emergencyContacts,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/safety/preferences
export const getSafetyPreferences = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.json({
      gender: user.gender,
      isVerifiedFemale: user.isVerifiedFemale,
      preferWomenOnlyRides: user.preferWomenOnlyRides,
      emergencyContacts: user.emergencyContacts,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route POST /api/safety/sos
export const triggerSOS = async (req, res) => {
  try {
    const { latitude, longitude, locationNote, rideOfferId } = req.body;
    const user = await User.findById(req.user._id);

    const alert = await EmergencyAlert.create({
      user: req.user._id,
      rideOffer: rideOfferId || undefined,
      latitude,
      longitude,
      locationNote,
      notifiedContacts: user.emergencyContacts || [],
      status: 'Active',
    });

    const locationText = locationNote
      || (latitude && longitude ? `${latitude}, ${longitude}` : 'Location not shared');

    await createNotification({
      userId: req.user._id,
      type: 'emergency',
      title: 'SOS Alert Sent',
      body: `Your emergency contacts have been notified. ${locationText}`,
      data: { alertId: alert._id },
    });

    const notifyIds = [];
    if (rideOfferId) {
      const offer = await RideOffer.findById(rideOfferId);
      if (offer) {
        notifyIds.push(offer.driver.toString());
        offer.passengers
          .filter((p) => p.status === 'Accepted')
          .forEach((p) => notifyIds.push(p.rider.toString()));
      }
    }

    await notifyMany(
      notifyIds.filter((id) => id !== req.user._id.toString()),
      {
        type: 'emergency',
        title: 'Emergency SOS Alert',
        body: `${user.name} triggered an SOS alert on AnnexPool.`,
        data: { alertId: alert._id, rideOfferId },
      }
    );

    res.status(201).json({
      message: 'SOS alert sent to emergency contacts and ride participants',
      alert,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/safety/sos/mine
export const getMySOSAlerts = async (req, res) => {
  try {
    const alerts = await EmergencyAlert.find({ user: req.user._id }).sort({ createdAt: -1 }).limit(20);
    res.json(alerts);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route POST /api/safety/report
export const reportMisconduct = async (req, res) => {
  try {
    const { reportedUserId, reason, details, rideOfferId } = req.body;
    if (!reportedUserId || !reason) {
      return res.status(400).json({ message: 'reportedUserId and reason are required' });
    }

    const report = await Report.create({
      reporter: req.user._id,
      reportedUser: reportedUserId,
      reason,
      details,
      chat: null,
    });

    await createNotification({
      userId: req.user._id,
      type: 'system',
      title: 'Report Submitted',
      body: 'Thank you. Our safety team will review your report.',
      data: { reportId: report._id, rideOfferId },
    });

    res.status(201).json({ message: 'Misconduct report submitted', report });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};
