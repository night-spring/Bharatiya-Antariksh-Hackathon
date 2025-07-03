const express = require("express");
const cron = require("node-cron");
const fetchData = require("./data.js");
const {fetchAndStoreData, allStations} = require("./db.js");

const path = require("path");
const app = express();

// app.get("/", (req, res) => {
//   res.send("working");
// });
app.use(express.static(path.join(__dirname, "../frontend/public")));

// Server start-up data fetch and store
// (async () => {
//   try {
//   await fetchAndStoreData();
//     console.log("Initial data fetch and store completed successfully");
//   } catch (err) {
//     console.error("Error during initial data fetch and store:", err);
//   }
// })();

// // Schedule a cron job to fetch and store data every hour
// cron.schedule("1 * * * *", async () => {
//   console.log("Running cron job to fetch and store data");
//   await fetchAndStoreData()
//     .then(() => {
//       console.log("Data fetched and stored successfully");
//     })
//     .catch((err) => {
//       console.error("Error :", err);
//     });
// });


// Home route
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../frontend/public/index.html"));
});

app.get("/data", async (req, res) => {
  try {
    let allStationsData = await allStations();
    res.json(allStationsData);
  } catch (err) {
    console.error("Error fetching all stations data:", err);
    res.status(500).json({ error: "Failed to fetch data" });
  }
});

app.listen(8080, () => {
  console.log("server is listening on port 8080");
});
