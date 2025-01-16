#!/bin/bash
set -e  # Exit on any error

# Check if color parameter is provided
if [ -z "$1" ]; then
    echo "Usage: ./switch-deployment.sh [blue|green]"
    exit 1
fi

COLOR=$1
if [ "$COLOR" != "blue" ] && [ "$COLOR" != "green" ]; then
    echo "Color must be either 'blue' or 'green'"
    exit 1
fi

# Ensure nginx directories exist
mkdir -p ./nginx

# Create new configuration
cat > ./nginx/nginx.conf.new << EOF
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    upstream app_servers {
        server app-$COLOR:3000;
    }

    server {
        listen 80;
        
        location / {
            proxy_pass http://app_servers;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /health {
            proxy_pass http://app_servers;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }

        location /metrics {
            proxy_pass http://app_servers;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF

# Move new config into place
echo "Updating nginx configuration..."
mv ./nginx/nginx.conf.new ./nginx/nginx.conf

# Reload nginx
echo "Reloading nginx..."
if ! docker-compose -f docker-compose.blue-green.yml exec -T nginx nginx -s reload; then
    echo "Failed to reload nginx"
    exit 1
fi

echo "Switched to $COLOR deployment"

# Verify the switch with retries
echo "Verifying $COLOR deployment health..."
max_retries=5
retry_count=0
while [ $retry_count -lt $max_retries ]; do
    if health_response=$(curl -s http://localhost/health); then
        if [[ $health_response == *"\"status\":\"ok\""* ]]; then
            echo "Health check passed"
            break
        fi
    fi
    echo "Attempt $((retry_count + 1)): Health check failed, retrying..."
    retry_count=$((retry_count + 1))
    sleep 2
done

if [ $retry_count -eq $max_retries ]; then
    echo "Failed to verify deployment health after $max_retries attempts"
    exit 1
fi

# Run full test suite
echo -e "\nRunning test suite..."
./scripts/test-deployment.sh