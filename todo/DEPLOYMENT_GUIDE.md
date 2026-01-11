# Step-by-Step Deployment Guide for Agent-Matrix Infrastructure

## Prerequisites Check

Before starting, ensure you have reviewed **REQUIREMENTS.md** and verified your environment meets all requirements.

## Deployment Options

You have three main deployment paths:

1. **Local Development (MiniKube)** - Best for development and testing
2. **Cloud VM (Docker Compose)** - Best for small production or staging
3. **Kubernetes Production** - Best for large-scale production (see docs/deployment.md)

---

## Option 1: Local Development with MiniKube

This is the recommended approach for development and testing the full Agent-Matrix ecosystem.

### Step 1: Install Dependencies

```bash
# Install Docker (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install MiniKube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Log out and back in for docker group to take effect
# Or run: newgrp docker
```

### Step 2: Clone Repository

```bash
git clone https://github.com/agent-matrix/matrix-infra.git
cd matrix-infra
```

### Step 3: Start MiniKube

```bash
# Start with adequate resources
minikube start --cpus=4 --memory=8192

# Verify MiniKube is running
minikube status
```

### Step 4: Deploy Using Make

```bash
# Use the automated installer
make install-minikube

# This will:
# - Create the 'matrix' namespace
# - Set current context to 'matrix' namespace
# - Deploy all manifests from platforms/minikube
```

**OR** deploy manually:

```bash
# Create namespace
kubectl create namespace matrix

# Set namespace context
kubectl config set-context --current --namespace=matrix

# Apply Kustomization
kubectl apply -k platforms/minikube
```

### Step 5: Monitor Deployment

```bash
# Watch pods come up
kubectl get pods -w

# Check all pods are running (may take 2-5 minutes)
kubectl get pods

# Check services
kubectl get services
```

### Step 6: Access Services

```bash
# Get service URLs
minikube service list -n matrix

# Or get MiniKube IP and use NodePort
MINIKUBE_IP=$(minikube ip)
echo "Matrix Hub: http://$MINIKUBE_IP:30081"
echo "Matrix AI: http://$MINIKUBE_IP:30083"
echo "Matrix Guardian: http://$MINIKUBE_IP:30082"
echo "Hub Admin UI: http://$MINIKUBE_IP:30089"
```

### Step 7: Configure CLI/SDK (Optional)

```bash
export MATRIX_HUB_URL="http://$(minikube ip):30081"
export MATRIX_AI_URL="http://$(minikube ip):30083"
export MATRIX_GUARDIAN_URL="http://$(minikube ip):30082"
export ADMIN_TOKEN="changeme"  # Change this!
```

### Step 8: Enable Ollama (Optional Local LLM)

```bash
# Edit platforms/minikube/kustomization.yaml
# Uncomment the line: # - ollama.yaml

# Reapply
kubectl apply -k platforms/minikube

# Wait for Ollama pod
kubectl get pods | grep ollama

# Pull a model
kubectl exec -it deployment/ollama -- ollama pull llama3
```

---

## Option 2: Cloud VM with Docker Compose

Best for simple production deployments or staging environments.

### Step 1: Provision Cloud VM

**Oracle Cloud (Free Tier):**
- Instance: VM.Standard.E2.1.Micro (1 CPU, 1GB RAM) - minimum
- Recommended: VM.Standard.E2.2 (2 CPU, 16GB RAM)
- OS: Ubuntu 24.04
- Enable ports: 7860, 8001, 11434 in Security Lists

**AWS, GCP, Azure:**
- Instance: t3.medium or equivalent (2 vCPU, 4GB RAM)
- OS: Ubuntu 24.04
- Security group: Allow ports 7860, 8001, 11434

### Step 2: Install Docker

```bash
# SSH into your VM
ssh ubuntu@YOUR_VM_IP

# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Log out and back in
exit
ssh ubuntu@YOUR_VM_IP
```

### Step 3: Clone Repository

```bash
git clone https://github.com/agent-matrix/matrix-infra.git
cd matrix-infra
```

### Step 4: Configure Environment

```bash
cd platforms/oracle/compose

# Copy environment template
cp .env.example .env

# Edit with your API keys
nano .env
```

**Required configurations in `.env`:**
```bash
# Admin token (change this!)
ADMIN_TOKEN=your-secure-admin-token-here

# LLM Provider (choose one or multiple)
PROVIDER_ORDER=ollama  # or groq,gemini,huggingface

# If using Ollama (local)
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=llama3

# If using Groq
GROQ_API_KEY=your-groq-api-key
GROQ_MODEL=mixtral-8x7b-32768

# If using Gemini
GOOGLE_API_KEY=your-google-api-key
GEMINI_MODEL=gemini-pro

# Matrix Hub endpoint (if using remote)
MATRIXHUB_API_BASE=https://hub.agent-matrix.com/api
# Or use local: http://localhost:8080

# Other settings
MATRIX_AI_BASE=http://matrix-ai:7860
AUTOPILOT_ENABLED=false
AUTOPILOT_INTERVAL_SEC=300
```

### Step 5: Deploy with Docker Compose

```bash
# Pull images
docker compose pull

# Start services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### Step 6: Verify Services

```bash
# Check running containers
docker compose ps

# Should see:
# - matrix-ai
# - matrix-guardian
# - ollama (if using local LLM)

# Test Matrix AI endpoint
curl http://localhost:7860/health

# Test Matrix Guardian endpoint
curl http://localhost:8001/health
```

### Step 7: Access Services

From your local machine:
```bash
# Matrix AI
http://YOUR_VM_IP:7860

# Matrix Guardian
http://YOUR_VM_IP:8001
```

---

## Option 3: Production Kubernetes Deployment

For production-grade deployments on managed Kubernetes (GKE, EKS, AKS):

### Prerequisites
- Managed Kubernetes cluster (GKE, EKS, AKS, etc.)
- kubectl configured for your cluster
- Helm 3+ installed (optional but recommended)

### Steps

```bash
# Clone repository
git clone https://github.com/agent-matrix/matrix-infra.git
cd matrix-infra

# Create production namespace
kubectl create namespace matrix-prod

# Set context
kubectl config set-context --current --namespace=matrix-prod

# Create secrets (DO NOT use default values)
kubectl create secret generic matrix-secrets \
  --from-literal=ADMIN_TOKEN=$(openssl rand -hex 32) \
  --from-literal=JWT_SECRET=$(openssl rand -hex 32) \
  --from-literal=GROQ_API_KEY=your-groq-key \
  --from-literal=GOOGLE_API_KEY=your-google-key

# Apply base manifests
kubectl apply -k platforms/minikube  # Use as base, customize as needed

# For production, you should:
# 1. Pin specific image tags (not :latest)
# 2. Set resource limits/requests
# 3. Configure ingress/load balancer
# 4. Set up persistent volumes for databases
# 5. Configure horizontal pod autoscaling
# 6. Set up monitoring (Prometheus/Grafana)
```

See **docs/deployment.md** for production-specific guidance.

---

## Post-Deployment Verification

### Health Checks

```bash
# MiniKube deployment
kubectl get pods -n matrix
kubectl logs -n matrix deployment/matrix-hub
kubectl logs -n matrix deployment/matrix-ai
kubectl logs -n matrix deployment/matrix-guardian

# Docker Compose deployment
docker compose logs matrix-ai
docker compose logs matrix-guardian
docker compose exec matrix-ai curl http://localhost:7860/health
```

### Test the Alive System Loop

1. Register a test agent (requires matrix-cli)
2. Query Matrix Hub for registered agents
3. Submit a task to Matrix AI
4. Verify Guardian approval workflow
5. Check execution in Matrix Architect

See the main Agent-Matrix documentation for end-to-end testing guides.

---

## Stopping and Cleanup

### MiniKube

```bash
# Delete deployments
kubectl delete -k platforms/minikube

# Or delete entire namespace
kubectl delete namespace matrix

# Stop MiniKube
minikube stop

# Delete cluster (careful!)
minikube delete
```

### Docker Compose

```bash
cd platforms/oracle/compose

# Stop services
docker compose down

# Stop and remove volumes (careful!)
docker compose down -v
```

---

## Troubleshooting

See **TROUBLESHOOTING.md** for common issues and solutions.

## Next Steps

After successful deployment:

1. **Configure LLM providers** - See docs/llm-providers.md
2. **Install Matrix CLI** - For interacting with the system
3. **Register agents** - Using Matrix Hub API or CLI
4. **Test governance** - Create policies in Matrix Guardian
5. **Monitor health** - Check service logs and metrics
6. **Read architecture docs** - Understand the alive system loop

## Support and Documentation

- **Full documentation**: See `docs/` directory
- **Architecture overview**: `docs/architecture.md`
- **LLM configuration**: `docs/llm-providers.md`
- **Production deployment**: `docs/deployment.md`
- **GitHub Issues**: https://github.com/agent-matrix/matrix-infra/issues
- **Organization**: https://github.com/agent-matrix
