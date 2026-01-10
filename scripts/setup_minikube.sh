#!/usr/bin/env bash

# Setup script for local MiniKube/K3s environment
#
# This script checks for required dependencies (docker, kubectl, kustomize,
# minikube), attempts to start a MiniKube cluster if necessary, and
# deploys the Agent‑Matrix stack using the manifests in this repository.
#
# It is designed for Ubuntu/Debian systems but prints installation
# suggestions for other platforms.  Run this script as a normal user;
# certain commands may prompt for sudo privileges when installing
# packages or starting services.

set -euo pipefail

BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
GREEN="\033[1;32m"
NC="\033[0m"

header() {
  echo -e "${BLUE}\n=== $1 ===${NC}"
}

check_dep() {
  local cmd="$1"
  local install_msg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${YELLOW}Dependency '$cmd' is not installed.${NC}"
    echo -e "${YELLOW}$install_msg${NC}"
    return 1
  fi
  return 0
}

main() {
  header "Checking dependencies"
  local missing=0
  check_dep docker "Install Docker. On Ubuntu: 'sudo apt-get update && sudo apt-get install -y docker.io'" || missing=1
  check_dep kubectl "Install kubectl. See https://kubernetes.io/docs/tasks/tools/#kubectl" || missing=1
  # kubectl includes kustomize via 'kubectl kustomize'
  check_dep minikube "Install minikube. See https://minikube.sigs.k8s.io/docs/start/" || missing=1
  if [ "$missing" -eq 1 ]; then
    echo -e "\n${RED}One or more dependencies are missing.  Please install them and re-run this script.${NC}"
    exit 1
  fi

  header "Starting MiniKube"
  # Start MiniKube if not already running
  if ! minikube status >/dev/null 2>&1; then
    echo "MiniKube is not running. Starting with default resources (4 CPUs, 8GB RAM)..."
    minikube start --cpus=4 --memory=8192
  else
    echo "MiniKube is already running."
  fi

  header "Deploying Agent‑Matrix manifests"
  # Use kubectl with Kustomize to deploy
  kubectl create namespace matrix --dry-run=client -o yaml | kubectl apply -f -
  kubectl config set-context --current --namespace=matrix
  kubectl apply -k platforms/minikube
  echo -e "\n${GREEN}Deployment initiated.  Use 'kubectl get pods -n matrix' to monitor status.${NC}"
}

main "$@"