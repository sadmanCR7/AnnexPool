import RideOffer from '../models/RideOffer.js';
import User from '../models/User.js';
import { getOrCreateChat } from '../services/chatService.js';
import { saveMessage } from './chatController.js';
import { getRouteLabel } from '../services/chatService.js';
import { createNotification } from '../services/notificationService.js';

// @desc    Create a ride offer
// @route   POST /api/rides/offers
// @access  Private (Driver+Rider only)
export const createRideOffer = async (req, res) => {
  try {
    if (req.user.role !== 'Driver+Rider') {
      return res.status(403).json({ message: 'Only drivers can create ride offers' });
    }

    const { source, destination, travelDate, travelTime, totalSeats, vehicleType, vehicleDetails, pricePerSeat, womenOnly } = req.body;

    const offer = await RideOffer.create({
      driver: req.user._id,
      source,
      destination,
      travelDate,
      travelTime,
      totalSeats,
      availableSeats: totalSeats,
      vehicleType,
      vehicleDetails,
      pricePerSeat,
      womenOnly: womenOnly || false,
    });

    res.status(201).json(offer);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get all active ride offers
// @route   GET /api/rides/offers
// @access  Private
export const getRideOffers = async (req, res) => {
  try {
    const filter = {
      status: 'Active',
      driver: { $ne: req.user._id },
    };
    if (req.query.source) filter.source = new RegExp(req.query.source, 'i');
    if (req.query.destination) filter.destination = new RegExp(req.query.destination, 'i');
    if (req.query.womenOnly === 'true') filter.womenOnly = true;

    if (req.query.preferWomenOnly === 'true') {
      filter.womenOnly = true;
    }

    const offers = await RideOffer.find(filter)
      .populate('driver', 'name avatarUrl role phone trustScore ratingCount isVerifiedFemale gender isStudentIdVerified')
      .populate('passengers.rider', 'name')
      .sort({ travelDate: 1 });

    res.json(offers);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get my ride offers (driver dashboard)
// @route   GET /api/rides/offers/mine
// @access  Private
export const getMyRideOffers = async (req, res) => {
  try {
    const offers = await RideOffer.find({ driver: req.user._id })
      .populate('passengers.rider', 'name phone')
      .sort({ createdAt: -1 });

    res.json(offers);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get offers where I am a passenger
// @route   GET /api/rides/offers/joined
// @access  Private
export const getMyJoinedOffers = async (req, res) => {
  try {
    const offers = await RideOffer.find({
      'passengers.rider': req.user._id,
    })
      .populate('driver', 'name phone avatarUrl isStudentIdVerified')
      .sort({ createdAt: -1 });

    res.json(offers);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};


// @desc    Request to join a ride
// @route   POST /api/rides/offers/:id/join
// @access  Private
export const joinRideOffer = async (req, res) => {
  try {
    const offer = await RideOffer.findById(req.params.id);
    if (!offer) return res.status(404).json({ message: 'Ride offer not found' });
    if (offer.availableSeats <= 0) return res.status(400).json({ message: 'No seats available' });
    if (offer.driver.toString() === req.user._id.toString()) {
      return res.status(400).json({ message: 'You cannot join your own ride' });
    }

    const alreadyRequested = offer.passengers.find(
      (p) => p.rider.toString() === req.user._id.toString()
    );
    if (alreadyRequested) return res.status(400).json({ message: 'You already requested this ride' });

    if (offer.womenOnly) {
      const rider = await User.findById(req.user._id);
      const allowed =
        rider?.gender === 'Female' || rider?.isVerifiedFemale === true;
      if (!allowed) {
        return res.status(403).json({
          message: 'This is a women-only ride. Verified female riders only.',
        });
      }
    }

    offer.passengers.push({ rider: req.user._id, status: 'Pending' });
    await offer.save();

    const { chat, isNew } = await getOrCreateChat(offer._id, req.user._id);

    if (isNew) {
      await saveMessage(
        chat._id,
        req.user._id,
        `Chat started for the route ${getRouteLabel({ rideOffer: offer })}`,
        req.app.get('io')
      );
    }

    await createNotification({
      userId: offer.driver,
      type: 'ride',
      title: 'New Ride Join Request',
      body: `${req.user.name} requested to join your ride to ${offer.destination}.`,
      data: { rideOfferId: offer._id, riderId: req.user._id, chatId: chat._id },
    });

    res.json({
      message: 'Join request sent successfully',
      chatId: chat._id,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Accept or reject a passenger
// @route   PUT /api/rides/offers/:offerId/passengers/:passengerId
// @access  Private (Driver only)
export const handlePassengerRequest = async (req, res) => {
  try {
    const { action } = req.body; // 'accept' or 'reject'
    const offer = await RideOffer.findById(req.params.offerId);

    if (!offer) return res.status(404).json({ message: 'Ride offer not found' });
    if (offer.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Only the driver can manage passengers' });
    }

    const passenger =
      offer.passengers.id(req.params.passengerId) ||
      offer.passengers.find((p) => p.rider.toString() === req.params.passengerId);
    if (!passenger) return res.status(404).json({ message: 'Passenger request not found' });

    if (action === 'accept') {
      if (passenger.status === 'Accepted') {
        return res.json({ message: 'Passenger already accepted', offer });
      }
      if (offer.availableSeats <= 0) return res.status(400).json({ message: 'No seats available' });
      passenger.status = 'Accepted';
      offer.availableSeats -= 1;
      if (offer.availableSeats === 0) {
        offer.status = 'Full';
        const overflowPassengers = offer.passengers.filter(
          (pendingPassenger) =>
            pendingPassenger.status === 'Pending' &&
            pendingPassenger.rider.toString() !== passenger.rider.toString()
        );

        overflowPassengers.forEach((pendingPassenger) => {
          pendingPassenger.status = 'Rejected';
        });

        await Promise.all(
          overflowPassengers.map((pendingPassenger) =>
            createNotification({
              userId: pendingPassenger.rider,
              type: 'ride',
              title: 'Ride Offer Full',
              body: `Riders are full for the offer to ${offer.destination}.`,
              data: { rideOfferId: offer._id },
            })
          )
        );
      }

    } else if (action === 'reject') {
      if (passenger.status === 'Accepted') {
        offer.availableSeats += 1;
        if (offer.status === 'Full') offer.status = 'Active';
      }
      passenger.status = 'Rejected';
    } else {
      return res.status(400).json({ message: 'Invalid action. Use "accept" or "reject".' });
    }

    await offer.save();

    const riderId = passenger.rider.toString();
    
    try {
      const { chat } = await getOrCreateChat(offer._id, riderId);
      if (chat) {
        if (action === 'accept') {
          await saveMessage(chat._id, req.user._id, 'Accepted the request for the route', req.app.get('io'));
        } else if (action === 'reject') {
          await saveMessage(chat._id, req.user._id, 'Declined the request for the route', req.app.get('io'));
          chat.closedAt = new Date();
          await chat.save();
          await saveMessage(chat._id, req.user._id, `Chat closed for the route ${getRouteLabel({ rideOffer: offer })}`, req.app.get('io'));
        }
      }
    } catch (err) {
      console.error('Failed to update chat on accept/reject', err);
    }

    await createNotification({
      userId: riderId,
      type: 'ride',
      title: action === 'accept' ? 'Ride Request Accepted' : 'Ride Request Declined',
      body:
        action === 'accept'
          ? `Your request to join the ride to ${offer.destination} was accepted.`
          : `Your request to join the ride to ${offer.destination} was declined.`,
      data: { rideOfferId: offer._id },
    });

    res.json({ message: `Passenger ${action}ed successfully`, offer });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Mark ride as completed (enables ratings)
// @route   PUT /api/rides/offers/:id/complete
export const completeRideOffer = async (req, res) => {
  try {
    const offer = await RideOffer.findById(req.params.id);
    if (!offer) return res.status(404).json({ message: 'Ride offer not found' });
    if (offer.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Only the driver can complete this ride' });
    }

    const hasAcceptedPassenger = offer.passengers.some(p => p.status === 'Accepted');
    if (!hasAcceptedPassenger && offer.passengers.length > 0) {
      return res.status(400).json({ message: 'You cannot complete this ride until you accept pending requests.' });
    }

    offer.status = 'Completed';
    await offer.save();

    const notifyIds = [
      ...offer.passengers
        .filter((p) => p.status === 'Accepted')
        .map((p) => p.rider.toString()),
    ];

    await Promise.all(
      notifyIds.map((userId) =>
        createNotification({
          userId,
          type: 'ride',
          title: 'Ride Completed',
          body: 'Please rate your experience on AnnexPool.',
          data: { rideOfferId: offer._id },
        })
      )
    );

    res.json({ message: 'Ride marked as completed', offer });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Cancel a ride offer
// @route   PUT /api/rides/offers/:id/cancel
// @access  Private (Driver only)
export const cancelRideOffer = async (req, res) => {
  try {
    const offer = await RideOffer.findById(req.params.id);
    if (!offer) return res.status(404).json({ message: 'Ride offer not found' });
    if (offer.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Only the driver can cancel this ride' });
    }

    offer.status = 'Cancelled';
    await offer.save();
    res.json({ message: 'Ride cancelled successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};
