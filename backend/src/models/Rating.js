import mongoose from 'mongoose';

const RatingSchema = new mongoose.Schema(
  {
    rideOffer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RideOffer',
    },
    rideRequest: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RideRequest',
    },
    reviewer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    ratedUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    score: { type: Number, required: true, min: 1, max: 5 },
    review: { type: String, maxlength: 500 },
  },
  { timestamps: true }
);

RatingSchema.index(
  { rideOffer: 1, reviewer: 1, ratedUser: 1 },
  { unique: true, partialFilterExpression: { rideOffer: { $exists: true } } }
);
RatingSchema.index(
  { rideRequest: 1, reviewer: 1, ratedUser: 1 },
  { unique: true, partialFilterExpression: { rideRequest: { $exists: true } } }
);

export default mongoose.model('Rating', RatingSchema);
