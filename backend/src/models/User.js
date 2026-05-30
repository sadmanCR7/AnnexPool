const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { 
    type: String, 
    required: true, 
    unique: true,
    // Strict BUP Email Validation Regex
    match: [/^[a-zA-Z0-9._%+-]+@bup\.edu\.bd$/, 'Registration is restricted to valid BUP emails only (@bup.edu.bd)']
  },
  password: { type: String, required: true, select: false },
  role: { type: String, enum: ['rider', 'driver'], default: 'rider' },
  isVerified: { type: Boolean, default: false }, // For future email OTP verification
}, { timestamps: true });

// Encrypt password before saving
userSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 12);
});

// Method to verify passwords
userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);