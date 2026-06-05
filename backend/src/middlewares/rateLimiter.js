const windowMs = 15 * 60 * 1000;
const maxRequests = 10000;
const hits = new Map();

export const rateLimiter = (req, res, next) => {
  const key = req.ip || req.socket.remoteAddress || 'unknown';
  const now = Date.now();
  const entry = hits.get(key) || { count: 0, start: now };

  if (now - entry.start > windowMs) {
    entry.count = 0;
    entry.start = now;
  }

  entry.count += 1;
  hits.set(key, entry);

  if (entry.count > maxRequests) {
    return res.status(429).json({ message: 'Too many requests. Please try again later.' });
  }

  next();
};
