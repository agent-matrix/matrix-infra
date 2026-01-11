# Quick Start Guide - Agent-Matrix Infrastructure

Get the Agent-Matrix infrastructure running in 15-30 minutes.

## Prerequisites

- **Local Development**: macOS, Windows (Docker Desktop), or Linux with 4+ CPU cores and 8GB+ RAM
- **Cloud Deployment**: Ubuntu 24.04 VM with Docker installed
- **Network**: Internet connection for pulling container images

## 🚀 Option 1: Local Development (MiniKube)

**Best for:** Development, testing, and exploring the full Agent-Matrix ecosystem locally.

**Time required:** 15-30 minutes (first time)

### Step 1: Clone Repository

```bash
git clone https://github.com/agent-matrix/matrix-infra.git
cd matrix-infra
```

### Step 2: Check Requirements

```bash
make preflight
```

If checks fail, install missing dependencies:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y docker.io

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**macOS:**
```bash
brew install docker kubectl minikube
```

### Step 3: Deploy

```bash
make deploy-minikube
```

This will:
- Start MiniKube cluster (if not running)
- Create `matrix` namespace
- Deploy all Agent-Matrix services
- Wait for services to initialize

### Step 4: Verify Deployment

```bash
make health-check
```

### Step 5: Access Services

```bash
# Get MiniKube IP
export MINIKUBE_IP=$(minikube ip)

# Access services
echo "Matrix Hub: http://$MINIKUBE_IP:30081"
echo "Matrix AI: http://$MINIKUBE_IP:30083"
echo "Matrix Guardian: http://$MINIKUBE_IP:30082"
echo "Hub Admin UI: http://$MINIKUBE_IP:30089"

# Or see all services
minikube service list -n matrix
```

### Step 6: Monitor Services

```bash
# Watch pod status
kubectl get pods -n matrix -w

# View logs
kubectl logs -f deployment/matrix-hub -n matrix
kubectl logs -f deployment/matrix-ai -n matrix
```

**✅ You're done!** Agent-Matrix is now running locally.

---

## ☁️ Option 2: Cloud Deployment (Docker Compose)

**Best for:** Small production, staging, or single-server deployments.

**Time required:** 10-20 minutes

### Step 1: Provision Cloud VM

**Minimum specs:**
- 2 vCPU, 4GB RAM (4+ vCPU, 8GB+ RAM recommended)
- 50GB disk space
- Ubuntu 24.04 LTS
- Ports 7860, 8001, 11434 open in firewall

**Cloud providers:**
- [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)
- [AWS EC2](https://aws.amazon.com/ec2/)
- [Google Cloud Compute](https://cloud.google.com/compute)
- [DigitalOcean Droplets](https://www.digitalocean.com/products/droplets)

### Step 2: SSH and Install Docker

```bash
# SSH into your VM
ssh ubuntu@YOUR_VM_IP

# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Log out and back in for group to take effect
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

# Copy example config
cp .env.example .env

# Edit configuration
nano .env
```

**Minimum required changes in `.env`:**
```bash
# Change ADMIN_TOKEN to something secure
ADMIN_TOKEN=your-secure-token-here

# For production, use a real LLM provider
# Option 1: Use Groq (free tier available)
PROVIDER_ORDER=groq,ollama
GROQ_API_KEY=your-groq-api-key

# Option 2: Use Gemini
PROVIDER_ORDER=gemini,ollama
GOOGLE_API_KEY=your-google-api-key

# Option 3: Use Ollama only (local, no API key needed)
PROVIDER_ORDER=ollama
```

**Generate secure secrets:**
```bash
cd ../../..  # Back to project root
./scripts/generate-secrets.sh >> platforms/oracle/compose/.env
```

### Step 5: Check Requirements

```bash
./scripts/preflight-check.sh docker-compose
```

### Step 6: Deploy

```bash
./scripts/deploy.sh docker-compose
```

This will:
- Pull latest container images
- Start all services
- Initialize databases
- Wait for services to become ready

### Step 7: Verify Deployment

```bash
./scripts/health-check.sh docker-compose
```

### Step 8: Access Services

Services are accessible at:
- **Matrix AI**: `http://YOUR_VM_IP:7860`
- **Matrix Guardian**: `http://YOUR_VM_IP:8001`
- **Ollama** (if enabled): `http://YOUR_VM_IP:11434`

```bash
# Check service status
cd platforms/oracle/compose
docker compose ps

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f matrix-ai
```

**✅ You're done!** Agent-Matrix is now running on your cloud VM.

---

## 🔧 Next Steps

### 1. Configure LLM Providers

For production use, configure external LLM providers:

**Get API Keys:**
- **Groq**: https://console.groq.com/ (free tier available, fast inference)
- **Google Gemini**: https://makersuite.google.com/app/apikey
- **OpenAI**: https://platform.openai.com/api-keys
- **Anthropic**: https://console.anthropic.com/

**Update configuration:**
```bash
# For MiniKube
kubectl edit configmap matrix-ai-config -n matrix

# For Docker Compose
nano platforms/oracle/compose/.env
# Then: docker compose restart
```

### 2. Install Matrix CLI

```bash
# Install matrix-cli for interacting with the infrastructure
pip install matrix-cli

# Configure CLI
export MATRIX_HUB_URL="http://YOUR_MATRIX_HUB_URL"
export ADMIN_TOKEN="your-admin-token"

# Test
matrix-cli agent list
```

### 3. Register Your First Agent

```bash
# Using matrix-cli
matrix-cli agent register --name my-agent --type general

# Or via API
curl -X POST http://YOUR_MATRIX_HUB_URL/api/agents \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-agent", "type": "general"}'
```

### 4. Test the Alive System Loop

1. Register agents and tools in Matrix Hub
2. Submit a task to Matrix AI for reasoning
3. Check Matrix Guardian for governance approval
4. Monitor execution in Matrix Architect
5. View economic impact in Matrix Treasury

See the main repository documentation for detailed guides.

### 5. Set Up Monitoring (Recommended for Production)

```bash
# Add Prometheus and Grafana for observability
kubectl apply -f platforms/monitoring/prometheus.yaml
kubectl apply -f platforms/monitoring/grafana.yaml
```

---

## 🛠 Common Operations

### View Service Logs

**MiniKube:**
```bash
kubectl logs -f deployment/matrix-hub -n matrix
kubectl logs -f deployment/matrix-ai -n matrix
kubectl logs -f deployment/matrix-guardian -n matrix
```

**Docker Compose:**
```bash
cd platforms/oracle/compose
docker compose logs -f
docker compose logs -f matrix-ai
```

### Restart Services

**MiniKube:**
```bash
kubectl rollout restart deployment/matrix-hub -n matrix
kubectl rollout restart deployment/matrix-ai -n matrix
```

**Docker Compose:**
```bash
cd platforms/oracle/compose
docker compose restart
docker compose restart matrix-ai
```

### Update Services

**MiniKube:**
```bash
kubectl set image deployment/matrix-hub matrix-hub=ghcr.io/agent-matrix/matrix-hub:v1.2.3 -n matrix
```

**Docker Compose:**
```bash
cd platforms/oracle/compose
docker compose pull
docker compose up -d
```

### Stop Services

**MiniKube:**
```bash
kubectl delete namespace matrix
minikube stop
```

**Docker Compose:**
```bash
cd platforms/oracle/compose
docker compose down
```

### Complete Removal

**MiniKube:**
```bash
kubectl delete namespace matrix
minikube delete
```

**Docker Compose:**
```bash
cd platforms/oracle/compose
docker compose down -v  # -v removes volumes too
```

---

## 📚 Documentation

- **Architecture**: [docs/architecture.md](docs/architecture.md)
- **LLM Providers**: [docs/llm-providers.md](docs/llm-providers.md)
- **Production Deployment**: [todo/DEPLOYMENT_GUIDE.md](todo/DEPLOYMENT_GUIDE.md)
- **Troubleshooting**: [todo/TROUBLESHOOTING.md](todo/TROUBLESHOOTING.md)
- **Requirements**: [todo/REQUIREMENTS.md](todo/REQUIREMENTS.md)
- **Scripts Reference**: [scripts/README.md](scripts/README.md)

---

## ❓ Troubleshooting

### Services not starting
- Wait 2-5 minutes for container pulls and initialization
- Check logs: `kubectl logs` or `docker compose logs`
- Verify resources: `kubectl top pods` or `docker stats`

### Cannot access services
- **MiniKube**: Ensure you're using MiniKube IP, not localhost
- **Docker Compose**: Check firewall rules allow ports 7860, 8001
- Verify services are running: `kubectl get pods` or `docker compose ps`

### Out of memory
- Increase MiniKube resources: `minikube delete && minikube start --memory=16384`
- Add swap on VM: `sudo fallocate -l 4G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`

### Image pull errors
- Check internet connectivity
- Verify image names in deployment files
- Try manual pull: `docker pull ghcr.io/agent-matrix/matrix-hub:latest`

**For more help:** See [todo/TROUBLESHOOTING.md](todo/TROUBLESHOOTING.md)

---

## 🆘 Getting Help

- **Issues**: https://github.com/agent-matrix/matrix-infra/issues
- **Discussions**: https://github.com/agent-matrix/matrix-infra/discussions
- **Documentation**: See `docs/` directory
- **Scripts Reference**: [scripts/README.md](scripts/README.md)

---

## 📝 Summary

**You can now:**
- ✅ Deploy Agent-Matrix locally (15-30 min) or to cloud (10-20 min)
- ✅ Access all core services (Hub, AI, Guardian, Architect, Treasury)
- ✅ Register agents and tools
- ✅ Test the alive system loop
- ✅ Monitor and manage services

**Next:** Explore the [architecture](docs/architecture.md) and register your first agent!

---

**Welcome to the Agent-Matrix ecosystem! 🧬**
