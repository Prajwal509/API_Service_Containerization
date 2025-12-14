# Part 2: Docker-in-Docker with k3d

## Overview

Part 2 runs the entire Kubernetes cluster (from Part 1) inside a single Docker container using Docker-in-Docker (DinD) and k3d.

## Directory Structure Required

```
/
├── wiki-service/
│   ├── Dockerfile
│   ├── pyproject.toml
│   └── app/
│       ├── __init__.py
│       ├── database.py
│       ├── main.py
│       ├── metrics.py
│       ├── models.py
│       └── schemas.py
├── wiki-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       └── (14 .yaml files)
├── Dockerfile          
└── start-cluster.sh    
```

## New Files for Part 2

### 1. Dockerfile (Root Level)
This is different from `wiki-service/Dockerfile`. This one builds the container that runs the entire cluster.

### 2. start-cluster.sh
Script that:
- Starts Docker daemon inside the container
- Creates k3d cluster
- Builds and imports wiki-service image
- Installs Helm chart
- Waits for everything to be ready
- Exposes services on port 8080

## Building and Running

### Build the Image

```bash
# Make sure you're in the directory with wiki-service/, wiki-chart/, Dockerfile, and start-cluster.sh
docker build -t wiki-cluster:latest .
```

**Note:** This build takes 5-10 minutes as it:
- Installs Docker, kubectl, Helm, k3d
- Copies your application
- Sets up the environment

### Run the Container

```bash
docker run --privileged -p 8080:8080 --name wiki-cluster wiki-cluster:latest
```

**Important flags:**
- `--privileged`: Required for Docker-in-Docker (runs Docker inside the container)
- `-p 8080:8080`: Maps port 8080 from container to host
- `--name wiki-cluster`: Names the container for easy reference

### What Happens When You Run

1. **Docker daemon starts** inside the container
2. **k3d cluster is created** (lightweight Kubernetes)
3. **wiki-service image is built** from your code
4. **Image is imported** into k3d
5. **Helm chart is installed** (deploys all services)
6. **Pods start** (FastAPI, PostgreSQL, Prometheus, Grafana)
7. **Services are exposed** on port 8080

This takes about 3-5 minutes total.

## Accessing the Services

Once you see "Cluster is Ready!" in the logs:

### Test FastAPI

```bash
# Create a user
curl -X POST "http://localhost:8080/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice"}'

# Get user
curl http://localhost:8080/user/1

# Create a post
curl -X POST "http://localhost:8080/posts" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "content": "Hello from Docker-in-Docker!"}'

# Get post
curl http://localhost:8080/posts/1

# Check metrics
curl http://localhost:8080/metrics | grep -E "(users_created|posts_created)"
```

### Access Grafana Dashboard

1. Open browser: `http://localhost:8080/grafana/`
2. Login: `admin` / `admin`
3. Navigate to dashboard: `/d/creation-dashboard-678/creation`

## Monitoring the Cluster

### View Logs

```bash
# The container shows FastAPI logs by default
# To see other logs, exec into the container:
docker exec -it wiki-cluster bash

# Then inside the container:
kubectl logs -l app=postgresql
kubectl logs -l app=prometheus
kubectl logs -l app=grafana
```

### Check Pod Status

```bash
docker exec -it wiki-cluster kubectl get pods
```

### Check Services

```bash
docker exec -it wiki-cluster kubectl get services
```

### View Ingress

```bash
docker exec -it wiki-cluster kubectl get ingress
```

## Stopping and Cleaning Up

### Stop the Container

```bash
docker stop wiki-cluster
```

### Restart the Container

```bash
docker start wiki-cluster
```

**Note:** The cluster state is preserved while the container is stopped.

### Remove Everything

```bash
docker stop wiki-cluster
docker rm wiki-cluster
docker rmi wiki-cluster:latest
```

## Troubleshooting

### Container Exits Immediately

Check logs:
```bash
docker logs wiki-cluster
```

Common issues:
- Not using `--privileged` flag
- Port 8080 already in use

### Services Not Accessible

```bash
# Check if pods are running
docker exec -it wiki-cluster kubectl get pods

# Check if all pods are ready
docker exec -it wiki-cluster kubectl get pods -o wide

# Check pod logs
docker exec -it wiki-cluster kubectl logs <pod-name>
```

### k3d Cluster Creation Fails

```bash
# Check Docker daemon logs
docker exec -it wiki-cluster cat /var/log/docker.log

# Try recreating the cluster
docker exec -it wiki-cluster k3d cluster delete wiki-cluster
docker exec -it wiki-cluster k3d cluster create wiki-cluster --port "8080:80@loadbalancer"
```

### Image Build Fails

```bash
# Check Docker inside the container
docker exec -it wiki-cluster docker images
docker exec -it wiki-cluster docker ps -a
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Host Machine                          │
│                                                         │
│  Docker Container (--privileged)                        │
│  ┌───────────────────────────────────────────────────┐ │
│  │                                                   │ │
│  │  Docker Daemon (running inside container)        │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │                                             │ │ │
│  │  │  k3d Cluster (Kubernetes)                   │ │ │
│  │  │  ┌────────────────────────────────────────┐ │ │ │
│  │  │  │                                        │ │ │ │
│  │  │  │  Pods:                                 │ │ │ │
│  │  │  │  - FastAPI (wiki-service)              │ │ │ │
│  │  │  │  - PostgreSQL                          │ │ │ │
│  │  │  │  - Prometheus                          │ │ │ │
│  │  │  │  - Grafana                             │ │ │ │
│  │  │  │                                        │ │ │ │
│  │  │  │  Ingress → Port 80                     │ │ │ │
│  │  │  └────────────────────────────────────────┘ │ │ │
│  │  │                                             │ │ │
│  │  │  Port Mapping: 80 → 8080                    │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  │                                                   │ │
│  │  Exposed Port: 8080                               │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Host Port Mapping: 8080:8080                           │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
              http://localhost:8080
```

## Testing Checklist

- [ ] Image builds successfully
- [ ] Container starts with `--privileged` flag
- [ ] Docker daemon starts inside container
- [ ] k3d cluster is created
- [ ] wiki-service image is built and imported
- [ ] Helm chart installs successfully
- [ ] All 4 pods reach Running state
- [ ] Can access FastAPI at `http://localhost:8080/users`
- [ ] Can create users and posts
- [ ] Can access metrics at `http://localhost:8080/metrics`
- [ ] Can access Grafana at `http://localhost:8080/grafana/`
- [ ] Grafana dashboard shows metrics

## Quick Test Script

Save as `test-part2.sh`:

```bash
#!/bin/bash

echo "Building Docker image..."
docker build -t wiki-cluster:latest .

echo "Starting cluster..."
docker run -d --privileged -p 8080:8080 --name wiki-cluster wiki-cluster:latest

echo "Waiting for cluster to be ready (this takes ~3-5 minutes)..."
sleep 180

echo "Testing API..."
curl -X POST http://localhost:8080/users -H "Content-Type: application/json" -d '{"name": "Test User"}'
curl http://localhost:8080/user/1

echo "Cluster is ready! Access at:"
echo "  FastAPI: http://localhost:8080/users"
echo "  Grafana: http://localhost:8080/grafana/"

echo "View logs:"
docker logs -f wiki-cluster
```

## Pro Tips

1. **Speed up builds**: Use `docker build --no-cache` only when needed
2. **Debug**: Use `docker exec -it wiki-cluster bash` to explore
3. **Logs**: Use `docker logs wiki-cluster` to see startup process
4. **Restart**: `docker restart wiki-cluster` to restart everything
5. **Clean start**: `docker rm -f wiki-cluster` then run again
