/
├── wiki-service/
│   ├── Dockerfile
│   ├── pyproject.toml
│   ├── main.py
│   └── app/
│       ├── __init__.py
│       ├── database.py (updated)
│       ├── models.py
│       ├── schemas.py
│       ├── metrics.py
│       └── main.py
└── wiki-chart/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── fastapi-deployment.yaml
        ├── fastapi-service.yaml
        ├── postgresql-deployment.yaml
        ├── postgresql-service.yaml
        ├── postgresql-pvc.yaml
        ├── prometheus-config.yaml
        ├── prometheus-deployment.yaml
        ├── prometheus-service.yaml
        ├── prometheus-pvc.yaml
        ├── grafana-config.yaml
        ├── grafana-deployment.yaml
        ├── grafana-service.yaml
        ├── grafana-pvc.yaml
        └── ingress.yaml