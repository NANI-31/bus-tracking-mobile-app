import College from "../models/College";

export const seedColleges = async (collegeData: {
  name: string;
  domains: string[];
}) => {
  console.log("Seeding College...");

  // Clear existing (optional, usually main runner handles or we handle here)
  await College.deleteMany({});

  const college = await College.create({
    name: collegeData.name,
    allowedDomains: collegeData.domains,
    verified: true,
    createdBy: "SYSTEM_SEED",
  });

  console.log("College seeded:", college.name);
  return college;
};
