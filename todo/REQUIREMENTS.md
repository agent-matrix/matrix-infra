# Infrastructure Requirements for Agent-Matrix Deployment

## Minimum System Requirements

### Hardware
- **CPU**: 4 cores (minimum), 8+ cores recommended for production
- **RAM**: 8GB (minimum), 16GB+ recommended for production
- **Disk**: 50GB available space (100GB+ for production with logs/data)
- **Network**: Stable internet connection for pulling container images

### Operating System

**Supported Platforms:**
- Ubuntu 24.04 LTS (Noble) - **Recommended**
- Ubuntu 22.04 LTS (Jammy)
- Debian 11/12
- CentOS 8+
- macOS 12+ (with Docker Desktop)
- Windows 10/11 (with Docker Desktop and WSL2)

**Not Supported:**
- Containerized environments (Docker-in-Docker) without privileged mode
- Systems without kernel module support
- Environments with restricted networking

## Required Software Dependencies

### For MiniKube Deployment (Local Development)

1. **Docker** (v20.10+)
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y docker.io
   sudo systemctl enable --now docker
   sudo usermod -aG docker $USER
   ```

2. **kubectl** (v1.28+)
   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

3. **MiniKube** (v1.32+)
   ```bash
   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
   sudo install minikube-linux-amd64 /usr/local/bin/minikube
   ```

4. **Git** (for cloning repository)
   ```bash
   sudo apt-get install -y git
   ```

### For Oracle/Docker Compose Deployment

1. **Docker** (same as above)
2. **Docker Compose** (v2.0+)
   ```bash
   # Usually included with Docker, or install separately:
   sudo apt-get install -y docker-compose-plugin
   ```

3. **Git** (for cloning repository)

## Kernel Requirements

The following kernel features must be available:

- **Namespaces**: network, mount, pid, ipc, uts
- **Cgroups**: v1 or v2
- **Storage**: overlay2, aufs, or devicemapper support
- **Networking**: iptables, nftables, or equivalent
- **Capabilities**: CAP_SYS_ADMIN, CAP_NET_ADMIN, CAP_NET_RAW

Check kernel support:
```bash
# Check overlay filesystem support
grep overlay /proc/filesystems

# Check network namespaces
ls /proc/self/ns/

# Verify kernel version (4.0+ required, 5.0+ recommended)
uname -r
```

## Network Requirements

### Ports Required

**MiniKube Deployment:**
- **30081**: Matrix Hub API
- **30082**: Matrix Guardian API
- **30083**: Matrix AI API
- **30084**: Matrix Architect API
- **30085**: Matrix Architect UI
- **30086**: Matrix Treasury API
- **30087**: Matrix Treasury UI
- **30088**: Network MatrixHub UI
- **30089**: Matrix Hub Admin UI
- **30090**: A2A Validator UI
- **11434**: Ollama (if using local LLM)

**Docker Compose Deployment:**
- **7860**: Matrix AI
- **8001**: Matrix Guardian
- **11434**: Ollama (if using local LLM)

### Outbound Connectivity

The deployment requires internet access to:
- Pull container images from `ghcr.io/agent-matrix/*`
- Access LLM APIs (if using hosted providers):
  - Groq API (api.groq.com)
  - Google Gemini (generativelanguage.googleapis.com)
  - HuggingFace (huggingface.co)
  - OpenAI (api.openai.com)
  - Anthropic (api.anthropic.com)

## Configuration Requirements

### Secrets and API Keys

You will need to configure the following (create from `.env.example`):

**Required:**
- `ADMIN_TOKEN`: Administrative access token for services
- `JWT_SECRET`: Secret for JWT token signing

**Optional (for LLM providers):**
- `GROQ_API_KEY`: Groq LLM API key
- `GOOGLE_API_KEY`: Google Gemini API key
- `HF_TOKEN`: HuggingFace API token
- `OPENAI_API_KEY`: OpenAI API key
- `ANTHROPIC_API_KEY`: Anthropic API key
- `WATSONX_API_KEY`: IBM watsonx.ai API key

**For local LLM (recommended for testing):**
- Install Ollama: https://ollama.ai/
- No API keys needed

### Database

Some services require PostgreSQL:
- Matrix Guardian uses a local SQLite or PostgreSQL database
- Matrix Hub requires PostgreSQL (can use managed service or deploy locally)

For MiniKube, databases are included in the deployment manifests.

## Service Architecture

The complete Agent-Matrix ecosystem includes:

### Core Services
1. **Matrix Hub** - Agent/tool registry and catalog
2. **Matrix Guardian** - Governance and safety layer
3. **Matrix AI** - Reasoning and planning engine
4. **Matrix Architect** - Execution and evolution layer
5. **Matrix Treasury** - Economic operating system

### Supporting Services
6. **Matrix Hub Admin** - Web UI for Matrix Hub
7. **Network MatrixHub** - Professional network portal
8. **A2A Validator** - Agent-to-Agent protocol validator

### Optional Services
9. **Ollama** - Local LLM inference server
10. **PostgreSQL** - Database for persistence
11. **Redis** - Cache for Matrix Architect
12. **Celery Workers** - Background task processing

## Resource Allocation

**Minimum for Development:**
```
Total CPU: 4 cores
Total RAM: 8GB
Total Disk: 50GB
```

**Recommended for Production:**
```
Total CPU: 8-16 cores
Total RAM: 16-32GB
Total Disk: 100-500GB (depending on data volume)
Load Balancer: For multi-replica deployments
Monitoring: Prometheus + Grafana recommended
```

## Pre-flight Checklist

Before attempting deployment, verify:

- [ ] Running on bare metal, VM, or properly configured cloud instance
- [ ] NOT running inside a Docker container
- [ ] Docker daemon can start successfully (`docker ps` works)
- [ ] At least 4 CPU cores and 8GB RAM available
- [ ] 50GB+ free disk space
- [ ] Kernel version 4.0+ (5.0+ preferred)
- [ ] Internet connectivity for image pulls
- [ ] Firewall rules allow required ports
- [ ] For MiniKube: kubectl and minikube installed
- [ ] For Compose: docker-compose installed
- [ ] Git installed for repository cloning

## Validation Commands

Run these commands to verify your environment:

```bash
# Check Docker
docker --version
docker ps

# Check system resources
nproc  # Should show 4+
free -h  # Should show 8GB+ total
df -h  # Should show 50GB+ available

# Check kernel
uname -r  # Should be 4.0+
grep overlay /proc/filesystems  # Should show 'overlay'

# For MiniKube deployment
kubectl version --client
minikube version

# For Compose deployment
docker compose version
```

All checks should pass before proceeding with deployment.
