// Jest setup file
// Set environment variables for testing
process.env.JWT_SECRET = "test-jwt-secret-for-testing";
process.env.NODE_ENV = "test";

// Suppress console logs during tests (optional)
// global.console = {
//   ...console,
//   log: jest.fn(),
//   debug: jest.fn(),
//   info: jest.fn(),
// };
