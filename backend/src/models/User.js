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
  role: { type: String, enum: ['rider', 'driver'], default: 'rider' }, // Existing field
  
  // NEW PROFILE FIELDS
  profilePhoto: { type: String, default: '' },
  phone: { type: String, default: '' },
  department: { type: String, default: '' },
  batch: { type: String, default: '' },
  
  // Array of emergency contacts
  emergencyContacts: [{
    name: String,
    phone: String,
    relation: String
  }],

  // Verification & Driver specific info
  studentIdPhoto: { type: String, default: '' },
  isVerified: { type: Boolean, default: false },
  
  driverInfo: {
    licenseNumber: { type: String, default: '' },
    vehicleModel: { type: String, default: '' },
    licensePlate: { type: String, default: '' }
  },
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