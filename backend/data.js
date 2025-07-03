import dotenv from "dotenv";
import fetch from "node-fetch";

dotenv.config();

const AQI_API_KEY = process.env.AQI_API_KEY;

function fetchURL(pollutant_id) {
  return `https://api.data.gov.in/resource/3b01bcb8-0b14-4abf-b6f2-c1bfd384ba69?api-key=${AQI_API_KEY}&format=json&limit=1000&filters%5Bcountry%5D=India&filters%5Bpollutant_id%5D=${pollutant_id}`;
}


// Fetching data from the API
async function fetchData(pollutant_id) {
  try {
    const aqiURL = fetchURL(pollutant_id);
    const response = await fetch(aqiURL);
    const data = await response.json();
    return data.records;
  } catch (err) {
    console.log("Error: ", err);
    throw err;
  }
}

export default fetchData;
