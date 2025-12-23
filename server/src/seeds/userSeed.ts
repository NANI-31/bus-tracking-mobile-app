import User, { UserRole } from "../models/User";
import crypto from "crypto";
import bcrypt from "bcryptjs";

export const seedUsers = async (collegeId: string) => {
  console.log("Seeding Users...");

  // Clear existing
  await User.deleteMany({});

  const password = "a";

  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(password, salt);

  const users = [
    {
      _id: crypto.randomUUID(),
      fullName: "nani",
      email: "darkbutterflystar31@gmail.com",
      password: passwordHash,
      role: UserRole.Student,
      collegeId,
      approved: true,
      emailVerified: true,
      rollNumber: "20JR1A0501",
    },
    {
      _id: crypto.randomUUID(),
      fullName: "Student One",
      email: "s@s.com",
      password: passwordHash,
      role: UserRole.Student,
      collegeId,
      approved: true,
      emailVerified: true,
      rollNumber: "20JR1A0501",
    },
    {
      _id: crypto.randomUUID(),
      fullName: "Teacher One",
      email: "t@t.com",
      password: passwordHash,
      role: UserRole.Teacher,
      collegeId,
      approved: true,
      emailVerified: true,
    },
    {
      _id: crypto.randomUUID(),
      fullName: "Parent One",
      email: "p@p.com",
      password: passwordHash,
      role: UserRole.Parent,
      collegeId,
      approved: true,
      emailVerified: true,
    },
    {
      _id: crypto.randomUUID(),
      fullName: "Coordinator One",
      email: "c@c.com",
      password: passwordHash,
      role: UserRole.BusCoordinator,
      collegeId,
      approved: true,
      emailVerified: true,
    },
  ];

  const createdUsers = await User.insertMany(users);
  console.log("Users seeded.");
  return createdUsers;
};
