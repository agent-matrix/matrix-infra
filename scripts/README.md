# Agent-Matrix Infrastructure Scripts

This directory contains production-ready deployment and management scripts for the Agent-Matrix infrastructure.

## Quick Start

```bash
# 1. Check your system meets requirements
./scripts/preflight-check.sh

# 2. Deploy to MiniKube (local development)
./scripts/deploy.sh minikube

# 3. Verify deployment
./scripts/health-check.sh
```

## Available Scripts

### 🚀 Deployment Scripts

#### `deploy.sh` - One-Command Deployment
**The recommended way to deploy Agent-Matrix infrastructure.**

Handles pre-flight checks, deployment, and post-deployment verification in a single command.

```bash
# Deploy to MiniKube (local/development)
./scripts/deploy.sh minikube

# Deploy to Docker Compose (cloud VM/production)
./scripts/deploy.sh docker-compose

# Skip pre-flight checks
./scripts/deploy.sh minikube --skip-checks

# Skip health verification
./scripts/deploy.sh docker-compose --skip-verify
```

**Features:**
- Automatic dependency checking
- Pre-flight environment validation
- Deployment execution
- Post-deployment health checks
- Clear success/failure reporting
- Helpful next-steps guidance

**Time to deploy:**
- MiniKube: 15-30 minutes (first time)
- Docker Compose: 10-20 minutes

---

#### `setup_minikube.sh` - MiniKube Setup
Legacy script for MiniKube deployment. Use `deploy.sh minikube` instead.

```bash
./scripts/setup_minikube.sh
```

---

#### `install.sh` - Interactive Installer
Interactive menu-driven installer. Choose deployment type interactively.

```bash
./scripts/install.sh
```

---

### ✅ Validation Scripts

#### `preflight-check.sh` - Pre-flight Environment Validation
Validates system requirements before deployment.

```bash
# Auto-detect deployment type and check
./scripts/preflight-check.sh

# Check for MiniKube deployment
./scripts/preflight-check.sh minikube

# Check for Docker Compose deployment
./scripts/preflight-check.sh docker-compose
```

**Checks:**
- Docker installation and daemon status
- kubectl and minikube availability (for K8s)
- System resources (CPU, RAM, disk)
- Kernel compatibility
- Port availability
- Environment configuration

---

#### `health-check.sh` - Post-Deployment Health Checks
Verifies all services are running and healthy after deployment.

```bash
# Auto-detect deployment and check
./scripts/health-check.sh

# Check MiniKube deployment
./scripts/health-check.sh minikube

# Check Docker Compose deployment
./scripts/health-check.sh docker-compose
```

**Checks:**
- Pod/container status
- Service availability
- Endpoint responsiveness
- Recent logs and events
- Provides access URLs

---

### 🔐 Security Scripts

#### `generate-secrets.sh` - Production Secrets Generation
Generates cryptographically secure secrets for production deployments.

```bash
# Generate secrets to stdout
./scripts/generate-secrets.sh

# Generate secrets to file
./scripts/generate-secrets.sh secrets.env

# Use with Kubernetes
./scripts/generate-secrets.sh secrets.env
kubectl create secret generic matrix-secrets --from-env-file=secrets.env -n matrix

# Use with Docker Compose
./scripts/generate-secrets.sh >> platforms/oracle/compose/.env
```

**Generates:**
- ADMIN_TOKEN - Inter-service authentication
- JWT_SECRET - Token signing
- ADMIN_PRIVATE_KEY - Encryption key
- ADMIN_ENCRYPTION_KEY - Data encryption
- MCP_GATEWAY_TOKEN - MCP Gateway access
- NETWORK_SECRET_KEY - Network MatrixHub
- NEXTAUTH_SECRET - Authentication secret

**⚠️ Important:**
- Never commit generated secrets to git
- Store secrets securely (vault, secrets manager)
- Rotate secrets regularly in production
- Use different secrets for dev/staging/prod

---

## Usage Patterns

### Development Workflow

```bash
# 1. First time setup
git clone https://github.com/agent-matrix/matrix-infra.git
cd matrix-infra

# 2. Check requirements
./scripts/preflight-check.sh minikube

# 3. Deploy
./scripts/deploy.sh minikube

# 4. Verify
./scripts/health-check.sh minikube

# 5. Access services
minikube service list -n matrix
```

### Production Workflow (Cloud VM)

```bash
# 1. SSH into your VM
ssh user@your-vm-ip

# 2. Clone repository
git clone https://github.com/agent-matrix/matrix-infra.git
cd matrix-infra

# 3. Configure environment
cd platforms/oracle/compose
cp .env.example .env
nano .env  # Edit configuration

# 4. Generate production secrets
cd ../../..
./scripts/generate-secrets.sh >> platforms/oracle/compose/.env

# 5. Check requirements
./scripts/preflight-check.sh docker-compose

# 6. Deploy
./scripts/deploy.sh docker-compose

# 7. Verify
./scripts/health-check.sh docker-compose
```

### CI/CD Integration

```bash
# In your CI pipeline
./scripts/preflight-check.sh minikube || exit 1
./scripts/deploy.sh minikube --skip-checks
./scripts/health-check.sh minikube || exit 1
```

---

## Makefile Integration

All scripts are integrated into the project Makefile for convenience:

```bash
# Using Makefile (recommended)
make preflight              # Run pre-flight checks
make deploy-minikube        # Deploy to MiniKube
make deploy-docker-compose  # Deploy to Docker Compose
make health-check           # Run health checks
make generate-secrets       # Generate production secrets

# Direct script usage (alternative)
./scripts/deploy.sh minikube
```

---

## Environment Variables

Scripts support the following environment variables:

- `SKIP_CHECKS=true` - Skip pre-flight validation
- `SKIP_VERIFY=true` - Skip post-deployment health checks
- `TIMEOUT=300` - Health check timeout in seconds

Example:
```bash
SKIP_CHECKS=true ./scripts/deploy.sh minikube
```

---

## Troubleshooting

### Pre-flight Checks Fail
- Review error messages carefully
- Check system requirements in `todo/REQUIREMENTS.md`
- Ensure Docker daemon is running: `docker ps`
- For MiniKube: Ensure sufficient resources

### Deployment Fails
- Check logs: `kubectl logs -n matrix <pod-name>`
- Or: `docker compose logs -f`
- Verify .env configuration
- Ensure secrets are set correctly
- Check firewall/network settings

### Health Checks Fail
- Wait 2-5 minutes for services to start
- Re-run health check: `./scripts/health-check.sh`
- Check pod/container status
- Review service logs

### Common Issues
- **Port conflicts**: Check if ports are already in use
- **Out of memory**: Increase system/MiniKube RAM
- **Image pull errors**: Check internet connectivity
- **Permission denied**: Ensure user is in docker group

---

## Script Development

### Adding New Scripts

1. Create script in `scripts/` directory
2. Add shebang: `#!/usr/bin/env bash`
3. Set strict mode: `set -euo pipefail`
4. Make executable: `chmod +x scripts/your-script.sh`
5. Add to Makefile if appropriate
6. Update this README

### Code Style

- Use bash for compatibility
- Include usage/help output
- Provide colored output for readability
- Handle errors gracefully
- Support both auto-detection and explicit modes
- Include validation and sanity checks

---

## Related Documentation

- **Quick Start**: See `/QUICKSTART.md` for end-user guide
- **Requirements**: See `/todo/REQUIREMENTS.md` for system requirements
- **Deployment Guide**: See `/todo/DEPLOYMENT_GUIDE.md` for detailed deployment instructions
- **Troubleshooting**: See `/todo/TROUBLESHOOTING.md` for common issues

---

## Support

- **Issues**: https://github.com/agent-matrix/matrix-infra/issues
- **Documentation**: See `docs/` directory
- **Community**: Agent-Matrix GitHub organization

---

## License

Apache 2.0 - See LICENSE file in repository root.
