const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("working");
});

app.get("/data", async (req, res) => {
  const fetchData = require("./data").default;
  try {
    const data = await fetchData();
    res.json(data);
  } catch (err) {
    console.error("Error fetching data:", err);
    res.status(500).send("Internal Server Error");
  }
});

app.listen(8080, () => {
  console.log("server is listening on port 8080");
});
