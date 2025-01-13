import * as promClient from 'prom-client';

// Create a Registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({
  register,
  prefix: 'app_',
  gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5]
});

// Custom metrics
const metrics = {
  httpRequestDuration: new promClient.Histogram({
    name: 'app_http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.1, 0.5, 1, 2, 5]
  }),

  httpRequestTotal: new promClient.Counter({
    name: 'app_http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code']
  }),

  httpRequestErrors: new promClient.Counter({
    name: 'app_http_request_errors_total',
    help: 'Total number of HTTP request errors',
    labelNames: ['method', 'route', 'error_type']
  }),

  memoryUsage: new promClient.Gauge({
    name: 'app_memory_usage_bytes',
    help: 'Process memory usage',
    collect() {
      const usage = process.memoryUsage();
      this.set(usage.heapUsed);
    }
  })
};

// Register custom metrics
Object.values(metrics).forEach(metric => register.registerMetric(metric));

export {
  register,
  metrics
};