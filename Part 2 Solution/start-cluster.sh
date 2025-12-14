#!/bin/bash
set -e

echo "========================================="
echo "Starting Wiki Service Cluster with k3d"
echo "========================================="

# Start Docker daemon in background
echo "Starting Docker daemon..."
dockerd > /var/log/docker.log 2>&1 &

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
timeout=60
counter=0
until docker info > /dev/null 2>&1; do
    sleep 1
    counter=$((counter + 1))
    if [ $counter -ge $timeout ]; then
        echo "ERROR: Docker failed to start within ${timeout} seconds"
        cat /var/log/docker.log
        exit 1
    fi
done
echo "Docker is ready!"

# Create k3d cluster with port mapping
echo "Creating k3d cluster..."
k3d cluster create wiki-cluster \
    --port "8080:80@loadbalancer" \
    --agents 1 \
    --wait

# Wait for k3d to be fully ready
echo "Waiting for k3d cluster to be ready..."
kubectl wait --for=condition=ready node --all --timeout=120s

# Build wiki-service image
echo "Building wiki-service Docker image..."
cd /workspace/wiki-service
docker build -t wiki-service:latest .

# Import image into k3d
echo "Importing wiki-service image into k3d..."
k3d image import wiki-service:latest -c wiki-cluster

# Install Helm chart
echo "Installing Helm chart..."
cd /workspace
helm install wiki-release ./wiki-chart --wait --timeout=5m

# Wait for all pods to be ready
echo "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all --timeout=300s

# Get pod status
echo ""
echo "========================================="
echo "Cluster Status"
echo "========================================="
kubectl get pods
echo ""
kubectl get services
echo ""
kubectl get ingress
echo ""

# Print access information
echo "========================================="
echo "Cluster is Ready!"
echo "========================================="
echo ""
echo "Access the services at:"
echo "  - FastAPI:  http://localhost:8080/users"
echo "  - Grafana:  http://localhost:8080/grafana/"
echo "  - Metrics:  http://localhost:8080/metrics"
echo ""
echo "Grafana credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "========================================="

# Keep container running and show logs
echo "Tailing logs... (Ctrl+C to stop)"
echo ""
kubectl logs -f -l app=fastapi --tail=50