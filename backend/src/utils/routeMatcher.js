import { BUP_LOCATIONS } from './bupLocations.js';

const normalize = (text = '') =>
  text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ');

export const resolveLocation = (input = '') => {
  const norm = normalize(input);
  if (!norm) return null;

  for (const loc of BUP_LOCATIONS) {
    const names = [loc.name, ...loc.aliases].map(normalize);
    if (names.some((n) => norm === n || norm.includes(n) || n.includes(norm))) {
      return loc;
    }
  }
  return { id: `custom_${norm}`, name: input.trim(), aliases: [norm] };
};

export const locationMatchScore = (a, b) => {
  const locA = resolveLocation(a);
  const locB = resolveLocation(b);
  if (!locA || !locB) return 0;

  if (locA.id === locB.id) return 40;

  const normA = normalize(a);
  const normB = normalize(b);
  if (normA.includes(normB) || normB.includes(normA)) return 28;

  return 0;
};

const parseTimeToMinutes = (timeStr = '') => {
  const match = timeStr.match(/(\d{1,2}):?(\d{2})?\s*(am|pm)?/i);
  if (!match) return null;

  let hours = parseInt(match[1], 10);
  const minutes = parseInt(match[2] || '0', 10);
  const meridiem = match[3]?.toLowerCase();

  if (meridiem === 'pm' && hours < 12) hours += 12;
  if (meridiem === 'am' && hours === 12) hours = 0;

  return hours * 60 + minutes;
};

export const scheduleMatchScore = (dateA, timeA, dateB, timeB) => {
  let score = 0;
  const dA = new Date(dateA);
  const dB = new Date(dateB);

  if (Number.isNaN(dA.getTime()) || Number.isNaN(dB.getTime())) return score;

  const dayDiff = Math.abs(dA.setHours(0, 0, 0, 0) - dB.setHours(0, 0, 0, 0)) / (1000 * 60 * 60 * 24);

  if (dayDiff === 0) score += 15;
  else if (dayDiff <= 1) score += 8;

  const minsA = parseTimeToMinutes(timeA);
  const minsB = parseTimeToMinutes(timeB);

  if (minsA != null && minsB != null) {
    const diff = Math.abs(minsA - minsB);
    if (diff <= 30) score += 10;
    else if (diff <= 60) score += 5;
  }

  return score;
};

export const vehicleMatchScore = (preference, vehicleType) => {
  if (!preference || preference === 'Any') return 5;
  if (preference === vehicleType) return 5;
  return 0;
};

export const scoreRideMatch = (query, ride, type = 'offer') => {
  const sourceScore = locationMatchScore(query.source, ride.source);
  const destScore = locationMatchScore(query.destination, ride.destination);
  const scheduleScore = scheduleMatchScore(
    query.travelDate,
    query.travelTime,
    ride.travelDate,
    ride.travelTime
  );

  let vehicleScore = 0;
  if (type === 'offer') {
    vehicleScore = vehicleMatchScore(query.vehiclePreference, ride.vehicleType);
  } else {
    vehicleScore = vehicleMatchScore(query.vehiclePreference, ride.vehiclePreference);
  }

  let seatBonus = 0;
  if (type === 'offer' && ride.availableSeats > 0) seatBonus = 5;

  const total = sourceScore + destScore + scheduleScore + vehicleScore + seatBonus;

  return {
    score: Math.min(100, total),
    breakdown: { sourceScore, destScore, scheduleScore, vehicleScore, seatBonus },
  };
};

export const rankMatches = (query, items, type) =>
  items
    .map((item) => {
      const plain = typeof item.toObject === 'function' ? item.toObject() : item;
      const { score, breakdown } = scoreRideMatch(query, plain, type);
      return { ...plain, matchScore: score, matchBreakdown: breakdown, matchType: type };
    })
    .filter((item) => item.matchScore >= 25)
    .sort((a, b) => b.matchScore - a.matchScore);
