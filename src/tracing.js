import { NodeSDK } from '@opentelemetry/sdk-node';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

export function setupTracing(serviceName) {
  // Check if we're in a testing environment
  if (process.env.NODE_ENV === 'test') {
    console.log(`Tracing setup for service: ${serviceName}`);
    return {
      start: () => {},
      shutdown: () => {}
    };
  }

  // Actual tracing implementation for production/development
  const exporter = new JaegerExporter({
    endpoint: 'http://jaeger:14268/api/traces'
  });

  const sdk = new NodeSDK({
    resource: new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
    }),
    traceExporter: exporter,
    instrumentations: [getNodeAutoInstrumentations()]
  });

  sdk.start();
  return sdk;
}