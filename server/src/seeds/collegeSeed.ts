import College from "../models/College";

export const seedColleges = async (collegeData: {
  name: string;
  domains: string[];
  busNumbers?: string[];
}) => {
  console.log("Seeding College...");

  const college = await College.create({
    name: collegeData.name,
    allowedDomains: collegeData.domains,
    verified: true,
    createdBy: "SYSTEM_SEED",
    busNumbers: collegeData.busNumbers || [],
  });

  console.log("College seeded:", college.name);
  return college;
};
