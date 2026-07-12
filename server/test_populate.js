const mongoose = require('mongoose');

const mongoUri = "mongodb://nani:nani@ac-qb3lmd3-shard-00-00.nkgeayy.mongodb.net:27017,ac-qb3lmd3-shard-00-01.nkgeayy.mongodb.net:27017,ac-qb3lmd3-shard-00-02.nkgeayy.mongodb.net:27017/college_bus_tracking?ssl=true&replicaSet=atlas-gktisf-shard-0&authSource=admin&appName=Cluster0";

// Define schemas first (so populate works)
const UserSchema = new mongoose.Schema({
  _id: String,
  fullName: String,
  email: String
});
const User = mongoose.model('User', UserSchema);

const TeacherOverrideRequestSchema = new mongoose.Schema({
  teacherId: { type: String, ref: 'User' },
  busId: { type: mongoose.Schema.Types.ObjectId, ref: 'Bus' },
  collegeId: { type: mongoose.Schema.Types.ObjectId, ref: 'College' },
  status: String
});
const TeacherOverrideRequest = mongoose.model('TeacherOverrideRequest', TeacherOverrideRequestSchema);

const BusSchema = new mongoose.Schema({
  busNumber: String
});
const Bus = mongoose.model('Bus', BusSchema);

async function run() {
  await mongoose.connect(mongoUri);
  console.log("Connected!");

  // Find requests
  const requests = await TeacherOverrideRequest.find({})
    .populate('teacherId', 'fullName email')
    .populate('busId', 'busNumber');

  console.log("Populated requests:", JSON.stringify(requests, null, 2));

  await mongoose.disconnect();
}

run().catch(console.error);
