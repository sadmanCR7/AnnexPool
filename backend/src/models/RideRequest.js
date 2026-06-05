import mongoose from 'mongoose';

const RideRequestSchema = new mongoose.Schema(
  {
    rider: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'User',
    },
    source: {
      type: String,
      required: true,
    },
    destination: {
      type: String,
      required: true,
    },
    travelDate: {
      type: Date,
      required: true,
    },
    travelTime: {
      type: String,
      required: true,
    },
    vehiclePreference: {
      type: String,
      enum: ['Car', 'Bike', 'Rickshaw', 'Any'],
      default: 'Any',
    },
    status: {
      type: String,
      enum: ['Pending', 'Matched', 'Cancelled', 'Completed'],
      default: 'Pending',
    },
    responders: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
        chat: { type: mongoose.Schema.Types.ObjectId, ref: 'Chat' },
        kind: {
          type: String,
          enum: ['driver_offer', 'co_rider'],
          default: 'co_rider',
        },
        status: {
          type: String,
          enum: ['Pending', 'Accepted', 'Rejected'],
          default: 'Pending',
        },
        requestedAt: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

export default mongoose.model('RideRequest', RideRequestSchema);
