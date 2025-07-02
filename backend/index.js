import express from "express";
import fetchData from "./data.js";
const app = express();

app.get("/", (req, res) => {
  res.send("working");
});

app.get("/data", async (req, res) => {
  try {
    const pollutantId = ["PM10", "PM2.5", "NO2", "SO2", "CO", "OZONE", "NH3"];
    
  } catch (err) {
    console.error("Error fetching data:", err);
    res.status(500).send("Internal Server Error");
  }
});

app.listen(8080, () => {
  console.log("server is listening on port 8080");
});
