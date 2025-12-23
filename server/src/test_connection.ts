import mongoose from "mongoose";

const uri =
  "mongodb+srv://nani:nani@cluster0.nkgeayy.mongodb.net/college_bus_tracking?retryWrites=true&w=majority";

console.log("Testing connection to:", uri);

mongoose
  .connect(uri)
  .then(() => {
    console.log("SUCCESS: Connected to MongoDB!");
    process.exit(0);
  })
  .catch((err) => {
    console.error("FAILURE: Could not connect to MongoDB.");
    console.error("Error name:", err.name);
    console.error("Error message:", err.message);
    if (err.codeName) console.error("CodeName:", err.codeName);
    if (err.code) console.error("Code:", err.code);
    process.exit(1);
  });
