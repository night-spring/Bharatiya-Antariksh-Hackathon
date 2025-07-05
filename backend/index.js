const express = require("express")
const cors = require("cors")
const cron = require("node-cron")
const fetchData = require("./data.js")
const { storePollutantData, storeAQIData, allAQI } = require("./db.js")
const path = require("path")

const app = express()

// CORS Configuration - This fixes the CORS error
const corsOptions = {
  origin: [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:64481", // Flutter web dev server
    "http://127.0.0.1:64481",
    "*", // Allow all origins for development - restrict in production
  ],
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
}

// Apply CORS middleware
app.use(cors(corsOptions))

// Additional CORS headers for preflight requests
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*")
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res.header("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept")

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    res.sendStatus(200)
    return
  }

  next()
})

// Body parsing middleware
app.use(express.json())
app.use(express.urlencoded({ extended: true }))

// Static files
app.use(express.static(path.join(__dirname, "../frontend/public")))

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    message: "AQI API Server is running",
  })
})

// AQI Data API endpoint with enhanced error handling
app.get("/api/aqidata", async (req, res) => {
  try {
    console.log("API request received for AQI data")

    const aqiData = await allAQI()

    if (!aqiData || aqiData.length === 0) {
      console.warn("No AQI data found in database")
      return res.status(404).json({
        error: "No AQI data available",
        message: "Database might be empty or not initialized",
      })
    }

    console.log(`Returning ${aqiData.length} AQI records`)

    // Ensure proper JSON response with CORS headers
    res.setHeader("Content-Type", "application/json")
    res.status(200).json(aqiData)
  } catch (err) {
    console.error("Error fetching AQI data:", err)
    res.status(500).json({
      error: "Failed to fetch AQI data",
      message: err.message,
      timestamp: new Date().toISOString(),
    })
  }
})

// API endpoint to get latest data count
app.get("/api/stats", async (req, res) => {
  try {
    const aqiData = await allAQI()
    res.json({
      totalStations: aqiData ? aqiData.length : 0,
      lastUpdated: new Date().toISOString(),
      status: "active",
    })
  } catch (err) {
    console.error("Error fetching stats:", err)
    res.status(500).json({
      error: "Failed to fetch stats",
      message: err.message,
    })
  }
})

// Home route
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../frontend/public/index.html"))
})

// 404 handler for undefined API routes
app.use((req, res, next) => {
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({
      error: "API endpoint not found",
      availableEndpoints: ["GET /api/health", "GET /api/aqidata", "GET /api/stats"],
    });
  }
  next();
});


// Global error handler
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err)
  res.status(500).json({
    error: "Internal server error",
    message: err.message,
    timestamp: new Date().toISOString(),
  })
})

// Start server
const PORT = process.env.PORT || 8080
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 AQI API Server is running on port ${PORT}`)
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`)
  console.log(`🌍 AQI Data API: http://localhost:${PORT}/api/aqidata`)
  console.log(`📈 Stats API: http://localhost:${PORT}/api/stats`)
})

// Server start-up data fetch and store
;(async () => {
  try {
    console.log("🔄 Initial data fetch and store starting ...")
    const data = await fetchData()
    console.log("✅ Initial pollutant data fetch completed successfully")
    await storePollutantData(data)
    console.log("✅ Pollutant data stored successfully")
    await storeAQIData()
    console.log("✅ AQI data stored successfully")

    // Log initial data count
    const aqiData = await allAQI()
    console.log(`📊 Initial data loaded: ${aqiData ? aqiData.length : 0} AQI records`)
  } catch (err) {
    console.error("❌ Error during initial pollutant data fetch:", err)
  }
})()

// Schedule a cron job to fetch and store data every hour
cron.schedule("1 * * * *", async () => {
  console.log("⏰ Running hourly cron job!")
  try {
    const data = await fetchData()
    console.log("✅ Pollutant data fetch completed successfully")
    await storePollutantData(data)
    console.log("✅ Pollutant data stored successfully")
    await storeAQIData()
    console.log("✅ AQI data stored successfully")

    // Log updated data count
    const aqiData = await allAQI()
    console.log(`📊 Updated data: ${aqiData ? aqiData.length : 0} AQI records`)
  } catch (err) {
    console.error("❌ Error during scheduled pollutant data fetch:", err)
  }
})

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("\n🛑 Shutting down AQI API Server...")
  process.exit(0)
})

process.on("SIGTERM", () => {
  console.log("\n🛑 Shutting down AQI API Server...")
  process.exit(0)
})
