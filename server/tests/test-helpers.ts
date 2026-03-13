import jwt from 'jsonwebtoken';
import { Types } from 'mongoose';
import User from '@/models/User.model';
import College from '@/models/College.model';
import { Bus } from '@/models/Bus.model';

export const generateTestToken = (payload: any) => {
  return jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });
};

export const createTestCollege = async (overrides = {}) => {
  const college = new College({
    name: 'Test College',
    busNumbers: ['B1', 'B2'],
    allowedDomains: ['test.edu'],
    ...overrides,
  });
  return await college.save();
};

export const createTestUser = async (overrides = {}) => {
  const user = new User({
    fullName: 'Test User',
    email: `test-${Date.now()}@test.edu`,
    password: 'password123',
    role: 'student',
    emailVerified: true,
    approved: true,
    ...overrides,
  });
  return await user.save();
};

export const createTestBus = async (collegeId: Types.ObjectId | string, overrides = {}) => {
  const bus = new Bus({
    busNumber: 'B1',
    collegeId,
    status: 'unassigned',
    isActive: false,
    ...overrides,
  });
  return await bus.save();
};

export const getAuthHeader = (token: string) => ({
  Authorization: `Bearer ${token}`,
});
