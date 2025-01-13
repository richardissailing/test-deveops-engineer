import request from 'supertest';
import app from '../app.js';

describe('Express App', () => {
  // Health check endpoint
  test('GET /health returns status ok', async () => {
    const response = await request(app).get('/health');
    expect(response.statusCode).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });

  // Root endpoint
  test('GET / returns welcome message', async () => {
    const response = await request(app).get('/');
    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty('message');
    expect(typeof response.body.message).toBe('string');
  });

});