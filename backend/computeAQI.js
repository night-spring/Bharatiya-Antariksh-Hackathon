const { allPollutants } = require("./db");
const { calculateAQI } = require("./aqiCalculator");
const fs = require("fs");

(async () => {
  try {
    const pollutantData = await allPollutants();
    const results = pollutantData.map(row => calculateAQI(row));

    fs.writeFileSync("computedAQI.json", JSON.stringify(results, null, 2));
    console.log("✅ AQI data saved to computedAQI.json");
  } catch (err) {
    console.error("❌ Error calculating AQI:", err);
  }
})();
