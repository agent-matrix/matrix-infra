#!/usr/bin/env bash

# This interactive installer helps you deploy the Agent‑Matrix stack
# locally on MiniKube/K3s or on an Oracle Cloud VM using Docker
# Compose.  It guides you through selecting a deployment target and
# executes the corresponding commands.  See docs/quickstart-local-minikube.md
# and docs/quickstart-oracle.md for more details on each option.

set -euo pipefail

die() {
  echo "Error: $1" >&2
  exit 1
}

print_header() {
  echo "============================================================"
  echo " Agent‑Matrix Interactive Installer"
  echo "============================================================"
  echo
}

print_menu() {
  echo "Select an installation type:"
  echo "  1) Local development (MiniKube/K3s)"
  echo "  2) Oracle VM (Docker Compose)"
  echo "  3) Exit"
  echo
}

install_minikube() {
  echo "\n[+] Installing on MiniKube/K3s..."
  # Ensure kubectl is available
  if ! command -v kubectl >/dev/null 2>&1; then
    die "kubectl is not installed or not in PATH"
  fi
  # Create namespace if it does not exist
  kubectl create namespace matrix --dry-run=client -o yaml | kubectl apply -f -
  # Set current context namespace
  kubectl config set-context --current --namespace=matrix
  # Apply kustomization
  kubectl apply -k platforms/minikube
  echo "\n[✓] Deployment started on your local cluster.  Use 'kubectl get pods -n matrix' to check status."
}

install_oracle() {
  echo "\n[+] Installing on Oracle VM with Docker Compose..."
  local compose_dir="platforms/oracle/compose"
  if [ ! -d "$compose_dir" ]; then
    die "Cannot find $compose_dir"
  fi
  cd "$compose_dir"
  # Ensure .env exists
  if [ ! -f .env ]; then
    echo "\n[!] It looks like you have not created a .env file yet."
    echo "    Please copy .env.example to .env and fill in the required values before continuing."
    exit 1
  fi
  # Pull latest images and start the stack
  docker compose pull
  docker compose up -d
  echo "\n[✓] Services started.  Use 'docker compose ps' to see running containers."
}

main() {
  print_header
  while true; do
    print_menu
    read -rp "Enter your choice [1-3]: " choice
    case "$choice" in
      1)
        install_minikube
        break
        ;;
      2)
        install_oracle
        break
        ;;
      3)
        echo "Bye."
        exit 0
        ;;
      *)
        echo "Invalid choice: $choice"
        ;;
    esac
  done
}

main "$@"