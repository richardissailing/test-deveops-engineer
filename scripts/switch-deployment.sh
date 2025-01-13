#!/bin/bash

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

# Create temporary nginx configuration
cat > nginx.conf.temp << EOF
events {
    worker_connections 1024;
}

http {
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

# Copy the new configuration into the container
docker cp nginx.conf.temp devtakehome_nginx_1:/etc/nginx/nginx.conf

# Remove temporary file
rm nginx.conf.temp

# Reload nginx
docker-compose -f docker-compose.blue-green.yml exec nginx nginx -s reload

echo "Switched to $COLOR deployment"

# Verify the switch
echo "Verifying $COLOR deployment health..."
sleep 2
curl -s http://localhost/health

# Run full test suite
echo -e "\nRunning test suite..."
./scripts/test-deployment.sh
