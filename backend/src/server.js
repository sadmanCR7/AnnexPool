import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import { Server } from 'socket.io';
import mongoose from 'mongoose';
import authRoutes from './routes/authRoutes.js';
import profileRoutes from './routes/profileRoutes.js';
import rideRequestRoutes from './routes/rideRequestRoutes.js';
import rideOfferRoutes from './routes/rideOfferRoutes.js';
import matchRoutes from './routes/matchRoutes.js';
import chatRoutes from './routes/chatRoutes.js';
import safetyRoutes from './routes/safetyRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import ratingRoutes from './routes/ratingRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import { rateLimiter } from './middlewares/rateLimiter.js';
import { initSocket } from './socket/socketHandler.js';
import { cleanupLegacyIndexes } from './config/dbCleanup.js';
import { setIo } from './config/io.js';

dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
  },
});

app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(helmet());
app.use('/api', rateLimiter);
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/api/auth', authRoutes);
app.use('/api/users', profileRoutes);
app.use('/api/rides/requests', rideRequestRoutes);
app.use('/api/rides/offers', rideOfferRoutes);
app.use('/api/rides/match', matchRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/safety', safetyRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/admin', adminRoutes);

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'success', message: 'AnnexPool API is running smoothly.' });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    status: 'error',
    message: err.message || 'Internal Server Error',
  });
});

setIo(io);
initSocket(io);

const PORT = process.env.PORT || 8000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/annexpool';

mongoose
  .connect(MONGO_URI)
  .then(async () => {
    console.log('Successfully connected to MongoDB.');
    await cleanupLegacyIndexes();
    server.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Error connecting to MongoDB:', error);
    process.exit(1);
  });

export { app, io };
