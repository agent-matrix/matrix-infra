#!/usr/bin/env bash

# One-command deployment script for Agent-Matrix infrastructure
# Handles pre-flight checks, deployment, and post-deployment verification
# Usage: ./deploy.sh [minikube|docker-compose] [--skip-checks] [--skip-verify]

set -euo pipefail

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
BOLD="\033[1m"
NC="\033[0m"

DEPLOYMENT_TYPE=""
SKIP_CHECKS=false
SKIP_VERIFY=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: $0 [minikube|docker-compose] [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --skip-checks    Skip pre-flight checks"
  echo "  --skip-verify    Skip post-deployment health checks"
  echo "  --help           Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 minikube                    # Deploy to MiniKube with all checks"
  echo "  $0 docker-compose --skip-checks # Deploy to Docker Compose, skip pre-flight"
  echo ""
  exit 1
}

banner() {
  echo ""
  echo "============================================================"
  echo "  $1"
  echo "============================================================"
  echo ""
}

step() {
  echo -e "\n${BLUE}▶${NC} ${BOLD}$1${NC}\n"
}

success() {
  echo -e "${GREEN}✓${NC} $1"
}

error() {
  echo -e "${RED}✗${NC} $1" >&2
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

die() {
  error "$1"
  exit 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      minikube|docker-compose)
        DEPLOYMENT_TYPE="$1"
        shift
        ;;
      --skip-checks)
        SKIP_CHECKS=true
        shift
        ;;
      --skip-verify)
        SKIP_VERIFY=true
        shift
        ;;
      --help|-h)
        usage
        ;;
      *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
  done

  if [ -z "$DEPLOYMENT_TYPE" ]; then
    echo "Error: Deployment type required"
    echo ""
    usage
  fi
}

run_preflight_checks() {
  step "Running pre-flight checks..."

  if [ "$SKIP_CHECKS" = true ]; then
    warn "Skipping pre-flight checks (--skip-checks specified)"
    return 0
  fi

  if [ ! -x "$SCRIPT_DIR/preflight-check.sh" ]; then
    warn "Pre-flight check script not found or not executable, skipping..."
    return 0
  fi

  if ! "$SCRIPT_DIR/preflight-check.sh" "$DEPLOYMENT_TYPE"; then
    die "Pre-flight checks failed. Fix errors and try again, or use --skip-checks to bypass."
  fi

  success "Pre-flight checks passed"
}

deploy_minikube() {
  step "Deploying to MiniKube..."

  cd "$PROJECT_ROOT"

  # Check if minikube is running, start if not
  if ! minikube status >/dev/null 2>&1; then
    echo "MiniKube is not running. Starting with default resources (4 CPUs, 8GB RAM)..."
    minikube start --cpus=4 --memory=8192 || die "Failed to start MiniKube"
    success "MiniKube started"
  else
    success "MiniKube is already running"
  fi

  # Create namespace
  echo "Creating matrix namespace..."
  kubectl create namespace matrix --dry-run=client -o yaml | kubectl apply -f - || die "Failed to create namespace"
  success "Namespace created"

  # Set context
  echo "Setting kubectl context..."
  kubectl config set-context --current --namespace=matrix || die "Failed to set context"
  success "Context set to matrix namespace"

  # Apply kustomization
  echo "Applying Kubernetes manifests..."
  kubectl apply -k platforms/minikube || die "Failed to apply manifests"
  success "Manifests applied"

  # Wait for pods to be scheduled
  echo "Waiting for pods to be scheduled..."
  sleep 5

  success "MiniKube deployment complete!"

  # Show deployment info
  echo ""
  echo "Deployment started. Pods may take a few minutes to become ready."
  echo "Monitor status with: kubectl get pods -n matrix -w"
  echo ""
}

deploy_docker_compose() {
  step "Deploying with Docker Compose..."

  local compose_dir="$PROJECT_ROOT/platforms/oracle/compose"

  if [ ! -d "$compose_dir" ]; then
    die "Docker Compose directory not found: $compose_dir"
  fi

  cd "$compose_dir"

  # Check for .env file
  if [ ! -f .env ]; then
    warn ".env file not found"
    echo ""
    echo "Creating .env from .env.example..."
    if [ -f .env.example ]; then
      cp .env.example .env
      warn "Please edit platforms/oracle/compose/.env and configure your settings"
      echo ""
      read -p "Press Enter when you've configured the .env file, or Ctrl+C to abort..."
    else
      die ".env.example not found. Cannot proceed."
    fi
  else
    success ".env file found"
  fi

  # Determine compose command
  local compose_cmd="docker compose"
  if ! docker compose version >/dev/null 2>&1; then
    if command -v docker-compose >/dev/null 2>&1; then
      compose_cmd="docker-compose"
    else
      die "Docker Compose is not available"
    fi
  fi

  # Pull images
  echo "Pulling latest images..."
  $compose_cmd pull || die "Failed to pull images"
  success "Images pulled"

  # Start services
  echo "Starting services..."
  $compose_cmd up -d || die "Failed to start services"
  success "Services started"

  # Wait a moment for services to initialize
  echo "Waiting for services to initialize..."
  sleep 10

  success "Docker Compose deployment complete!"

  echo ""
  echo "Services are starting in the background."
  echo "Monitor logs with: docker compose logs -f"
  echo ""

  cd "$PROJECT_ROOT"
}

run_health_checks() {
  step "Running health checks..."

  if [ "$SKIP_VERIFY" = true ]; then
    warn "Skipping health checks (--skip-verify specified)"
    return 0
  fi

  if [ ! -x "$SCRIPT_DIR/health-check.sh" ]; then
    warn "Health check script not found or not executable, skipping..."
    return 0
  fi

  echo "Waiting 30 seconds for services to stabilize..."
  sleep 30

  if ! "$SCRIPT_DIR/health-check.sh" "$DEPLOYMENT_TYPE"; then
    warn "Some health checks failed or services are still starting up"
    echo ""
    echo "This is normal for first-time deployments. Services may take 2-5 minutes to become fully ready."
    echo "Run './scripts/health-check.sh $DEPLOYMENT_TYPE' again in a few minutes to verify."
    echo ""
    return 0
  fi

  success "Health checks passed"
}

print_next_steps() {
  banner "Deployment Complete!"

  echo "Next steps:"
  echo ""

  if [ "$DEPLOYMENT_TYPE" = "minikube" ]; then
    echo "1. Check pod status:"
    echo "   kubectl get pods -n matrix"
    echo ""
    echo "2. View service URLs:"
    echo "   minikube service list -n matrix"
    echo ""
    echo "3. Access Matrix Hub:"
    echo "   export MINIKUBE_IP=\$(minikube ip)"
    echo "   curl http://\$MINIKUBE_IP:30081"
    echo ""
    echo "4. Monitor logs:"
    echo "   kubectl logs -f deployment/matrix-hub -n matrix"
    echo ""
    echo "5. Run health check:"
    echo "   ./scripts/health-check.sh minikube"
    echo ""
  else
    echo "1. Check service status:"
    echo "   cd platforms/oracle/compose && docker compose ps"
    echo ""
    echo "2. View logs:"
    echo "   cd platforms/oracle/compose && docker compose logs -f"
    echo ""
    echo "3. Access services:"
    echo "   Matrix AI:       http://localhost:7860"
    echo "   Matrix Guardian: http://localhost:8001"
    echo ""
    echo "4. Run health check:"
    echo "   ./scripts/health-check.sh docker-compose"
    echo ""
  fi

  echo "For troubleshooting, see: todo/TROUBLESHOOTING.md"
  echo ""
}

main() {
  parse_args "$@"

  banner "Agent-Matrix Infrastructure Deployment"

  echo "Deployment type: ${BOLD}$DEPLOYMENT_TYPE${NC}"
  echo "Skip pre-flight: $SKIP_CHECKS"
  echo "Skip verification: $SKIP_VERIFY"
  echo ""

  run_preflight_checks

  case "$DEPLOYMENT_TYPE" in
    minikube)
      deploy_minikube
      ;;
    docker-compose)
      deploy_docker_compose
      ;;
    *)
      die "Unknown deployment type: $DEPLOYMENT_TYPE"
      ;;
  esac

  run_health_checks

  print_next_steps

  echo -e "${GREEN}${BOLD}Deployment successful!${NC}"
  echo ""
}

main "$@"
