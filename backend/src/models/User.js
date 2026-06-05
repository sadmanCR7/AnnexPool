import mongoose from 'mongoose';
import bcrypt from 'bcrypt';

export const UserRole = {
  Rider: 'Rider',
  DriverRider: 'Driver+Rider',
  Admin: 'Admin',
};

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      validate: {
        validator: function (v) {
          return v.endsWith('@student.bup.edu.bd') || v.endsWith('@sudent.bup.edu.bd');
        },
        message: 'Registration is exclusively for BUP students using @student.bup.edu.bd email.',
      },
    },
    password: { type: String, required: true, select: false },
    role: {
      type: String,
      enum: Object.values(UserRole),
      default: UserRole.Rider,
    },
    isEmailVerified: { type: Boolean, default: false },
    isBanned: { type: Boolean, default: false },
    studentId: { type: String },
    isStudentIdVerified: { type: Boolean, default: false },
    phone: { type: String },
    avatarUrl: { type: String },
    emergencyContacts: [
      {
        name: { type: String },
        phone: { type: String },
        relation: { type: String },
      },
    ],
    gender: { type: String, enum: ['Male', 'Female', 'Other', 'Prefer not to say'], default: 'Prefer not to say' },
    isVerifiedFemale: { type: Boolean, default: false },
    preferWomenOnlyRides: { type: Boolean, default: false },
    fcmToken: { type: String },
    trustScore: { type: Number, default: 0, min: 0, max: 5 },
    ratingCount: { type: Number, default: 0 },
    ratingSum: { type: Number, default: 0 },
  },
  { timestamps: true }
);

// Hash the password before saving
UserSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Compare password method
UserSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

export default mongoose.model('User', UserSchema);
