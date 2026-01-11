##
## Matrix-Infra — reference deployment for the Agent-Matrix alive system
##
## Targets are written to support reproducible, auditable workflows.
## Use `make help` to discover commands.
##

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# Optional: override where upstream repos are cloned for local builds
CLONE_DIR ?= builds

# --- Internal Python Script for Linting ---
define LINT_SCRIPT
import glob, sys, yaml
paths = glob.glob('apps/**/*.yaml', recursive=True) + glob.glob('platforms/**/*.yaml', recursive=True)
bad = 0
for p in paths:
    with open(p, 'r', encoding='utf-8') as f:
        try:
            list(yaml.safe_load_all(f))
        except Exception as e:
            bad += 1
            print(f"YAML error in {p}: {e}")
print("OK" if bad==0 else f"FAILED: {bad} files")
sys.exit(0 if bad==0 else 1)
endef
export LINT_SCRIPT
# ------------------------------------------

.PHONY: help build install install-minikube install-oracle deploy deploy-minikube deploy-docker-compose preflight health-check generate-secrets docs-serve docs-build lint

help: ## Show a Matrix-style command reference
	@echo "\n🧬  Matrix-Infra — Alive System Infrastructure"
	@echo "======================================================="
	@echo "Purpose: reproducible infrastructure to run and study governed, long-lived AI systems."
	@echo "Scope:   Kubernetes overlays (MiniKube/K3s) + VM deployments (Oracle/Compose) + CI builds."
	@echo "Note:    This repository is not a commercial product; it is an open reference implementation."
	@echo "\nCommands:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo "\nQuick Start:"
	@echo "  make preflight             # check system requirements"
	@echo "  make deploy-minikube       # deploy to MiniKube (recommended for local dev)"
	@echo "  make health-check          # verify deployment"
	@echo ""
	@echo "Examples:"
	@echo "  make generate-secrets      # generate production secrets"
	@echo "  make deploy-docker-compose # deploy to Docker Compose"
	@echo "  make docs-serve            # serve docs locally"
	@echo ""

build: ## Build all container images needed by the platform (local Docker)
	@CLONE_DIR="$(CLONE_DIR)" bash scripts/build_all.sh

install: ## Interactive installer (choose MiniKube or Oracle)
	@bash scripts/install.sh

install-minikube: ## Validate deps, start MiniKube if needed, deploy manifests
	@bash scripts/setup_minikube.sh

install-oracle: ## Deploy services on an Oracle VM (Docker Compose)
	@cd platforms/oracle/compose && docker compose pull && docker compose up -d

deploy: ## One-command deployment (interactive, choose platform)
	@bash scripts/deploy.sh

deploy-minikube: ## One-command deployment to MiniKube with checks
	@bash scripts/deploy.sh minikube

deploy-docker-compose: ## One-command deployment to Docker Compose with checks
	@bash scripts/deploy.sh docker-compose

preflight: ## Run pre-flight environment checks
	@bash scripts/preflight-check.sh

health-check: ## Run health checks on deployed services
	@bash scripts/health-check.sh

generate-secrets: ## Generate production-ready secrets
	@bash scripts/generate-secrets.sh secrets.env

docs-serve: ## Serve documentation locally (requires mkdocs)
	@mkdocs serve

docs-build: ## Build the static docs site into ./site (requires mkdocs)
	@mkdocs build --strict

lint: ## Lightweight checks for YAML formatting and obvious manifest issues
	@echo "Running basic lint checks…"
	@python3 -c "$$LINT_SCRIPT"