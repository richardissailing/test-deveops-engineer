import express from 'express';
import * as promClient from 'prom-client';
import winston from 'winston';

// Prometheus metrics setup
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Create custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5]
});
register.registerMetric(httpRequestDuration);

// Logging setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: process.env.DEPLOYMENT_COLOR || 'app' },
  transports: [
    new winston.transports.Console()
  ]
});

// Create Express app
const app = express();

// Middleware for metrics and logging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const labels = {
      method: req.method,
      route: req.route?.path || req.path,
      code: res.statusCode
    };
    httpRequestDuration.observe(labels, duration / 1000);
    logger.info('Request processed', {
      ...labels,
      duration,
      userAgent: req.get('user-agent')
    });
  });
  next();
});

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.send(await register.metrics());
});

app.get('/', (req, res) => {
  res.json({ message: 'Welcome to the app!' });
});

// Sample data endpoint
app.get('/api/data', (req, res) => {
  res.json({ data: 'Sample data response' });
});

// Error endpoint
app.get('/api/error', (req, res, next) => {
  const error = new Error('Test error endpoint');
  next(error);
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Error occurred', {
    error: err.message,
    stack: err.stack
  });
  res.status(500).json({ error: 'Internal Server Error' });
});

export default app;
