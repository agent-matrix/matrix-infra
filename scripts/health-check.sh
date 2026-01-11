#!/usr/bin/env bash

# Health check and verification script for Agent-Matrix deployment
# Verifies all services are running and healthy after deployment
# Usage: ./health-check.sh [minikube|docker-compose]

set -euo pipefail

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

DEPLOYMENT_TYPE="${1:-auto}"
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARN=0

header() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

check_pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  ((CHECKS_PASSED++))
}

check_fail() {
  echo -e "  ${RED}✗${NC} $1"
  ((CHECKS_FAILED++))
}

check_warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
  ((CHECKS_WARN++))
}

wait_for_condition() {
  local description="$1"
  local condition="$2"
  local max_wait="${3:-60}"
  local waited=0

  while [ $waited -lt $max_wait ]; do
    if eval "$condition" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  return 1
}

check_minikube_health() {
  header "Checking MiniKube Cluster"

  # Check if minikube is running
  if minikube status >/dev/null 2>&1; then
    check_pass "MiniKube cluster is running"
  else
    check_fail "MiniKube cluster is not running"
    return 1
  fi

  # Check if kubectl can connect
  if kubectl cluster-info >/dev/null 2>&1; then
    check_pass "kubectl can connect to cluster"
  else
    check_fail "kubectl cannot connect to cluster"
    return 1
  fi

  header "Checking Namespace"

  if kubectl get namespace matrix >/dev/null 2>&1; then
    check_pass "matrix namespace exists"
  else
    check_fail "matrix namespace does not exist"
    return 1
  fi

  header "Checking Pods"

  local pods=$(kubectl get pods -n matrix --no-headers 2>/dev/null | wc -l)
  if [ "$pods" -gt 0 ]; then
    check_pass "Found $pods pod(s) in matrix namespace"
  else
    check_fail "No pods found in matrix namespace"
    return 1
  fi

  # Check individual pod status
  kubectl get pods -n matrix --no-headers 2>/dev/null | while read -r name ready status restarts age; do
    if [ "$status" = "Running" ]; then
      check_pass "Pod $name is Running ($ready)"
    elif [ "$status" = "Pending" ] || [ "$status" = "ContainerCreating" ]; then
      check_warn "Pod $name is $status (may still be starting)"
    else
      check_fail "Pod $name is $status"
    fi
  done

  header "Checking Services"

  local services=$(kubectl get svc -n matrix --no-headers 2>/dev/null | wc -l)
  if [ "$services" -gt 0 ]; then
    check_pass "Found $services service(s)"
  else
    check_warn "No services found"
  fi

  # Get MiniKube IP for endpoint checks
  local minikube_ip=$(minikube ip 2>/dev/null || echo "")

  if [ -n "$minikube_ip" ]; then
    check_pass "MiniKube IP: $minikube_ip"

    header "Checking Service Endpoints"

    # Check Matrix Hub
    if curl -sf "http://$minikube_ip:30081" -o /dev/null 2>&1; then
      check_pass "Matrix Hub is responding at http://$minikube_ip:30081"
    else
      check_warn "Matrix Hub not responding at http://$minikube_ip:30081 (may still be starting)"
    fi

    # Check Matrix AI
    if curl -sf "http://$minikube_ip:30083" -o /dev/null 2>&1; then
      check_pass "Matrix AI is responding at http://$minikube_ip:30083"
    else
      check_warn "Matrix AI not responding at http://$minikube_ip:30083 (may still be starting)"
    fi

    # Check Matrix Guardian
    if curl -sf "http://$minikube_ip:30082" -o /dev/null 2>&1; then
      check_pass "Matrix Guardian is responding at http://$minikube_ip:30082"
    else
      check_warn "Matrix Guardian not responding at http://$minikube_ip:30082 (may still be starting)"
    fi
  fi

  header "Recent Events"
  kubectl get events -n matrix --sort-by='.lastTimestamp' 2>/dev/null | tail -n 10 || true
}

check_docker_compose_health() {
  header "Checking Docker Compose Services"

  local compose_dir="platforms/oracle/compose"
  if [ ! -d "$compose_dir" ]; then
    check_fail "Docker Compose directory not found: $compose_dir"
    return 1
  fi

  cd "$compose_dir"

  # Check if docker compose is available
  local compose_cmd="docker compose"
  if ! docker compose version >/dev/null 2>&1; then
    if command -v docker-compose >/dev/null 2>&1; then
      compose_cmd="docker-compose"
    else
      check_fail "Docker Compose is not available"
      return 1
    fi
  fi

  # Get list of services
  local services=$($compose_cmd ps --services 2>/dev/null || echo "")

  if [ -z "$services" ]; then
    check_fail "No services found (compose stack may not be running)"
    return 1
  fi

  # Check each service
  while IFS= read -r service; do
    local status=$($compose_cmd ps --filter "name=$service" --format "{{.Status}}" 2>/dev/null || echo "")

    if echo "$status" | grep -q "Up"; then
      check_pass "Service $service is Up"
    elif echo "$status" | grep -q "Exit"; then
      check_fail "Service $service has exited"
    else
      check_warn "Service $service status: $status"
    fi
  done <<< "$services"

  header "Checking Service Endpoints"

  # Check Matrix AI
  if curl -sf http://localhost:7860 -o /dev/null 2>&1; then
    check_pass "Matrix AI is responding at http://localhost:7860"
  else
    check_warn "Matrix AI not responding at http://localhost:7860 (may still be starting)"
  fi

  # Check Matrix Guardian
  if curl -sf http://localhost:8001 -o /dev/null 2>&1; then
    check_pass "Matrix Guardian is responding at http://localhost:8001"
  else
    check_warn "Matrix Guardian not responding at http://localhost:8001 (may still be starting)"
  fi

  # Check Ollama if running
  if echo "$services" | grep -q "ollama"; then
    if curl -sf http://localhost:11434/api/tags -o /dev/null 2>&1; then
      check_pass "Ollama is responding at http://localhost:11434"
    else
      check_warn "Ollama not responding at http://localhost:11434 (may still be starting)"
    fi
  fi

  header "Recent Container Logs (last 10 lines)"
  $compose_cmd logs --tail=10 2>/dev/null || true

  cd - >/dev/null
}

auto_detect() {
  if kubectl get namespace matrix >/dev/null 2>&1; then
    echo "minikube"
  elif [ -d "platforms/oracle/compose" ] && docker compose ps >/dev/null 2>&1; then
    echo "docker-compose"
  else
    echo "unknown"
  fi
}

print_summary() {
  echo ""
  echo "============================================================"
  echo -e "Results: ${GREEN}$CHECKS_PASSED passed${NC}, ${RED}$CHECKS_FAILED failed${NC}, ${YELLOW}$CHECKS_WARN warnings${NC}"

  if [ $CHECKS_FAILED -eq 0 ] && [ $CHECKS_WARN -eq 0 ]; then
    echo -e "${GREEN}✓ All health checks passed! System is fully operational.${NC}"
  elif [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠ Some warnings detected. Services may still be starting up.${NC}"
    echo -e "${YELLOW}Wait a few minutes and run this check again.${NC}"
  else
    echo -e "${RED}✗ Some health checks failed. Review errors above.${NC}"
    echo -e "${RED}Check logs and troubleshoot issues.${NC}"
    return 1
  fi
  echo "============================================================"
  echo ""
}

print_access_info() {
  local deployment="$1"

  echo ""
  echo "============================================================"
  echo "  Access Information"
  echo "============================================================"

  if [ "$deployment" = "minikube" ]; then
    local minikube_ip=$(minikube ip 2>/dev/null || echo "localhost")
    echo ""
    echo "Services are accessible at:"
    echo "  Matrix Hub:         http://$minikube_ip:30081"
    echo "  Matrix AI:          http://$minikube_ip:30083"
    echo "  Matrix Guardian:    http://$minikube_ip:30082"
    echo "  Matrix Architect:   http://$minikube_ip:30084"
    echo "  Matrix Treasury:    http://$minikube_ip:30086"
    echo "  Hub Admin UI:       http://$minikube_ip:30089"
    echo "  Network Portal:     http://$minikube_ip:30088"
    echo "  A2A Validator:      http://$minikube_ip:30090"
    echo ""
    echo "Get full service list: minikube service list -n matrix"
    echo ""
  elif [ "$deployment" = "docker-compose" ]; then
    echo ""
    echo "Services are accessible at:"
    echo "  Matrix AI:          http://localhost:7860"
    echo "  Matrix Guardian:    http://localhost:8001"
    echo "  Ollama (if enabled): http://localhost:11434"
    echo ""
    echo "View logs: docker compose logs -f"
    echo "View status: docker compose ps"
    echo ""
  fi

  echo "============================================================"
  echo ""
}

main() {
  echo "============================================================"
  echo "  Agent-Matrix Infrastructure Health Check"
  echo "============================================================"

  local deployment="$DEPLOYMENT_TYPE"

  if [ "$deployment" = "auto" ]; then
    deployment=$(auto_detect)
    echo -e "${BLUE}Auto-detected deployment type: $deployment${NC}"
  fi

  case "$deployment" in
    minikube)
      check_minikube_health
      ;;
    docker-compose)
      check_docker_compose_health
      ;;
    *)
      echo -e "${RED}Unable to detect deployment type.${NC}"
      echo "Usage: $0 [minikube|docker-compose]"
      exit 1
      ;;
  esac

  print_summary
  print_access_info "$deployment"
}

main "$@"
