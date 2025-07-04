const express = require("express");
const cron = require("node-cron");
const fetchData = require("./data.js");
const {
  fetchAndStoreData,
  storeAQIData,
  allStations,
  allPollutants,
  allAQI,
} = require("./db.js");
const computeAQI = require("./computeAQI.js");

const path = require("path");
const app = express();

// app.get("/", (req, res) => {
//   res.send("working");
// });
app.use(express.static(path.join(__dirname, "../frontend/public")));

// Server start-up data fetch and store
// (async () => {
//   try {
//     console.log("Initial pollutant data fetch!");
//     await fetchAndStoreData();
//     console.log("Initial data fetch and store completed successfully");
//   } catch (err) {
//     console.error("Error during initial data fetch and store:", err);
//   }

//   try {
//     console.log("Initial aqi data fetch!");
//     await storeAQIData();
//     console.log("Initial AQI computation completed successfully");
//   } catch (err) {
//     console.error("Error during initial AQI computation:", err);
//   }
// })();

// Schedule a cron job to fetch and store data every hour
cron.schedule("1 * * * *", async () => {
  console.log("Running cron job!");
  try {
    await fetchAndStoreData();
    console.log("Pollutant data fetch and store completed successfully");
  } catch (err) {
    console.error("Error during pollutant data fetch and store:", err);
  }

  try {
    await storeAQIData();
    console.log("AQI computation completed successfully");
  } catch (err) {
    console.error("Error during AQI computation:", err);
  }
});

// Home route
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../frontend/public/index.html"));
});

app.get("/api/aqidata", async (req, res) => {
  try {
    let aqiData = await allAQI();
    res.send(aqiData);
  } catch (err) {
    console.error("Error fetching AQI data:", err);
    res.status(500).json({ error: "Failed to fetch AQI data" });
  }
});

app.listen(8080, () => {
  console.log("server is listening on port 8080");
});
