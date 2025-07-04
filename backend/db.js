const postgres = require("postgres");
const dotenv = require("dotenv");
const fetchData = require("./data.js");
const { calculateAQI } = require("./aqiCalculator.js");

dotenv.config();

const connectionString = process.env.DATABASE_URL;
const sql = postgres(connectionString, {
  ssl: "require",
});

const pollutantId = ["PM2.5", "PM10", "NO2", "SO2", "CO", "OZONE", "NH3"];

function formatTime(datetime) {
  const [day, month, rest] = datetime.split("-");
  const [year, time] = rest.split(" ");
  return `${year}-${month}-${day}T${time}Z`;
}

async function getStationId(record) {
  const station_id = await sql`
        SELECT id FROM stations WHERE
        country = ${record.country} AND
        state = ${record.state} AND
        city = ${record.city} AND
        station = ${record.station} AND
        latitude = ${record.latitude} AND
        longitude = ${record.longitude}`;

  if (station_id.length != 0) {
    return station_id;
  }
  return [];
}

async function fetchPM() {
  try {
    const records = await fetchData(pollutantId[0]);
    if (!records && records.length == 0) {
      throw new Error("No PM2.5 data found");
    }

    for (const record of records) {
      if (record.avg_value === "NA") {
        continue;
      }

      let station_id = await getStationId(record);

      if (station_id.length != 0) {
        await sql`UPDATE pollutants
                    SET pm2_5 = ${record.avg_value}, 
                    time = ${formatTime(record.last_update)}
                    WHERE station_id = ${station_id[0].id}`;
      }
    }
  } catch (error) {
    console.error("Error fetching PM2.5 data:", error);
    throw error;
  }
}

async function fetchAndStoreData() {
  try {
    await fetchPM();

    for (const pollutant of pollutantId.slice(1, pollutantId.length)) {
      const records = await fetchData(pollutant);
      if (!records || records.length === 0) {
        console.warn(`No data found for ${pollutant}`);
        continue;
      }

      for (const record of records) {
        if (record.avg_value === "NA") {
          continue;
        }

        let station_id = await getStationId(record);

        if (station_id.length !== 0) {
          await sql`UPDATE pollutants
                        SET ${sql(pollutant.toLowerCase())} = ${
            record.avg_value
          }
                        WHERE station_id = ${station_id[0].id}
                        AND time = ${formatTime(record.last_update)}`;
        }
      }
    }
  } catch (error) {
    console.error("Error fetching and storing data:", error);
    throw error;
  }
}

async function allStations() {
  try {
    const stations = await sql`SELECT * FROM stations`;
    return stations;
  } catch (error) {
    console.error("Error fetching all stations:", error);
    throw error;
  }
}

async function allPollutants() {
  try {
    const pollutants = await sql`SELECT * FROM pollutants`;
    return pollutants;
  } catch (error) {
    console.error("Error fetching pollutants:", error);
    throw error;
  }
}

async function allAQI() {
  try {
    const aqiData = await sql`
      SELECT 
        aqitable.station_id, 
        aqitable.time, 
        stations.latitude, 
        stations.longitude, 
        aqitable.aqi, 
        aqitable.category, 
        aqitable.dominant_pollutant
      FROM aqitable
      JOIN stations ON aqitable.station_id = stations.id
    `;
    return aqiData;
  } catch (error) {
    console.error("Error fetching AQI data:", error);
    throw error;
  }
}

async function computeAQI() {
  try {
    const pollutantData = await allPollutants();
    const results = pollutantData.map((row) => calculateAQI(row));
    return results;
  } catch (err) {
    console.error("❌ Error calculating AQI:", err);
    return []; // Return empty array instead of undefined
  }
}

async function storeAQIData() {
  try {
    let aqiData = await computeAQI();
    for (const record of aqiData) {
      await sql`INSERT INTO aqitable
                    (station_id, aqi, time, category, dominant_pollutant)
                    VALUES (${record.station_id}, ${record.aqi}, ${record.time}, ${record.category}, ${record.dominantPollutant})`;
    }
  } catch (error) {
    console.error("Error storing AQI data:", error);
    throw error;
  }
}

module.exports = {
  fetchAndStoreData,
  storeAQIData,
  allStations,
  allPollutants,
  allAQI,
};
