const breakpoints = {
  pm2_5: [
    { bpL: 0, bpH: 30, iL: 0, iH: 50 },
    { bpL: 31, bpH: 60, iL: 51, iH: 100 },
    { bpL: 61, bpH: 90, iL: 101, iH: 200 },
    { bpL: 91, bpH: 120, iL: 201, iH: 300 },
    { bpL: 121, bpH: 250, iL: 301, iH: 400 },
    { bpL: 251, bpH: 500, iL: 401, iH: 500 },
  ],
  pm10: [
    { bpL: 0, bpH: 50, iL: 0, iH: 50 },
    { bpL: 51, bpH: 100, iL: 51, iH: 100 },
    { bpL: 101, bpH: 250, iL: 101, iH: 200 },
    { bpL: 251, bpH: 350, iL: 201, iH: 300 },
    { bpL: 351, bpH: 430, iL: 301, iH: 400 },
    { bpL: 431, bpH: 500, iL: 401, iH: 500 },
  ],
  no2: [
    { bpL: 0, bpH: 40, iL: 0, iH: 50 },
    { bpL: 41, bpH: 80, iL: 51, iH: 100 },
    { bpL: 81, bpH: 180, iL: 101, iH: 200 },
    { bpL: 181, bpH: 280, iL: 201, iH: 300 },
    { bpL: 281, bpH: 400, iL: 301, iH: 400 },
    { bpL: 401, bpH: 500, iL: 401, iH: 500 },
  ],
  so2: [
    { bpL: 0, bpH: 40, iL: 0, iH: 50 },
    { bpL: 41, bpH: 80, iL: 51, iH: 100 },
    { bpL: 81, bpH: 380, iL: 101, iH: 200 },
    { bpL: 381, bpH: 800, iL: 201, iH: 300 },
    { bpL: 801, bpH: 1600, iL: 301, iH: 400 },
    { bpL: 1601, bpH: 2000, iL: 401, iH: 500 },
  ],
};

function getCategory(aqi) {
  if (aqi <= 50) return "Good";
  if (aqi <= 100) return "Satisfactory";
  if (aqi <= 200) return "Moderate";
  if (aqi <= 300) return "Poor";
  if (aqi <= 400) return "Very Poor";
  return "Severe";
}

function getSubIndex(value, pollutant) {
  if (!value || !breakpoints[pollutant]) return null;
  const bp = breakpoints[pollutant];
  for (let i = 0; i < bp.length; i++) {
    const { bpL, bpH, iL, iH } = bp[i];
    if (value >= bpL && value <= bpH) {
      return ((iH - iL) / (bpH - bpL)) * (value - bpL) + iL;
    }
  }
  return null;
}

function calculateAQI(data) {
  const pollutants = ["pm2_5", "pm10", "no2", "so2"]; // Only these affect AQI
  let maxAQI = -1;
  let dominantPollutant = "";

  pollutants.forEach((p) => {
    const val = parseFloat(data[p]);
    const subIndex = getSubIndex(val, p);
    if (subIndex !== null && subIndex > maxAQI) {
      maxAQI = subIndex;
      dominantPollutant = p;
    }
  });

  const roundedAQI = Math.round(maxAQI);

  return {
    station_id: data.station_id,
    time: data.time,
    aqi: roundedAQI.toString(),
    category: getCategory(roundedAQI),
    dominantPollutant,
  };
}

module.exports = { calculateAQI };
