const request = require('supertest');
const app = require('../../server');

describe('API Integration Tests', () => {
  test('1. GET /health returns 200 OK', async () => {
    const response = await request(app).get('/health');
    expect(response.statusCode).toBe(200);
  });

  test('2. GET /health returns JSON payload', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toHaveProperty('status', 'UP');
  });
});