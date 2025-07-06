// backend/server.js

const express = require("express");
const cors = require("cors");
const cron = require("node-cron");
const fetchData = require("./data.js");
const { storePollutantData, storeAQIData, allAQI } = require("./db.js");
const path = require("path");

const app = express();

// --- CORS Configuration (Best Practice) ---
const corsOptions = {
  // Allow all origins for development. In production, use a whitelist.
  origin: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: [
    "Content-Type",
    "Authorization",
    "Accept",
    "Access-Control-Allow-Origin",
    "Access-Control-Allow-Methods",
    "Access-Control-Allow-Headers",
  ],
  credentials: true,
  optionsSuccessStatus: 200,
};
app.use(cors(corsOptions));

// --- Body Parsing Middleware ---
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- Serve Static Files (if you have a frontend build) ---
app.use(express.static(path.join(__dirname, "../frontend/public")));

// --- Health Check Endpoint ---
app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    message: "AQI API Server is running",
  });
});

// --- AQI Data Endpoint ---
app.get("/api/aqidata", async (req, res) => {
  try {
    console.log("API request received for AQI data");
    const aqiData = await allAQI();

    if (!aqiData || aqiData.length === 0) {
      console.warn("No AQI data found in database");
      return res.status(404).json({
        error: "No AQI data available",
        message: "Database might be empty or not initialized",
      });
    }

    res.setHeader("Content-Type", "application/json");
    res.status(200).json(aqiData);
  } catch (err) {
    console.error("Error fetching AQI data:", err);
    res.status(500).json({
      error: "Failed to fetch AQI data",
      message: err.message,
      timestamp: new Date().toISOString(),
    });
  }
});

// --- Stats Endpoint ---
app.get("/api/stats", async (req, res) => {
  try {
    const aqiData = await allAQI();
    res.json({
      totalStations: aqiData ? aqiData.length : 0,
      lastUpdated: new Date().toISOString(),
      status: "active",
    });
  } catch (err) {
    console.error("Error fetching stats:", err);
    res.status(500).json({
      error: "Failed to fetch stats",
      message: err.message,
    });
  }
});

// --- Home Route (serves index.html for SPA frontend) ---
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../frontend/public/index.html"));
});

// --- 404 Handler for Undefined API Routes ---
app.use((req, res, next) => {
  if (req.path.startsWith("/api/")) {
    return res.status(404).json({
      error: "API endpoint not found",
      availableEndpoints: [
        "GET /api/health",
        "GET /api/aqidata",
        "GET /api/stats",
      ],
    });
  }
  next();
});

// --- Global Error Handler ---
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({
    error: "Internal server error",
    message: err.message,
    timestamp: new Date().toISOString(),
  });
});

// --- Start Server ---
const PORT = process.env.PORT || 8080;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 AQI API Server is running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🌍 AQI Data API: http://localhost:${PORT}/api/aqidata`);
  console.log(`📈 Stats API: http://localhost:${PORT}/api/stats`);
});

// --- Initial Data Fetch and Store ---
(async () => {
  try {
    console.log("🔄 Initial data fetch and store starting ...");
    const data = await fetchData();
    console.log("✅ Initial pollutant data fetch completed successfully");
    await storePollutantData(data);
    console.log("✅ Pollutant data stored successfully");
    await storeAQIData();
    console.log("✅ AQI data stored successfully");

    // Log initial data count
    const aqiData = await allAQI();
    console.log(`📊 Initial data loaded: ${aqiData ? aqiData.length : 0} AQI records`);
  } catch (err) {
    console.error("❌ Error during initial pollutant data fetch:", err);
  }
})();

// --- Cron Job: Fetch and Store Data Every Hour ---
cron.schedule("1 * * * *", async () => {
  console.log("⏰ Running hourly cron job!");
  try {
    const data = await fetchData();
    console.log("✅ Pollutant data fetch completed successfully");
    await storePollutantData(data);
    console.log("✅ Pollutant data stored successfully");
    await storeAQIData();
    console.log("✅ AQI data stored successfully");

    // Log updated data count
    const aqiData = await allAQI();
    console.log(`📊 Updated data: ${aqiData ? aqiData.length : 0} AQI records`);
  } catch (err) {
    console.error("❌ Error during scheduled pollutant data fetch:", err);
  }
});

// --- Graceful Shutdown ---
process.on("SIGINT", () => {
  console.log("\n🛑 Shutting down AQI API Server...");
  process.exit(0);
});

process.on("SIGTERM", () => {
  console.log("\n🛑 Shutting down AQI API Server...");
  process.exit(0);
});
