import mongoose from 'mongoose';

const EmergencyAlertSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    rideOffer: { type: mongoose.Schema.Types.ObjectId, ref: 'RideOffer' },
    latitude: { type: Number },
    longitude: { type: Number },
    locationNote: { type: String },
    status: {
      type: String,
      enum: ['Active', 'Resolved'],
      default: 'Active',
    },
    notifiedContacts: [{ name: String, phone: String }],
  },
  { timestamps: true }
);

export default mongoose.model('EmergencyAlert', EmergencyAlertSchema);
