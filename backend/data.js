const dotenv = require("dotenv");
const fetch = (...args) =>
  import("node-fetch").then((mod) => mod.default(...args));

dotenv.config();

const AQI_API_KEY = process.env.AQI_API_KEY;

function fetchURL(pollutant_id) {
  return `https://api.data.gov.in/resource/3b01bcb8-0b14-4abf-b6f2-c1bfd384ba69?api-key=${AQI_API_KEY}&format=json&limit=1000&filters%5Bcountry%5D=India&filters%5Bpollutant_id%5D=${pollutant_id}`;
}

const pollutantId = ["PM2.5", "PM10", "NO2", "SO2", "CO", "OZONE", "NH3"];

// Fetching data from the API
async function fetchData() {
  try {
    const results = [];
    for (const pollutant of pollutantId) {
      const aqiURL = fetchURL(pollutant);
      const response = await fetch(aqiURL);
      const data = (await response.json()).records;
      results.push(data);
    }
    //console.log(results.length);
    return results;
  } catch (err) {
    console.log("Error: ", err);
    throw err;
  }
}

//export default fetchData;
module.exports = fetchData;
