# Troubleshooting Guide for Agent-Matrix Infrastructure

## Common Deployment Issues

### 1. Docker Daemon Won't Start

**Symptoms:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Causes and Solutions:**

#### Running in Containerized Environment
```bash
# Check if running inside a container
cat /proc/1/cgroup | grep docker

# If yes, this won't work - you need a bare metal/VM environment
# See REQUIREMENTS.md for proper environment setup
```

#### Service Not Running
```bash
# Ubuntu/Debian with systemd
sudo systemctl status docker
sudo systemctl start docker
sudo systemctl enable docker

# Check for errors
journalctl -u docker -n 50
```

#### Permission Issues
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Verify
docker ps
```

#### Kernel Module Issues
```bash
# Check overlay filesystem support
grep overlay /proc/filesystems

# If missing, you may need to load the module
sudo modprobe overlay

# Or your kernel doesn't support it - upgrade kernel
uname -r  # Should be 4.0+
```

---

### 2. MiniKube Won't Start

**Symptoms:**
```
minikube start fails with various errors
```

**Solutions:**

#### Insufficient Resources
```bash
# Ensure adequate resources
minikube start --cpus=4 --memory=8192

# Check available resources
nproc  # Should show 4+
free -h  # Should show 8GB+ total
```

#### Driver Issues
```bash
# Try different driver
minikube start --driver=docker --cpus=4 --memory=8192

# Or use virtualbox/kvm2
minikube start --driver=virtualbox
```

#### Existing Cluster Issues
```bash
# Delete old cluster
minikube delete

# Start fresh
minikube start --cpus=4 --memory=8192
```

#### Check Logs
```bash
minikube logs
```

---

### 3. Pods Won't Start (CrashLoopBackOff / ImagePullBackOff)

**Check Pod Status:**
```bash
kubectl get pods -n matrix
kubectl describe pod POD_NAME -n matrix
kubectl logs POD_NAME -n matrix
```

#### ImagePullBackOff

**Cause:** Cannot pull container image from registry

**Solutions:**
```bash
# Check image name in deployment.yaml
kubectl get deployment DEPLOYMENT_NAME -n matrix -o yaml | grep image:

# Verify internet connectivity
curl -I https://ghcr.io

# Check if image exists
docker pull ghcr.io/agent-matrix/matrix-hub:latest

# For private registries, create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  -n matrix
```

#### CrashLoopBackOff

**Cause:** Container is starting but crashing

**Solutions:**
```bash
# Check logs for the crash
kubectl logs POD_NAME -n matrix --previous

# Common causes:
# 1. Missing environment variables
kubectl describe pod POD_NAME -n matrix | grep -A 20 "Environment:"

# 2. Missing secrets
kubectl get secrets -n matrix

# 3. Database connection issues
# Check if database pods are running
kubectl get pods -n matrix | grep postgres

# 4. Port conflicts
# Check service definitions
kubectl get svc -n matrix
```

---

### 4. Services Not Accessible

**Symptoms:**
Cannot access services via NodePort or LoadBalancer

**MiniKube Solutions:**
```bash
# Get MiniKube IP
minikube ip

# Get service URLs
minikube service list -n matrix

# Tunnel for LoadBalancer services
minikube tunnel

# Port forward for testing
kubectl port-forward -n matrix svc/matrix-hub 8080:80
```

**Docker Compose Solutions:**
```bash
# Check container ports
docker compose ps

# Check if ports are bound
netstat -tulpn | grep 7860
netstat -tulpn | grep 8001

# Check firewall
sudo ufw status
sudo ufw allow 7860/tcp
sudo ufw allow 8001/tcp

# Check container networks
docker network ls
docker network inspect compose_default
```

---

### 5. Database Connection Issues

**Symptoms:**
Services fail with database connection errors

**PostgreSQL Issues:**
```bash
# Check if database pod is running
kubectl get pods -n matrix | grep postgres

# Check database logs
kubectl logs -n matrix postgres-POD-NAME

# Verify database secret exists
kubectl get secret -n matrix | grep database

# Test connection from within cluster
kubectl run -it --rm debug --image=postgres:14 --restart=Never -- \
  psql -h postgres-service -U postgres
```

**Guardian Database Issues:**
```bash
# Guardian uses SQLite by default, or PostgreSQL if configured
# Check Guardian logs
kubectl logs -n matrix deployment/matrix-guardian

# For Docker Compose
docker compose logs matrix-guardian

# Check volume mounts
kubectl describe pod -n matrix matrix-guardian-POD-NAME | grep -A 5 Volumes
```

---

### 6. LLM Provider Issues

**Symptoms:**
Matrix AI cannot connect to LLM providers

**Check Configuration:**
```bash
# MiniKube
kubectl get configmap -n matrix matrix-ai-config -o yaml
kubectl get secret -n matrix matrix-secrets -o yaml

# Docker Compose
cat platforms/oracle/compose/.env
```

**Ollama Issues:**
```bash
# Check if Ollama pod is running
kubectl get pods -n matrix | grep ollama

# Check Ollama logs
kubectl logs -n matrix deployment/ollama

# Verify model is pulled
kubectl exec -it deployment/ollama -n matrix -- ollama list

# Pull model manually
kubectl exec -it deployment/ollama -n matrix -- ollama pull llama3

# Test Ollama endpoint
kubectl exec -it deployment/matrix-ai -n matrix -- \
  curl http://ollama:11434/api/tags
```

**API Key Issues:**
```bash
# For Groq/Gemini/HuggingFace
# Verify secrets are set
kubectl get secret matrix-secrets -n matrix -o jsonpath='{.data.GROQ_API_KEY}' | base64 -d

# Test API keys
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.groq.com/openai/v1/models
```

---

### 7. Memory and Resource Issues

**Symptoms:**
Pods are OOMKilled or evicted

**Solutions:**
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n matrix

# Increase MiniKube resources
minikube stop
minikube start --cpus=8 --memory=16384

# Set resource limits (edit deployment)
kubectl edit deployment matrix-architect -n matrix

# Add/modify:
# resources:
#   requests:
#     memory: "512Mi"
#     cpu: "250m"
#   limits:
#     memory: "2Gi"
#     cpu: "1000m"
```

---

### 8. Network/DNS Issues

**Symptoms:**
Services cannot communicate with each other

**Solutions:**
```bash
# Check CoreDNS is running
kubectl get pods -n kube-system | grep coredns

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup matrix-hub.matrix.svc.cluster.local

# Check service endpoints
kubectl get endpoints -n matrix

# Verify network policies (if any)
kubectl get networkpolicies -n matrix
```

---

### 9. Persistent Volume Issues

**Symptoms:**
Pods stuck in Pending with PVC issues

**Solutions:**
```bash
# Check PVC status
kubectl get pvc -n matrix

# Describe PVC for events
kubectl describe pvc PVC_NAME -n matrix

# Check if storage class exists
kubectl get storageclass

# For MiniKube, ensure storage provisioner is enabled
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
```

---

### 10. Configuration/Secret Issues

**Missing Secrets:**
```bash
# List secrets
kubectl get secrets -n matrix

# Create matrix-secrets if missing
kubectl create secret generic matrix-secrets \
  --from-literal=ADMIN_TOKEN=$(openssl rand -hex 32) \
  --from-literal=JWT_SECRET=$(openssl rand -hex 32) \
  -n matrix

# For Docker Compose
# Ensure .env file exists
ls -la platforms/oracle/compose/.env

# Copy from example if missing
cp platforms/oracle/compose/.env.example platforms/oracle/compose/.env
```

---

## Validation and Health Checks

### System Health Check Script

```bash
#!/bin/bash
# Save as check-health.sh

echo "=== Agent-Matrix Health Check ==="
echo

echo "1. Checking cluster connectivity..."
kubectl cluster-info || echo "FAIL: Cannot connect to cluster"

echo
echo "2. Checking namespace..."
kubectl get namespace matrix || echo "FAIL: matrix namespace not found"

echo
echo "3. Checking pods..."
kubectl get pods -n matrix
READY_PODS=$(kubectl get pods -n matrix --field-selector=status.phase=Running 2>/dev/null | grep -v NAME | wc -l)
echo "Ready pods: $READY_PODS"

echo
echo "4. Checking services..."
kubectl get svc -n matrix

echo
echo "5. Checking secrets..."
kubectl get secrets -n matrix

echo
echo "6. Checking recent events..."
kubectl get events -n matrix --sort-by='.lastTimestamp' | tail -10

echo
echo "=== Health Check Complete ==="
```

### Service Endpoint Tests

```bash
# Matrix Hub
curl -f http://MINIKUBE_IP:30081/health || echo "Matrix Hub unhealthy"

# Matrix AI
curl -f http://MINIKUBE_IP:30083/health || echo "Matrix AI unhealthy"

# Matrix Guardian
curl -f http://MINIKUBE_IP:30082/health || echo "Matrix Guardian unhealthy"
```

---

## Getting Help

### Logs Collection

When reporting issues, collect:

```bash
# All pod logs
kubectl logs -n matrix --all-containers=true --tail=100 > all-logs.txt

# Cluster info
kubectl cluster-info dump -n matrix > cluster-dump.txt

# Describe all resources
kubectl describe all -n matrix > describe-all.txt

# Docker compose logs
docker compose logs --tail=100 > compose-logs.txt
```

### Environment Information

```bash
# System info
uname -a
docker --version
kubectl version
minikube version

# Resource availability
nproc
free -h
df -h

# Network
ip addr
ip route
```

### Support Channels

- **GitHub Issues**: https://github.com/agent-matrix/matrix-infra/issues
- **Documentation**: See `docs/` folder in repository
- **Community**: Check Agent-Matrix organization repos

---

## Emergency Recovery

### Complete Reset (MiniKube)

```bash
# Nuclear option - delete everything
kubectl delete namespace matrix
minikube stop
minikube delete

# Start fresh
minikube start --cpus=4 --memory=8192
kubectl create namespace matrix
kubectl apply -k platforms/minikube
```

### Complete Reset (Docker Compose)

```bash
cd platforms/oracle/compose

# Stop and remove everything
docker compose down -v

# Remove all containers, networks, volumes
docker compose rm -f
docker volume prune -f

# Start fresh
docker compose pull
docker compose up -d
```

---

## Prevention Best Practices

1. **Always check requirements** before deploying
2. **Monitor resources** during operation
3. **Use proper secrets** (not defaults) in production
4. **Pin image versions** in production
5. **Test in development** before production deployment
6. **Keep logs** for troubleshooting
7. **Document changes** to infrastructure
8. **Regular backups** of data volumes
9. **Health checks** enabled for all services
10. **Monitoring** set up (Prometheus/Grafana recommended)

---

## Known Limitations

1. **Docker-in-Docker**: Not supported without privileged mode and proper kernel support
2. **ARM64**: Some images may not have ARM64 builds (check GHCR for availability)
3. **Resource constraints**: Minimum 4 CPU / 8GB RAM required
4. **Network restrictions**: Some corporate networks block container registries
5. **Kernel versions**: Requires Linux 4.0+, 5.0+ recommended

See **REQUIREMENTS.md** for complete compatibility matrix.
