# Wiki Service - Kubernetes Deployment with Helm & Docker-in-Docker

A production-ready FastAPI microservice for managing users and posts, deployed on Kubernetes with comprehensive monitoring using Prometheus and Grafana. This project demonstrates modern DevOps practices including containerization, Kubernetes orchestration, Helm packaging, and Docker-in-Docker deployment.

## 📋 Problem Statement

The goal of this project is to productionize a simple Wikipedia-like API service through two progressive stages:

### Part 1: Kubernetes Deployment with Helm Chart
Package and deploy a FastAPI service with a complete observability stack on Kubernetes, including:
- **FastAPI Application**: RESTful API for user and post management
- **PostgreSQL Database**: Persistent data storage
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Metrics visualization with pre-configured dashboards

The entire stack must be packaged as a Helm chart for easy deployment and configuration management.

### Part 2: Containerized Cluster with Docker-in-Docker
Extend Part 1 by containerizing the entire Kubernetes cluster using Docker-in-Docker (DinD) and k3d, allowing the complete stack to run inside a single Docker container with all services accessible through port 8080.

## 🏗️ Architecture

### System Components

```
┌─────────────────────────────────────────────────────┐
│                   Ingress Controller                 │
│         Routes: /users, /posts, /grafana            │
└─────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   FastAPI    │  │   Grafana    │  │  Prometheus  │
│   Service    │  │   Service    │  │   Service    │
│   Port 8000  │  │   Port 3000  │  │   Port 9090  │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       │                 │          /metrics scraping
       │                 │                 │
       ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  PostgreSQL  │  │   Grafana    │  │  Prometheus  │
│   Database   │  │  Dashboard   │  │     TSDB     │
│   Port 5432  │  │    Storage   │  │   Storage    │
└──────────────┘  └──────────────┘  └──────────────┘
```

### Technology Stack

- **Application**: FastAPI (Python 3.13)
- **Database**: PostgreSQL 16 with async support (asyncpg)
- **ORM**: SQLAlchemy 2.0 (async)
- **Metrics**: Prometheus Client
- **Container Runtime**: Docker
- **Orchestration**: Kubernetes (k3d for Part 2)
- **Package Manager**: Helm 3
- **Monitoring**: Prometheus + Grafana
- **CI/CD Ready**: Containerized deployment

## 🚀 Features

### API Capabilities
- ✅ Create and retrieve users
- ✅ Create and retrieve posts with user validation
- ✅ RESTful API design with proper HTTP status codes
- ✅ Async database operations for high performance
- ✅ Input validation with Pydantic schemas
- ✅ Automatic API documentation (Swagger/ReDoc)

### DevOps Features
- ✅ Containerized application with multi-stage builds
- ✅ Helm chart for Kubernetes deployment
- ✅ PostgreSQL for production-grade data persistence
- ✅ Prometheus metrics exposure
- ✅ Pre-configured Grafana dashboards
- ✅ Resource-constrained deployment (2 CPU, 4GB RAM, 5GB disk)
- ✅ Ingress configuration for external access
- ✅ Docker-in-Docker deployment option

### Monitoring & Observability
- ✅ Custom Prometheus metrics tracking user and post creation rates
- ✅ Grafana dashboard visualizing creation rates over time
- ✅ Health checks (liveness and readiness probes)
- ✅ Structured logging

## 📁 Project Structure

```
.
├── app/                           # FastAPI application
│   ├── __init__.py
│   ├── main.py                   # FastAPI app and endpoints
│   ├── models.py                 # SQLAlchemy models
│   ├── schemas.py                # Pydantic schemas
│   ├── database.py               # Database configuration
│   └── metrics.py                # Prometheus metrics
│
├── wiki-service/                 # Docker packaging
│   ├── Dockerfile                # FastAPI service container
│   ├── pyproject.toml            # Python dependencies
│   └── app/                      # Application code
│
├── wiki-chart/                   # Helm chart
│   ├── Chart.yaml                # Chart metadata
│   ├── values.yaml               # Configuration values
│   └── templates/                # Kubernetes manifests
│       ├── fastapi-deployment.yaml
│       ├── fastapi-service.yaml
│       ├── postgresql-*.yaml     # PostgreSQL resources
│       ├── prometheus-*.yaml     # Prometheus resources
│       ├── grafana-*.yaml        # Grafana resources
│       └── ingress.yaml          # Ingress configuration
│
├── Dockerfile                    # Part 2: DinD container
├── start-cluster.sh              # Part 2: Cluster automation
├── test_api.sh                   # API testing script
└── README.md                     # This file
```

## 🔧 Installation & Deployment

### Prerequisites

**For Part 1:**
- Docker Desktop or Docker Engine
- Kubernetes cluster (minikube, k3d, or Docker Desktop Kubernetes)
- Helm 3.x
- kubectl

**For Part 2:**
- Docker with privileged container support
- 4 CPU cores and 8GB RAM recommended

### Part 1: Helm Chart Deployment

```bash
# 1. Build the FastAPI Docker image
cd wiki-service
docker build -t wiki-service:latest .

# 2. Load image into your Kubernetes cluster
# For minikube:
minikube image load wiki-service:latest

# For k3d:
k3d image import wiki-service:latest -c your-cluster-name

# 3. Install the Helm chart
cd ..
helm install wiki-release ./wiki-chart

# 4. Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all --timeout=300s

# 5. Access the services
kubectl port-forward svc/wiki-release-fastapi 8000:8000
kubectl port-forward svc/wiki-release-grafana 3000:3000
```

### Part 2: Docker-in-Docker Deployment

```bash
# 1. Build the complete cluster container
docker build -t wiki-cluster:latest .

# 2. Run the cluster (single command!)
docker run --privileged -p 8080:8080 --name wiki-cluster wiki-cluster:latest

# 3. Wait 3-5 minutes for cluster initialization
# Watch logs: docker logs -f wiki-cluster

# 4. Access all services on port 8080
# - API: http://localhost:8080/users
# - Grafana: http://localhost:8080/grafana/
```

## 📚 API Documentation

### Endpoints

#### Create User
```bash
POST /users
Content-Type: application/json

{
  "name": "John Doe"
}

Response: 201 Created
{
  "id": 1,
  "name": "John Doe",
  "created_time": "2024-12-14T10:30:00.123456"
}
```

#### Get User
```bash
GET /user/{id}

Response: 200 OK
{
  "id": 1,
  "name": "John Doe",
  "created_time": "2024-12-14T10:30:00.123456"
}
```

#### Create Post
```bash
POST /posts
Content-Type: application/json

{
  "user_id": 1,
  "content": "This is my first post!"
}

Response: 201 Created
{
  "post_id": 1,
  "content": "This is my first post!",
  "user_id": 1,
  "created_time": "2024-12-14T10:35:00.123456"
}
```

#### Get Post
```bash
GET /posts/{id}

Response: 200 OK
{
  "post_id": 1,
  "content": "This is my first post!",
  "user_id": 1,
  "created_time": "2024-12-14T10:35:00.123456"
}
```

#### Prometheus Metrics
```bash
GET /metrics

Response: 200 OK (Prometheus format)
# HELP users_created_total Total number of users created
# TYPE users_created_total counter
users_created_total 10.0
# HELP posts_created_total Total number of posts created
# TYPE posts_created_total counter
posts_created_total 25.0
```

### Interactive Documentation
- **Swagger UI**: `http://localhost:8000/docs` (Part 1) or `http://localhost:8080/docs` (Part 2)
- **ReDoc**: `http://localhost:8000/redoc` (Part 1) or `http://localhost:8080/redoc` (Part 2)

## 📊 Monitoring

### Grafana Dashboard

Access the pre-configured dashboard showing user and post creation rates:
- **Part 1**: `http://localhost:3000/d/creation-dashboard-678/creation`
- **Part 2**: `http://localhost:8080/grafana/d/creation-dashboard-678/creation`

**Credentials**: Username `admin`, Password `admin`

### Prometheus Metrics

The application exposes two custom metrics:
- `users_created_total`: Counter tracking total users created
- `posts_created_total`: Counter tracking total posts created

Prometheus scrapes the `/metrics` endpoint every 15 seconds.

## 🧪 Testing

### Manual Testing

```bash
# Run the provided test script
chmod +x test_api.sh
./test_api.sh
```

### Quick API Test

```bash
# Part 1 (port-forward to 8000)
BASE_URL="http://localhost:8000"

# Part 2 (single container)
BASE_URL="http://localhost:8080"

# Create a user
curl -X POST "$BASE_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice"}'

# Create a post
curl -X POST "$BASE_URL/posts" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "content": "Hello World!"}'

# Get metrics
curl "$BASE_URL/metrics" | grep -E "(users|posts)_created_total"
```

## 🎯 Design Decisions

### 1. Database Choice: PostgreSQL
- **Why**: Production-grade relational database with excellent Python support
- **Benefits**: ACID compliance, robust connection pooling, scalability
- **Implementation**: Async driver (asyncpg) for optimal performance

### 2. Helm Chart Structure
- **Separation of Concerns**: Each component (FastAPI, PostgreSQL, Prometheus, Grafana) has dedicated deployment, service, and configuration
- **ConfigMaps**: Used for Prometheus scrape config and Grafana datasource/dashboard provisioning
- **PersistentVolumeClaims**: Ensure data persistence across pod restarts
- **Resource Limits**: Explicit CPU and memory constraints to prevent resource exhaustion

### 3. Monitoring Strategy
- **Prometheus Counters**: Simple, reliable metric type for tracking creation events
- **Grafana Dashboard**: Pre-provisioned using ConfigMaps for zero-configuration deployment
- **Rate Visualization**: Dashboard shows creation rate (per second) rather than absolute counts for better insights

### 4. Docker-in-Docker Approach
- **Isolation**: Complete environment isolation with no host dependencies
- **Portability**: Single container can be deployed anywhere Docker runs
- **k3d**: Lightweight Kubernetes distribution perfect for containerized clusters
- **Automation**: Startup script handles all initialization steps

### 5. Ingress Configuration
- **Path-based Routing**: Different paths route to different services (`/users` → FastAPI, `/grafana` → Grafana)
- **Single Entry Point**: Part 2 exposes everything on port 8080 for simplicity
- **Subpath Support**: Grafana configured to serve from `/grafana/` subpath

## 🔐 Configuration

### Customizing the Deployment

Edit `wiki-chart/values.yaml` to customize:

```yaml
fastapi:
  image_name: wiki-service        # Change Docker image name
  image_tag: latest               # Change image tag
  replicas: 1                     # Scale application
  resources:
    limits:
      cpu: "500m"                 # Adjust CPU limits
      memory: "1Gi"               # Adjust memory limits

postgresql:
  auth:
    username: wikiuser            # Change database user
    password: wikipass            # Change database password
    database: wikidb              # Change database name
  primary:
    persistence:
      size: 2Gi                   # Adjust storage size

grafana:
  adminUser: admin                # Change Grafana admin user
  adminPassword: admin            # Change Grafana password
```

### Environment Variables

The FastAPI application reads configuration from environment variables:
- `DATABASE_URL`: PostgreSQL connection string (set automatically by Helm)

## 🐛 Troubleshooting

### Part 1 Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Database connection errors:**
```bash
# Check PostgreSQL pod
kubectl logs -l app=postgresql

# Verify DATABASE_URL
kubectl exec <fastapi-pod> -- env | grep DATABASE_URL
```

**Port-forward not working:**
```bash
# Kill any existing port-forwards
killall kubectl

# Try different port
kubectl port-forward svc/wiki-release-fastapi 8080:8000
```

### Part 2 Issues

**Container exits immediately:**
```bash
# Check logs
docker logs wiki-cluster

# Common cause: Missing --privileged flag
docker run --privileged -p 8080:8080 --name wiki-cluster wiki-cluster:latest
```

**Services not accessible:**
```bash
# Check if cluster is ready
docker exec -it wiki-cluster kubectl get pods

# Check if all pods are running
docker exec -it wiki-cluster kubectl get pods -o wide

# View startup logs
docker logs -f wiki-cluster
```

## 📈 Performance & Resource Usage

### Resource Allocation

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| FastAPI   | 250m        | 500m      | 512Mi          | 1Gi          |
| PostgreSQL| 250m        | 500m      | 256Mi          | 512Mi        |
| Prometheus| 250m        | 500m      | 512Mi          | 1Gi          |
| Grafana   | 100m        | 250m      | 256Mi          | 512Mi        |
| **Total** | **850m**    | **1.75**  | **1.5Gi**      | **3Gi**      |

### Startup Times

- **Part 1**: 2-3 minutes (Helm install + pod initialization)
- **Part 2**: 3-5 minutes (includes Docker daemon start + k3d cluster creation)

## 🔄 CI/CD Integration

This project is CI/CD ready and can be integrated with:
- **GitHub Actions**: Automated testing and deployment
- **GitLab CI**: Pipeline configuration included
- **Jenkins**: Jenkinsfile support
- **ArgoCD**: GitOps-based Kubernetes deployment

## 📝 Future Enhancements

- [ ] Add authentication and authorization (JWT)
- [ ] Implement caching layer (Redis)
- [ ] Add rate limiting
- [ ] Implement full-text search for posts
- [ ] Add user profile pictures and post media attachments
- [ ] Implement post comments and reactions
- [ ] Add GraphQL API alongside REST
- [ ] Implement horizontal pod autoscaling
- [ ] Add distributed tracing (Jaeger/Zipkin)
- [ ] Implement backup and disaster recovery

## 📄 License

This project is created for educational purposes as part of a DevOps assignment.

## 🤝 Contributing

This is an assignment project, but feedback and suggestions are welcome!

## 👨‍💻 Author

**Prajwal Patil**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/prajwalpatil509/)

Created as part of a Kubernetes and DevOps learning assignment.

## 🙏 Acknowledgments

- FastAPI for the excellent web framework
- Kubernetes community for comprehensive documentation
- Helm for simplifying Kubernetes deployments
- Prometheus and Grafana for monitoring capabilities
- k3d for lightweight Kubernetes clusters

---

**Note**: This project demonstrates production-ready DevOps practices including containerization, orchestration, monitoring, and infrastructure-as-code principles.
