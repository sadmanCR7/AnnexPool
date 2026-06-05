import Rating from '../models/Rating.js';
import RideOffer from '../models/RideOffer.js';
import RideRequest from '../models/RideRequest.js';
import User from '../models/User.js';
import { recalculateTrustScore } from '../services/trustScoreService.js';
import { createNotification } from '../services/notificationService.js';

// @route POST /api/ratings
export const submitRating = async (req, res) => {
  try {
    const { rideOfferId, rideRequestId, ratedUserId, score, review } = req.body;

    if ((!rideOfferId && !rideRequestId) || !ratedUserId || !score) {
      return res.status(400).json({ message: 'rideOfferId or rideRequestId, ratedUserId, and score are required' });
    }

    if (score < 1 || score > 5) {
      return res.status(400).json({ message: 'Score must be between 1 and 5' });
    }

    let isParticipant = false;
    let rideReference = {};

    if (rideOfferId) {
      const offer = await RideOffer.findById(rideOfferId);
      if (!offer) return res.status(404).json({ message: 'Ride offer not found' });

      isParticipant =
        offer.driver.toString() === req.user._id.toString() ||
        offer.passengers.some(
          (p) => p.rider.toString() === req.user._id.toString() && p.status === 'Accepted'
        );
      rideReference = { rideOffer: rideOfferId };
    } else {
      const request = await RideRequest.findById(rideRequestId);
      if (!request) return res.status(404).json({ message: 'Ride request not found' });

      isParticipant =
        request.rider.toString() === req.user._id.toString() ||
        request.responders.some(
          (responder) =>
            responder.user.toString() === req.user._id.toString() &&
            responder.status === 'Accepted'
        );
      rideReference = { rideRequest: rideRequestId };
    }

    if (!isParticipant) {
      return res.status(403).json({ message: 'You can only rate rides you participated in' });
    }

    const existing = await Rating.findOne({ 
      ...rideReference, 
      reviewer: req.user._id, 
      ratedUser: ratedUserId 
    });
    if (existing) {
      return res.status(400).json({ message: 'You already rated this user for this ride' });
    }

    const rating = await Rating.create({
      ...rideReference,
      reviewer: req.user._id,
      ratedUser: ratedUserId,
      score,
      review,
    });

    const ratedUser = await User.findById(ratedUserId);
    if (ratedUser) {
      ratedUser.ratingCount += 1;
      ratedUser.ratingSum += score;
      await ratedUser.save();
      await recalculateTrustScore(ratedUserId);
    }

    await createNotification({
      userId: ratedUserId,
      type: 'rating',
      title: 'New Rating Received',
      body: `You received a ${score}-star rating on AnnexPool.`,
      data: { rideOfferId, rideRequestId, ratingId: rating._id },
    });

    res.status(201).json(rating);
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'You already rated this ride' });
    }
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/ratings/user/:userId
export const getUserRatings = async (req, res) => {
  try {
    const ratings = await Rating.find({ ratedUser: req.params.userId })
      .populate('reviewer', 'name avatarUrl')
      .sort({ createdAt: -1 })
      .limit(30);

    const user = await User.findById(req.params.userId).select(
      'name trustScore ratingCount ratingSum'
    );

    res.json({ user, ratings });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @route GET /api/ratings/pending/:rideOfferId
export const getPendingRating = async (req, res) => {
  try {
    const offer = await RideOffer.findById(req.params.rideOfferId).populate('driver', 'name');
    if (offer) {
      const isDriver = offer.driver._id.toString() === req.user._id.toString();
      const myPassenger = offer.passengers.find(
        (p) => p.rider.toString() === req.user._id.toString() && p.status === 'Accepted'
      );

      let rateTarget = null;
      if (isDriver && offer.passengers.length > 0) {
        const accepted = offer.passengers.find((p) => p.status === 'Accepted');
        if (accepted) rateTarget = { userId: accepted.rider, role: 'rider' };
      } else if (myPassenger) {
        rateTarget = { userId: offer.driver._id, role: 'driver', name: offer.driver.name };
      }

      const alreadyRated = rateTarget ? await Rating.findOne({
        rideOffer: req.params.rideOfferId,
        reviewer: req.user._id,
        ratedUser: rateTarget.userId,
      }) : null;

      return res.json({
        canRate: !!rateTarget && !alreadyRated && ['Completed', 'Full', 'Active'].includes(offer.status),
        rateTarget,
        alreadyRated: !!alreadyRated,
      });
    }

    const request = await RideRequest.findById(req.params.rideOfferId).populate('rider', 'name');
    if (!request) return res.status(404).json({ message: 'Ride not found' });

    const isRider = request.rider._id.toString() === req.user._id.toString();
    const myResponder = request.responders.find(
      (r) => r.user.toString() === req.user._id.toString() && r.status === 'Accepted'
    );

    let rateTarget = null;
    if (isRider && request.responders.length > 0) {
      const accepted = request.responders.find((r) => r.status === 'Accepted');
      if (accepted) {
        const userObj = await User.findById(accepted.user).select('name');
        rateTarget = { userId: accepted.user, role: 'driver', name: userObj?.name || 'Driver' };
      }
    } else if (myResponder) {
      rateTarget = { userId: request.rider._id, role: 'rider', name: request.rider.name };
    }

    const alreadyRated = rateTarget ? await Rating.findOne({
      rideRequest: req.params.rideOfferId,
      reviewer: req.user._id,
      ratedUser: rateTarget.userId,
    }) : null;

    res.json({
      canRate: !!rateTarget && !alreadyRated && ['Completed', 'Matched'].includes(request.status),
      rateTarget,
      alreadyRated: !!alreadyRated,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};
