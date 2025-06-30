require("dotenv").config();

AQI_API_KEY = process.env.AQI_API_KEY;
//console.log(AQI_API_KEY);

let URL = `https://api.data.gov.in/resource/3b01bcb8-0b14-4abf-b6f2-c1bfd384ba69?api-key=${AQI_API_KEY}&format=json&limit=1000&filters%5Bcountry%5D=India&filters%5Bpollutant_id%5D=PM10`;

async function fetchData() {
  try {
    const response = await fetch(URL);
    const data = await response.json();
    return data.records;
  } catch (err) {
    console.log("Error: ", err);
  }
}

export default fetchData;
