import mongoose from 'mongoose';

/**
 * Removes legacy indexes left from an older schema (e.g. unique bupId).
 * Without this, new users fail with: E11000 duplicate key { bupId: null }
 */
export const cleanupLegacyIndexes = async () => {
  const collection = mongoose.connection.collection('users');

  try {
    await collection.dropIndex('bupId_1');
    console.log('Removed stale users.bupId_1 index.');
  } catch (err) {
    if (err.codeName !== 'IndexNotFound' && err.code !== 27) {
      console.warn('Index cleanup (bupId_1):', err.message);
    }
  }
};
