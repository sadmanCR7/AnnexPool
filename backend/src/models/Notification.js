import mongoose from 'mongoose';

const NotificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: {
      type: String,
      enum: ['ride', 'chat', 'emergency', 'rating', 'system'],
      default: 'system',
    },
    title: { type: String, required: true },
    body: { type: String, required: true },
    data: { type: mongoose.Schema.Types.Mixed },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true }
);

export default mongoose.model('Notification', NotificationSchema);
