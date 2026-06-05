import mongoose from 'mongoose';

const ChatSchema = new mongoose.Schema(
  {
    rideOffer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RideOffer',
      required: false,
    },
    rideRequest: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RideRequest',
      required: false,
    },
    participants: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
        role: { type: String, enum: ['driver', 'rider'], required: true },
        identityRevealed: { type: Boolean, default: true },
      },
    ],
    isAnonymous: { type: Boolean, default: false },
    /** User who started the chat (joiner / offerer). */
    initiatorUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    finishedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    closedAt: { type: Date },
    blockedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    lastMessage: { type: String },
    lastMessageAt: { type: Date },
  },
  { timestamps: true }
);

ChatSchema.index({ rideOffer: 1, 'participants.user': 1 });

export default mongoose.model('Chat', ChatSchema);
