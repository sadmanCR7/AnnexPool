import mongoose from 'mongoose';

const ReportSchema = new mongoose.Schema(
  {
    reporter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reportedUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    chat: { type: mongoose.Schema.Types.ObjectId, ref: 'Chat' },
    reason: { type: String, required: true },
    details: { type: String },
    status: { type: String, enum: ['Pending', 'Reviewed'], default: 'Pending' },
  },
  { timestamps: true }
);

export default mongoose.model('Report', ReportSchema);
