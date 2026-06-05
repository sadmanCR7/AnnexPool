import User from '../models/User.js';

export const recalculateTrustScore = async (userId) => {
  const user = await User.findById(userId);
  if (!user || user.ratingCount === 0) {
    if (user) {
      user.trustScore = 0;
      await user.save();
    }
    return 0;
  }

  const score = Math.round((user.ratingSum / user.ratingCount) * 10) / 10;
  user.trustScore = score;
  await user.save();
  return score;
};
