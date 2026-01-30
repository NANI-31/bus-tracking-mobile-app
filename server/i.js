const mongoose = require("mongoose");

// 1. MongoDB connection URI
// For local MongoDB:
// const MONGO_URI = "mongodb://127.0.0.1:27017/testdb";

// For MongoDB Atlas (example):
const MONGO_URI =
  "mongodb://nani:nani@ac-qb3lmd3-shard-00-00.nkgeayy.mongodb.net:27017,ac-qb3lmd3-shard-00-01.nkgeayy.mongodb.net:27017,ac-qb3lmd3-shard-00-02.nkgeayy.mongodb.net:27017/college_bus_tracking?replicaSet=atlas-gktisf-shard-0&ssl=true&authSource=admin";

async function main() {
  try {
    // 2. Connect to MongoDB
    await mongoose.connect(MONGO_URI);

    console.log("✅ MongoDB connected");

    // 3. Create a schema
    // const userSchema = new mongoose.Schema({
    //   name: String,
    //   email: String,
    //   age: Number,
    //   createdAt: {
    //     type: Date,
    //     default: Date.now,
    //   },
    // });

    // 4. Create a model
    // const User = mongoose.model("User", userSchema);

    // 5. Insert a document
    // const user = await User.create({
    //   name: "Test User",
    //   email: "test@example.com",
    //   age: 25,
    // });

    // console.log("📝 User inserted:", user);

    // // 6. Read from database
    // const users = await User.find();
    // console.log("📦 Users in DB:", users);
  } catch (error) {
    console.error("❌ Error:", error);
  } finally {
    // 7. Close connection
    await mongoose.connection.close();
    console.log("🔌 MongoDB connection closed");
  }
}

main();
