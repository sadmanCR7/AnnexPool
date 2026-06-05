import User from '../models/User.js';
import { generateToken } from '../utils/jwt.js';

export const registerUser = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists' });
    }

    const user = await User.create({
      name,
      email,
      password,
      role,
    });

    if (user) {
      // For local development, simulate email verification link
      const fakeVerificationToken = generateToken(user._id.toString(), user.role);
      console.log(`\n\n[DEV ONLY] Email Verification Link: http://localhost:8000/api/auth/verify?token=${fakeVerificationToken}\n\n`);

      res.status(201).json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        token: generateToken(user._id.toString(), user.role),
        message: 'Registration successful. Check console for verification link (dev mode).',
      });
    } else {
      res.status(400).json({ message: 'Invalid user data' });
    }
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }
    if (error.name === 'ValidationError') {
      const message = Object.values(error.errors)
        .map((e) => e.message)
        .join(', ');
      return res.status(400).json({ message });
    }
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');

    if (user && user.isBanned) {
      return res.status(403).json({ message: 'Your account has been suspended. Contact support.' });
    }

    if (user && (await user.comparePassword(password))) {
      res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        token: generateToken(user._id.toString(), user.role),
      });
    } else {
      res.status(401).json({ message: 'Invalid email or password' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server error' });
  }
};

export const verifyEmail = async (req, res) => {
  try {
    // Basic simulation for verification
    const { token } = req.query;
    if (!token) {
      return res.status(400).json({ message: 'Invalid token' });
    }
    
    // In real app, we verify the token, extract ID, set isEmailVerified = true.
    res.send('<h1>Email Verified Successfully (Simulation)</h1><p>You can now use AnnexPool.</p>');
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};
