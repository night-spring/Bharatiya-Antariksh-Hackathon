const express = require("express");
const cron = require("node-cron");
const fetchData = require("./data.js");
const { storePollutantData, storeAQIData, allAQI } = require("./db.js");

const path = require("path");
const app = express();

app.use(express.static(path.join(__dirname, "../frontend/public")));

app.listen(8080, () => {
  console.log("server is listening on port 8080");
});


// Server start-up data fetch and store
(async () => {
  try {
    console.log("Initial data fetch and store starting ...");

    let data = await fetchData();
    console.log("Initial pollutant data fetch completed successfully");

    await storePollutantData(data);
    console.log("Pollutant data stored successfully");

    await storeAQIData();
    console.log("AQI data stored successfully");
  } catch (err) {
    console.error("Error during initial pollutant data fetch :", err);
  }
})();

// Schedule a cron job to fetch and store data every hour
cron.schedule("1 * * * *", async () => {
  console.log("Running cron job!");
  try {
    let data = await fetchData();
    console.log("Pollutant data fetch completed successfully");

    await storePollutantData(data);
    console.log("Pollutant data stored successfully");

    await storeAQIData();
    console.log("AQI data stored successfully");
  } catch (err) {
    console.error("Error during pollutant data fetch :", err);
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
