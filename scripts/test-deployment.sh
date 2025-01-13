#!/bin/bash

echo "Starting deployment test..."

# Function to check health with timeout
check_health() {
    local url=$1
    local max_attempts=30
    local attempt=1
    
    echo "Testing endpoint: $url"
    while [ $attempt -le $max_attempts ]; do
        response=$(curl -s "$url")
        if echo "$response" | grep -q "ok"; then
            echo "✓ Health check passed"
            return 0
        fi
        echo "Attempt $attempt: Health check failed, retrying..."
        sleep 1
        attempt=$((attempt + 1))
    done
    echo "✗ Health check failed after $max_attempts attempts"
    return 1
}

# Function to test metrics endpoint
check_metrics() {
    local url=$1
    echo "Testing metrics at: $url"
    response=$(curl -s "$url")
    if [ -n "$response" ]; then
        echo "✓ Metrics endpoint responding"
        return 0
    else
        echo "✗ Metrics endpoint not responding"
        return 1
    fi
}

# Test blue deployment
echo "Testing blue deployment..."
if check_health "http://localhost:3002/health"; then
    check_metrics "http://localhost:3002/metrics"
else
    echo "Blue deployment health check failed!"
    exit 1
fi

# Test green deployment
echo -e "\nTesting green deployment..."
if check_health "http://localhost:3003/health"; then
    check_metrics "http://localhost:3003/metrics"
else
    echo "Green deployment health check failed!"
    exit 1
fi

# Test load balancer
echo -e "\nTesting load balancer..."
if check_health "http://localhost/health"; then
    echo "Load balancer is working"
else
    echo "Load balancer health check failed!"
    exit 1
fi

# Generate some test traffic
echo -e "\nGenerating test traffic..."
for i in {1..10}; do
    curl -s "http://localhost:3002/" > /dev/null &
    curl -s "http://localhost:3003/" > /dev/null &
    sleep 0.1
done

echo -e "\nAll tests completed successfully!"
