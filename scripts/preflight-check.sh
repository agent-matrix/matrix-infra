#!/usr/bin/env bash

# Pre-flight environment validation for Agent-Matrix deployment
# Checks system requirements, dependencies, and resources before deployment
# Usage: ./preflight-check.sh [minikube|docker-compose]

set -euo pipefail

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

DEPLOYMENT_TYPE="${1:-auto}"
ERRORS=0
WARNINGS=0

header() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

check_pass() {
  echo -e "  ${GREEN}✓${NC} $1"
}

check_fail() {
  echo -e "  ${RED}✗${NC} $1"
  ((ERRORS++))
}

check_warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
  ((WARNINGS++))
}

check_command() {
  local cmd="$1"
  local required="$2"
  local message="$3"

  if command -v "$cmd" >/dev/null 2>&1; then
    local version=$(eval "$cmd --version 2>&1 | head -n1" || echo "unknown")
    check_pass "$cmd is installed ($version)"
    return 0
  else
    if [ "$required" = "true" ]; then
      check_fail "$cmd is not installed - $message"
      return 1
    else
      check_warn "$cmd is not installed - $message"
      return 0
    fi
  fi
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    check_fail "Docker is not installed"
    return 1
  fi

  check_pass "Docker is installed"

  # Check if Docker daemon is running
  if ! docker ps >/dev/null 2>&1; then
    check_fail "Docker daemon is not running - run 'sudo systemctl start docker' or start Docker Desktop"
    return 1
  fi

  check_pass "Docker daemon is running"

  # Check Docker version
  local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0")
  check_pass "Docker version: $docker_version"

  return 0
}

check_resources() {
  local deployment="$1"

  # Check CPU cores
  local cpus=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "0")
  if [ "$cpus" -ge 4 ]; then
    check_pass "CPU cores: $cpus (minimum 4 required)"
  elif [ "$cpus" -ge 2 ]; then
    check_warn "CPU cores: $cpus (4+ recommended for production)"
  else
    check_fail "CPU cores: $cpus (minimum 4 required)"
  fi

  # Check memory (in GB)
  local mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
  local mem_gb=$((mem_kb / 1024 / 1024))

  if [ "$mem_gb" -eq 0 ]; then
    # Try macOS method
    local mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    mem_gb=$((mem_bytes / 1024 / 1024 / 1024))
  fi

  if [ "$mem_gb" -ge 8 ]; then
    check_pass "Memory: ${mem_gb}GB (minimum 8GB required)"
  elif [ "$mem_gb" -ge 4 ]; then
    check_warn "Memory: ${mem_gb}GB (8GB+ recommended)"
  else
    check_fail "Memory: ${mem_gb}GB (minimum 8GB required)"
  fi

  # Check disk space
  local disk_avail=$(df -BG . 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo "0")
  if [ "$disk_avail" -ge 50 ]; then
    check_pass "Disk space: ${disk_avail}GB available (minimum 50GB required)"
  elif [ "$disk_avail" -ge 20 ]; then
    check_warn "Disk space: ${disk_avail}GB available (50GB+ recommended)"
  else
    check_fail "Disk space: ${disk_avail}GB available (minimum 50GB required)"
  fi
}

check_kernel() {
  # Check kernel version
  local kernel=$(uname -r)
  check_pass "Kernel version: $kernel"

  # Check overlay filesystem support
  if grep -q overlay /proc/filesystems 2>/dev/null; then
    check_pass "Overlay filesystem is supported"
  else
    check_warn "Overlay filesystem not detected (may not be critical on macOS/Windows)"
  fi

  # Check if running in container
  if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    check_fail "Running inside a container - Agent-Matrix requires bare metal, VM, or proper DinD setup"
  else
    check_pass "Not running inside a container"
  fi
}

check_ports() {
  local deployment="$1"
  local ports_to_check=""

  if [ "$deployment" = "minikube" ]; then
    ports_to_check="30081 30082 30083 30084 30085 30086 30087 30088 30089 30090"
  elif [ "$deployment" = "docker-compose" ]; then
    ports_to_check="7860 8001 11434"
  fi

  if [ -z "$ports_to_check" ]; then
    return 0
  fi

  for port in $ports_to_check; do
    if command -v netstat >/dev/null 2>&1; then
      if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        check_warn "Port $port is already in use"
      fi
    elif command -v ss >/dev/null 2>&1; then
      if ss -tuln 2>/dev/null | grep -q ":$port "; then
        check_warn "Port $port is already in use"
      fi
    fi
  done
}

check_minikube_prereqs() {
  header "Checking MiniKube deployment prerequisites"

  check_docker || true
  check_command kubectl true "Install from https://kubernetes.io/docs/tasks/tools/"
  check_command minikube true "Install from https://minikube.sigs.k8s.io/docs/start/"
  check_resources "minikube"
  check_kernel
  check_ports "minikube"

  # Check if minikube is running
  if command -v minikube >/dev/null 2>&1; then
    if minikube status >/dev/null 2>&1; then
      check_pass "MiniKube cluster is running"
    else
      check_warn "MiniKube cluster is not running - will start during deployment"
    fi
  fi
}

check_docker_compose_prereqs() {
  header "Checking Docker Compose deployment prerequisites"

  check_docker || true
  check_command docker true "Install from https://docs.docker.com/get-docker/"

  # Check for docker compose (v2) or docker-compose (v1)
  if docker compose version >/dev/null 2>&1; then
    local version=$(docker compose version --short 2>/dev/null || echo "unknown")
    check_pass "Docker Compose is installed (v2: $version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    local version=$(docker-compose version --short 2>/dev/null || echo "unknown")
    check_pass "Docker Compose is installed (v1: $version)"
  else
    check_fail "Docker Compose is not installed - install docker-compose-plugin"
  fi

  check_resources "docker-compose"
  check_kernel
  check_ports "docker-compose"

  # Check if .env file exists for docker compose
  if [ -f "platforms/oracle/compose/.env" ]; then
    check_pass ".env file exists in platforms/oracle/compose/"
  else
    check_warn ".env file not found - copy .env.example to .env and configure"
  fi
}

auto_detect() {
  if command -v minikube >/dev/null 2>&1 && command -v kubectl >/dev/null 2>&1; then
    echo "minikube"
  elif command -v docker >/dev/null 2>&1 && (docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1); then
    echo "docker-compose"
  else
    echo "unknown"
  fi
}

print_summary() {
  echo ""
  echo "============================================================"
  if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! System is ready for deployment.${NC}"
  elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found. Deployment may proceed but review warnings.${NC}"
  else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found.${NC}"
    echo -e "${RED}Please fix errors before deploying.${NC}"
    return 1
  fi
  echo "============================================================"
  echo ""
}

main() {
  echo "============================================================"
  echo "  Agent-Matrix Infrastructure Pre-flight Check"
  echo "============================================================"

  local deployment="$DEPLOYMENT_TYPE"

  if [ "$deployment" = "auto" ]; then
    deployment=$(auto_detect)
    echo -e "${BLUE}Auto-detected deployment type: $deployment${NC}"
  fi

  case "$deployment" in
    minikube)
      check_minikube_prereqs
      ;;
    docker-compose)
      check_docker_compose_prereqs
      ;;
    *)
      echo -e "${YELLOW}Unable to detect deployment type. Checking common prerequisites...${NC}"
      header "Checking common prerequisites"
      check_docker || true
      check_resources "generic"
      check_kernel
      ;;
  esac

  print_summary
}

main "$@"
