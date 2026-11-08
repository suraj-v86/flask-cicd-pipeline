# Flask CI/CD Pipeline

![CI](https://github.com/suraj-v86/flask-cicd-pipeline/actions/workflows/ci.yml/badge.svg)

A small Flask app taken through a complete DevOps workflow as a personal hands-on project: containerised with Docker, built and tested by GitHub Actions, published to a private Amazon ECR repository created with Terraform, and deployed to a local Kubernetes cluster (minikube).

## Architecture

```
Developer ──push──> GitHub ──> GitHub Actions
                                  │  1. build Docker image (tag = commit SHA)
                                  │  2. run container + smoke test /health
                                  │  3. push image to ECR (main branch only)
                                  ▼
                        Amazon ECR (private repo, created by Terraform)
                                  │
                                  ▼
                  Kubernetes (minikube): Deployment + NodePort Service
```

## Tech stack

| Area | Tools |
|---|---|
| App | Python 3.12, Flask, gunicorn |
| Containers | Docker |
| CI | GitHub Actions |
| Infrastructure as code | Terraform (AWS provider 6.x) |
| Cloud | AWS (ECR, IAM) |
| Orchestration | Kubernetes (minikube), kubectl |
| Source control | Git, GitHub (branches, pull requests) |

## Repository structure

```
.
├── app.py                      # Flask app: / and /health
├── requirements.txt            # pinned dependencies
├── Dockerfile
├── .dockerignore
├── .github/workflows/ci.yml    # CI pipeline
├── terraform/                  # ECR repository (IaC)
└── kubernetes/
    ├── deployment.yaml
    └── service.yaml
```

## What each part does

### Application
- `GET /` returns a greeting.
- `GET /health` returns `{"status": "ok"}` as JSON. CI and Kubernetes both use it for health checks.

### Docker
- Based on `python:3.12-slim`.
- Dependencies are installed before the code is copied, so Docker can cache the install layer.
- Served by **gunicorn** instead of Flask's development server.
- Runs as a **non-root user** (`appuser`).
- A `.dockerignore` keeps `.venv`, `.git` and similar files out of the build context.

### CI pipeline (GitHub Actions)
Runs on pushes and pull requests to `main`.
1. Builds the image, tagged with the commit SHA.
2. Starts the container and calls `/health` with `curl --fail`, so a broken image fails the build.
3. Always removes the test container, even when a step fails.
4. On pushes to `main` only: logs in to Amazon ECR and pushes the image. Pull requests build and test but never push.

AWS credentials are stored as GitHub Actions secrets, and the region is a repository variable.

### Infrastructure (Terraform)
Creates the private ECR repository `flask-cicd-repo` in `us-east-1`:
- image scanning on push
- AES256 encryption
- tag immutability, with `latest*` and `dev-*` tags allowed to be overwritten
- resource tags (`Environment`, `ManagedBy`)

The provider version is pinned and `.terraform.lock.hcl` is committed. State files and `.terraform/` are git-ignored.

### Kubernetes
- **Deployment:** 2 replicas, image pulled from ECR by commit-SHA tag (no `latest`), readiness and liveness probes on `/health`, CPU and memory requests and limits.
- **Service:** NodePort on port 30080.

## Run it yourself

### 1. Run the app locally
```bash
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r requirements.txt
python app.py
curl http://localhost:5000/health
```

### 2. Run it in Docker
```bash
docker build -t flask-cicd:local .
docker run -d --name flask-cicd-container -p 5000:5000 flask-cicd:local
curl http://localhost:5000/health
```

### 3. Create the ECR repository
```bash
cd terraform
terraform init
terraform plan
terraform apply
```
Requires AWS credentials configured locally (`aws configure`).

### 4. Deploy to minikube
Edit the image tag in `kubernetes/deployment.yaml` to a SHA that exists in ECR, then:
```bash
minikube start --driver=docker

kubectl create secret docker-registry ecr-registry \
  --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1)

kubectl apply -f kubernetes/
kubectl rollout status deployment/flask-deployment
minikube service flask-service --url
```

## Known limitations and next steps
- Deployment to the cluster is manual. Minikube runs on a laptop that GitHub-hosted runners cannot reach.
- The ECR login token in the Kubernetes pull secret expires after 12 hours and is recreated by hand.
- CI uses long-lived IAM access keys. Switching to GitHub OIDC with short-lived credentials is planned.
- Planned: monitoring with Prometheus and Grafana, and a cloud cluster (EKS) built with Terraform.