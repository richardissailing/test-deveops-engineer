# DevOps Implementation Project

A comprehensive DevOps setup for a Node.js application featuring blue/green deployment, monitoring, tracing, and log aggregation.

## Features

### Core Infrastructure
- Blue/Green Deployment Strategy
- Nginx Load Balancer
- Docker Containerization
- Automated Testing and CI/CD

### Monitoring Stack
- Prometheus metrics collection
- Grafana dashboards
- Jaeger distributed tracing
- Loki log aggregation
- Health check monitoring

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js (for local development)
- Git

### Docker Configuration
Before starting, ensure Docker is properly configured:

1. Configure Docker DNS:
```json
{
    "dns": ["8.8.8.8", "8.8.4.4"],
    "dns-opts": ["ndots:1"],
    "mtu": 1500,
    "ipv6": false
}
```

2. Apply configuration:
```bash
sudo systemctl restart docker
```

### Project Structure
```
.
├── .github/
│   └── workflows/          # CI/CD pipeline configurations
├── grafana/
│   ├── dashboards/        # Grafana dashboard definitions
│   └── provisioning/      # Grafana configuration
│       └── datasources/   # Datasource configurations
├── loki/                  # Loki configuration
├── nginx/
│   └── nginx.conf         # Load balancer configuration
├── prometheus/
│   └── prometheus.yml     # Prometheus configuration
├── src/                   # Application source code
├── promtail/              # Loki configuration
├── docker-compose.blue-green.yml
└── Dockerfile
```

### Getting Started

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-name>
```

2. Start the services in order:
```bash
# Start core services
docker-compose -f docker-compose.blue-green.yml up -d nginx prometheus grafana

# Start applications
docker-compose -f docker-compose.blue-green.yml up -d app-blue app-green

# Start monitoring services
docker-compose -f docker-compose.blue-green.yml up -d jaeger loki
```

### Service Endpoints
- Blue Deployment: http://localhost:3002
- Green Deployment: http://localhost:3003
- Load Balancer: http://localhost:80
- Grafana: http://localhost:3001 (admin/admin)
- Prometheus: http://localhost:9090
- Jaeger UI: http://localhost:16686
- Loki: http://localhost:3100

## Deployment

### Blue/Green Deployment

Switch between deployments:
```bash
./scripts/switch-deployment.sh blue  # Switch to blue deployment
./scripts/switch-deployment.sh green # Switch to green deployment
```

Test deployments:
```bash
./scripts/test-deployment.sh
```

### Monitoring

#### Metrics
Access application metrics at `/metrics` endpoint in Prometheus format:
- HTTP request duration
- Request counts by endpoint
- Error rates
- Node.js runtime metrics

#### Tracing
Distributed tracing with Jaeger:
- Request tracing across services
- Performance bottleneck identification
- Error tracking

#### Logging
Log aggregation with Loki:
- Centralized logging
- Structured log format
- Real-time log tailing

### Testing

Run the test suite:
```bash
npm test
```

Generate test traffic:
```bash
./test-traffic.sh
```

## Configuration

### Environment Variables
```
NODE_ENV=production
DEPLOYMENT_COLOR=[blue|green]
```

### Prometheus Configuration
Target metrics endpoints:
- Blue deployment (app-blue:3000)
- Green deployment (app-green:3000)
- Prometheus itself

### Nginx Configuration
Load balancer settings:
- Health check endpoints
- Proxy configuration
- Zero-downtime switching

## Testing the Setup

### Generate test traffic:

```
# Simple traffic generator
while true; do
  curl localhost:3002/
  curl localhost:3003/
  sleep 1
done
```

View results in:

* Grafana dashboards (metrics)
* Jaeger UI (traces)
* Loki (logs)

## Architectural Decisions

### 1. Blue/Green Deployment Strategy
**Decision**: Implemented blue/green deployment using Docker Compose and Nginx as a load balancer.
**Rationale**:
- Zero-downtime deployments
- Easy rollback capability
- Simple health check verification
- No need for complex orchestration tools for this scale

**Trade-offs**:
- Requires double the resources as both versions run simultaneously
- More complex initial setup compared to simple deployments
- Higher memory usage due to running multiple instances

### 2. Monitoring Stack
**Decision**: Used Prometheus, Grafana, Jaeger, and Loki for comprehensive monitoring.
**Rationale**:
- Prometheus: Industry standard for metrics collection
- Grafana: Rich visualization capabilities
- Jaeger: Distributed tracing for performance analysis
- Loki: Log aggregation that integrates well with Grafana

**Trade-offs**:
- Higher resource usage with multiple monitoring tools
- More complex configuration needed
- Learning curve for team members

### 3. Container Strategy
**Decision**: Used multi-stage Docker builds and alpine-based images.
**Rationale**:
- Smaller final image size
- Better security with minimal dependencies
- Faster deployment times

**Trade-offs**:
- More complex Dockerfile
- Potential debugging challenges in minimal images
- Need to explicitly add debugging tools when needed


## Assumptions Made

1. Scale Requirements:
- Assumed moderate traffic load
- Single region deployment
- No specific high availability requirements

2. Security Requirements:
- Basic authentication for Grafana
- No specific security compliance needs
- Internal network for monitoring tools

3. Operational Requirements:
- Team familiarity with Docker
- No specific backup requirements
- Manual intervention acceptable for rollbacks
