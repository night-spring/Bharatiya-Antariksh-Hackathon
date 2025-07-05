const postgres = require("postgres");
const dotenv = require("dotenv");

const { calculateAQI } = require("./aqiCalculator.js");

dotenv.config();

const connectionString = process.env.DATABASE_URL;
const sql = postgres(connectionString, {
  ssl: "require",
});

const pollutantId = ["PM2.5", "PM10", "NO2", "SO2", "CO", "OZONE", "NH3"];

function formatTime(datetime) {
  let [day, month, rest] = datetime.split("-");
  let [year, time] = rest.split(" ");
  return `${year}-${month}-${day} ${time}`;
}

async function getStationId(record) {
  let station_id = await sql`
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

async function addNewStation(records){
  try{
    for (let i=0; i < records.length; i++){
      for (let record of records[i]) {
        let stationId = await getStationId(record);
        if (stationId.length === 0) {
          await sql`INSERT INTO stations
                        (country, state, city, station, latitude, longitude)
                        VALUES (${record.country}, ${record.state}, ${record.city}, ${record.station}, ${record.latitude}, ${record.longitude})`;
        } 
      }
    }
  } catch (error) {
    console.error("Error adding new stations:", error);
    throw error;
  }
}

async function storePollutantData(records) {
  await addNewStation(records);
  try {
    for (let i = 0; i < records.length; i++) {
      for (let record of records[i]) {
        if (record.avg_value === "NA") {
          continue;
        }

        let station_id = await getStationId(record);
        let pollutant = pollutantId[i].toLowerCase();
        if (pollutant==="pm2.5"){
          pollutant = "pm2_5";
        }
        await sql`INSERT INTO pollutants (station_id, ${sql(pollutant)}, time)
                  VALUES (${station_id[0].id}, ${record.avg_value}, ${formatTime(record.last_update)})
                  ON CONFLICT (station_id)
                  DO UPDATE SET
                    ${sql(pollutant)} = EXCLUDED.${sql(pollutant)},
                    time = EXCLUDED.time;`;
      }
    }
  } catch (error) {
    console.error("Error storing data:", error);
    throw error;
  }
}

async function allStations() {
  try {
    let stations = await sql`SELECT * FROM stations`;
    return stations;
  } catch (error) {
    console.error("Error fetching all stations:", error);
    throw error;
  }
}

async function allPollutants() {
  try {
    let pollutants = await sql`SELECT * FROM pollutants`;
    return pollutants;
  } catch (error) {
    console.error("Error fetching pollutants:", error);
    throw error;
  }
}

async function computeAQI() {
  try {
    let pollutantData = await allPollutants();
    console.log(pollutantData.slice(0, 5)); 
    let results = pollutantData.map((row) => calculateAQI(row));
    return results;
  } catch (err) {
    console.error("❌ Error calculating AQI:", err);
    return []; // Return empty array instead of undefined
  }
}

async function storeAQIData() {
  try {
    let aqiData = await computeAQI();
    for (let record of aqiData) {
      await sql` INSERT INTO aqitable
                    (station_id, aqi, time, category, dominant_pollutant)
                  VALUES (${record.station_id}, ${record.aqi}, ${record.time}, ${record.category}, ${record.dominantPollutant})
                  ON CONFLICT (station_id)
                  DO UPDATE SET
                    aqi = EXCLUDED.aqi,
                    time = EXCLUDED.time,
                    category = EXCLUDED.category,
                    dominant_pollutant = EXCLUDED.dominant_pollutant;`;
    }
  } catch (error) {
    console.error("Error storing AQI data:", error);
    throw error;
  }
}

async function allAQI() {
  try {
    let aqiData = await sql`
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

module.exports = {
  storePollutantData,
  allStations,
  allPollutants,
  storeAQIData,
  allAQI,
};
