/**
 * Create default admin user (run once):
 * node scripts/seedAdmin.js
 */
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from '../src/models/User.js';

dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/annexpool';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@student.bup.edu.bd';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Admin@123456';

await mongoose.connect(MONGO_URI);

const existing = await User.findOne({ email: ADMIN_EMAIL });
if (existing) {
  existing.role = 'Admin';
  existing.isBanned = false;
  if (ADMIN_PASSWORD) existing.password = ADMIN_PASSWORD;
  await existing.save();
  console.log(`Admin updated: ${ADMIN_EMAIL}`);
} else {
  await User.create({
    name: 'AnnexPool Admin',
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
    role: 'Admin',
    isEmailVerified: true,
  });
  console.log(`Admin created: ${ADMIN_EMAIL}`);
}

console.log(`Password: ${ADMIN_PASSWORD}`);
await mongoose.disconnect();
