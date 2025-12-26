import User, { UserRole } from "../models/User";
import crypto from "crypto";
import bcrypt from "bcryptjs";

export const seedUsers = async (
  collegeId: string,
  domain: string,
  prefix: string
) => {
  console.log(`Seeding Users for college with domain ${domain}...`);

  const password = "a";
  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(password, salt);

  const roleConfigs = [
    { name: "Student", role: UserRole.Student, prefix: "s", count: 10 },
    { name: "Teacher", role: UserRole.Teacher, prefix: "t", count: 5 },
    { name: "Parent", role: UserRole.Parent, prefix: "p", count: 5 },
    { name: "Driver", role: UserRole.Driver, prefix: "d", count: 15 },
    {
      name: "Coordinator",
      role: UserRole.BusCoordinator,
      prefix: "c",
      count: 1,
    },
    { name: "Admin", role: UserRole.Admin, prefix: "ad", count: 1 },
  ];

  const users: any[] = [];

  for (const config of roleConfigs) {
    for (let i = 1; i <= config.count; i++) {
      const email =
        config.count === 1
          ? `${config.prefix}@${domain}`
          : `${config.prefix}${i}@${domain}`;
      users.push({
        _id: crypto.randomUUID(),
        fullName: `${prefix} ${config.name} ${i}`,
        email: email,
        password: passwordHash,
        role: config.role,
        collegeId,
        approved: true,
        emailVerified: true,
        ...(config.role === UserRole.Student
          ? { rollNumber: `${prefix}-${100 + i}` }
          : {}),
      });
    }
  }

  // Special user for Nani
  if (domain === "kkr.ac.in") {
    users.push({
      _id: crypto.randomUUID(),
      fullName: "nani",
      email: "darkbutterflystar31@gmail.com",
      password: passwordHash,
      role: UserRole.Student,
      collegeId,
      approved: true,
      emailVerified: true,
      rollNumber: "20JR1A0501",
    });
  }

  const createdUsers = await User.insertMany(users);
  console.log(`Users seeded for ${domain}.`);
  return createdUsers;
};
