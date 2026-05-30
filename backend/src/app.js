const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const authRoutes = require('./routes/authRoutes');
const app = express();
const profileRoutes = require('./routes/profileRoutes'); // Add at the top with other imports
const path = require('path');


// Security & Utility Middlewares
app.use(helmet({ crossOriginResourcePolicy: false })); // Protects headers
app.use(cors()); // Enables Cross-Origin Resource Sharing
app.use(express.json()); // Parses incoming JSON requests
app.use(express.urlencoded({ extended: true }));
app.use('/api/v1/auth', authRoutes);
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
app.use('/api/v1/profile', profileRoutes);



if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev')); // HTTP request logger
}

// Basic Health Check Route
app.get('/', (req, res) => {
    res.status(200).json({ success: true, message: 'AnnexPool API is running smoothly.' });
});

// Future API Routes will be mounted here
// app.use('/api/v1/auth', authRoutes);

module.exports = app;