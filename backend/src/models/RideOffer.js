import mongoose from 'mongoose';

const RideOfferSchema = new mongoose.Schema(
  {
    driver: {
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
    totalSeats: {
      type: Number,
      required: true,
      min: 1,
      max: 6,
    },
    availableSeats: {
      type: Number,
      required: true,
      min: 0,
    },
    vehicleType: {
      type: String,
      enum: ['Car', 'Bike', 'Rickshaw'],
      required: true,
    },
    vehicleDetails: {
      type: String, // e.g., "White Toyota Corolla"
    },
    pricePerSeat: {
      type: Number,
      default: 0,
    },
    womenOnly: {
      type: Boolean,
      default: false,
    },
    status: {
      type: String,
      enum: ['Active', 'Full', 'Cancelled', 'Completed'],
      default: 'Active',
    },
    passengers: [
      {
        rider: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
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

export default mongoose.model('RideOffer', RideOfferSchema);
