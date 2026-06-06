import RideRequest from '../models/RideRequest.js';
import Chat from '../models/Chat.js';
import { createNotification } from '../services/notificationService.js';
import { saveMessage } from './chatController.js';
import { getRouteLabel } from '../services/chatService.js';

// @desc    Create a new ride request
// @route   POST /api/rides/requests
// @access  Private
export const createRideRequest = async (req, res) => {
  try {
    const { source, destination, travelDate, travelTime, vehiclePreference } = req.body;

    const rideRequest = new RideRequest({
      rider: req.user._id,
      source,
      destination,
      travelDate,
      travelTime,
      vehiclePreference,
    });

    const createdRequest = await rideRequest.save();
    res.status(201).json(createdRequest);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get all ride requests
// @route   GET /api/rides/requests
// @access  Private
export const getRideRequests = async (req, res) => {
  try {
    const filter = { status: { $nin: ['Cancelled', 'Completed'] } };
    if (req.query.source) filter.source = new RegExp(req.query.source, 'i');
    if (req.query.destination) filter.destination = new RegExp(req.query.destination, 'i');
    if (req.query.status) filter.status = req.query.status;
    if (req.query.vehiclePreference) filter.vehiclePreference = req.query.vehiclePreference;

    const requests = await RideRequest.find(filter)
      .populate('rider', 'name avatarUrl role phone isStudentIdVerified')
      .sort({ travelDate: 1 });

    res.json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get current user's ride requests
// @route   GET /api/rides/requests/mine
// @access  Private
export const getMyRideRequests = async (req, res) => {
  try {
    const requests = await RideRequest.find({ rider: req.user._id })
      .populate('responders.user', 'name avatarUrl role phone isStudentIdVerified')
      .sort({ createdAt: -1 });

    res.json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Accept or reject someone responding to my ride request
// @route   PUT /api/rides/requests/:requestId/responders/:responderId
// @access  Private
export const handleRideRequestResponder = async (req, res) => {
  try {
    const { action } = req.body;
    const request = await RideRequest.findById(req.params.requestId);

    if (!request) return res.status(404).json({ message: 'Ride request not found' });
    if (request.rider.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Only the request owner can manage responses' });
    }

    const responder = request.responders.id(req.params.responderId) ||
      request.responders.find((item) => item.user.toString() === req.params.responderId);
    if (!responder) return res.status(404).json({ message: 'Responder request not found' });

    if (action === 'accept') {
      responder.status = 'Accepted';
      request.status = 'Matched';
    } else if (action === 'reject') {
      responder.status = 'Rejected';
    } else {
      return res.status(400).json({ message: 'Invalid action. Use "accept" or "reject".' });
    }

    await request.save();

    try {
      if (responder.chat) {
        if (action === 'accept') {
          await saveMessage(responder.chat, req.user._id, 'Accepted the request for the route', req.app.get('io'));
        } else if (action === 'reject') {
          await saveMessage(responder.chat, req.user._id, 'Declined the request for the route', req.app.get('io'));
          const chat = await Chat.findById(responder.chat);
          if (chat) {
            chat.closedAt = new Date();
            await chat.save();
          }
          await saveMessage(responder.chat, req.user._id, `Chat closed for the route ${getRouteLabel({ rideRequest: request })}`, req.app.get('io'));
        }
      }
    } catch (err) {
      console.error('Failed to update chat on accept/reject', err);
    }

    await createNotification({
      userId: responder.user,
      type: 'ride',
      title: action === 'accept' ? 'Ride Request Accepted' : 'Ride Request Declined',
      body:
        action === 'accept'
          ? `Your response for ${request.source} to ${request.destination} was accepted.`
          : `Your response for ${request.source} to ${request.destination} was declined.`,
      data: { rideRequestId: request._id, chatId: responder.chat },
    });

    res.json({ message: `Responder ${action}ed successfully`, request });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Cancel a ride request
// @route   PUT /api/rides/requests/:id/cancel
// @access  Private
export const cancelRideRequest = async (req, res) => {
  try {
    const request = await RideRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({ message: 'Ride request not found' });
    }

    if (request.rider.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You can only cancel your own requests' });
    }

    if (request.status === 'Cancelled') {
      return res.status(400).json({ message: 'Request is already cancelled' });
    }

    request.status = 'Cancelled';
    await request.save();

    res.json({ message: 'Ride request cancelled successfully', request });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Mark a ride request as completed
// @route   PUT /api/rides/requests/:id/complete
// @access  Private (Request owner only)
export const completeRideRequest = async (req, res) => {
  try {
    const request = await RideRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({ message: 'Ride request not found' });
    }

    if (request.rider.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Only the request owner can complete this ride' });
    }

    if (request.status === 'Completed') {
      return res.status(400).json({ message: 'Request is already completed' });
    }

    const hasAcceptedResponder = request.responders.some(r => r.status === 'Accepted');
    if (!hasAcceptedResponder && request.responders.length > 0) {
      return res.status(400).json({ message: 'You cannot complete this ride until you accept a pending request.' });
    }

    request.status = 'Completed';
    await request.save();

    const notifyIds = request.responders
      .filter((r) => r.status === 'Accepted')
      .map((r) => r.user.toString());

    await Promise.all(
      notifyIds.map((userId) =>
        createNotification({
          userId,
          type: 'ride',
          title: 'Ride Completed',
          body: `The ride from ${request.source} to ${request.destination} has been completed. Please rate your experience.`,
          data: { rideRequestId: request._id },
        })
      )
    );

    try {
      // Find ALL chats linked to this ride request
      const chats = await Chat.find({ rideRequest: request._id });
      for (const chat of chats) {
        try {
          await saveMessage(
            chat._id,
            req.user._id,
            `Chat closed for the route ${getRouteLabel({ rideRequest: request })}`,
            req.app.get('io')
          );
        } catch (msgErr) {
          console.error('Failed to send completion message to chat', chat._id, msgErr.message);
        }
      }
    } catch (err) {
      console.error('Failed to send completion messages', err);
    }

    res.json({ message: 'Ride request marked as completed', request });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get ride requests where current user is a responder
// @route   GET /api/rides/requests/responded
// @access  Private
export const getMyRespondedRequests = async (req, res) => {
  try {
    const requests = await RideRequest.find({
      'responders.user': req.user._id,
    })
      .populate('rider', 'name phone avatarUrl isStudentIdVerified')
      .populate('responders.user', 'name phone avatarUrl isStudentIdVerified')
      .sort({ createdAt: -1 });

    res.json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};
