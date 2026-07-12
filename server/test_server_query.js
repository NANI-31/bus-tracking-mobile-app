const mongoose = require('mongoose');

process.env.NODE_ENV = 'development';

const mongoUri = "mongodb://nani:nani@ac-qb3lmd3-shard-00-00.nkgeayy.mongodb.net:27017,ac-qb3lmd3-shard-00-01.nkgeayy.mongodb.net:27017,ac-qb3lmd3-shard-00-02.nkgeayy.mongodb.net:27017/college_bus_tracking?ssl=true&replicaSet=atlas-gktisf-shard-0&authSource=admin&appName=Cluster0";

async function run() {
  await mongoose.connect(mongoUri);
  console.log("Connected to MongoDB!");

  // Load the actual models to ensure they register in Mongoose
  require('./dist/models/User.model');
  require('./dist/models/Bus.model');
  const { TeacherOverrideRequest } = require('./dist/models/TeacherOverrideRequest.model');

  const stringCollegeId = "6a2e675191531bf829ecdc4c";
  
  const query = { collegeId: stringCollegeId, status: "pending" };
  console.log("Querying with:", query);
  
  const requests = await TeacherOverrideRequest.find(query)
    .populate("teacherId", "fullName email phoneNumber")
    .populate("busId", "busNumber");

  console.log("Found requests:", requests.length);
  console.log("Requests detail:", requests);

  await mongoose.disconnect();
}

run().catch(console.error);
