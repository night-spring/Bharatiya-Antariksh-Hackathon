const { allPollutants } = require("./db.js");
const { calculateAQI } = require("./aqiCalculator.js");
//const fs = require("fs");

async function computeAQI() {
  try {
    const pollutantData = await allPollutants();
    const results = pollutantData.map((row) => calculateAQI(row));
    return results;

    //fs.writeFileSync("computedAQI.json", JSON.stringify(results, null, 2));
    //console.log("✅ AQI data saved to computedAQI.json");
  
  } catch (err) {
    console.error("❌ Error calculating AQI:", err);
    return []; // Return empty array instead of undefined
  }
}

// Export the computeAQI function
module.exports = computeAQI;
