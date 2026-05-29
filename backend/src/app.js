const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();

// Security & Utility Middlewares
app.use(helmet()); // Protects headers
app.use(cors()); // Enables Cross-Origin Resource Sharing
app.use(express.json()); // Parses incoming JSON requests
app.use(express.urlencoded({ extended: true }));

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