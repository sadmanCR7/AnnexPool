import RideOffer from '../models/RideOffer.js';
import RideRequest from '../models/RideRequest.js';
import { rankMatches } from '../utils/routeMatcher.js';

// @desc    Smart route matching suggestions
// @route   GET /api/rides/match
// @access  Private
export const getMatchSuggestions = async (req, res) => {
  try {
    const { source, destination, travelDate, travelTime, vehiclePreference, limit = 10 } = req.query;

    if (!source || !destination || !travelDate || !travelTime) {
      return res.status(400).json({
        message: 'source, destination, travelDate, and travelTime are required',
      });
    }

    const query = { source, destination, travelDate, travelTime, vehiclePreference };

    const [offers, requests] = await Promise.all([
      RideOffer.find({
        status: { $in: ['Active', 'Full'] },
        availableSeats: { $gt: 0 },
        driver: { $ne: req.user._id },
      })
        .populate('driver', 'name avatarUrl role phone')
        .limit(50),
      RideRequest.find({ status: 'Pending' })
        .populate('rider', 'name avatarUrl role phone')
        .limit(50),
    ]);

    const rankedOffers = rankMatches(query, offers, 'offer').slice(0, Number(limit));
    const rankedRequests = rankMatches(query, requests, 'request').slice(0, Number(limit));

    const suggestions = [...rankedOffers, ...rankedRequests]
      .sort((a, b) => b.matchScore - a.matchScore)
      .slice(0, Number(limit));

    res.json({
      query: {
        source,
        destination,
        travelDate,
        travelTime,
        vehiclePreference: vehiclePreference || 'Any',
      },
      count: suggestions.length,
      suggestions,
      topOffers: rankedOffers.slice(0, 5),
      topRequests: rankedRequests.slice(0, 5),
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Match suggestions for a specific ride request owned by user
// @route   GET /api/rides/match/for-request/:id
// @access  Private
export const getMatchesForRequest = async (req, res) => {
  try {
    const rideRequest = await RideRequest.findById(req.params.id);
    if (!rideRequest) return res.status(404).json({ message: 'Ride request not found' });

    if (rideRequest.rider.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const query = {
      source: rideRequest.source,
      destination: rideRequest.destination,
      travelDate: rideRequest.travelDate,
      travelTime: rideRequest.travelTime,
      vehiclePreference: rideRequest.vehiclePreference,
    };

    const offers = await RideOffer.find({
      status: 'Active',
      availableSeats: { $gt: 0 },
      driver: { $ne: req.user._id },
    }).populate('driver', 'name avatarUrl role phone');

    const ranked = rankMatches(query, offers, 'offer');

    res.json({ rideRequest, suggestions: ranked });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};
