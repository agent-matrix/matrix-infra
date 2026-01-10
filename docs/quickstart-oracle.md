# Quickstart: Deploying on Oracle Cloud

This guide walks you through deploying the missing Agent‑Matrix services on
Oracle Cloud using lightweight Arm VMs (Oracle “Always Free” tier) together with
Docker Compose and GitHub Actions for continuous deployment.  It assumes you
already have **Matrix Hub** and **PostgreSQL** running on separate Oracle VMs
(see `docs/current-state.md`).

## Overview

In the production v1 architecture we deploy only the services that are not
already running on Oracle:

| Service            | Deployment approach |
|-------------------|---------------------|
| **Matrix AI**        | Runs as a Docker container on an Oracle VM.  Requires LLM
  provider configuration or a local Ollama instance.  Exposes port `7860` to
  internal network only. |
| **Matrix Guardian**  | Runs as a Docker container on the same VM.  Uses its own
  Postgres database (can be SQLite for minimal setup).  Listens on port
  `8001`. |
| **Matrix Architect** | (Optional) Runs on its own VM or on the same host; uses
  Redis and Postgres. |
| **Matrix Treasury**   | (Optional) Not required for the first release. |

We use **Cloudflare Zero Trust** to create secure, private tunnels to the
services.  This avoids opening inbound ports on the VM.  You can also assign a
public IP to the VM and restrict access via security lists if preferred.

## Steps

1. **Provision a VM**: Use the Oracle Cloud console to create an Always Free
   Arm A1 VM (for example `2 OCPU / 12 GB RAM`).  Install Docker and Git.
2. **Clone this repository** onto the VM:

   ```bash
   sudo apt update && sudo apt install -y git docker docker-compose
   sudo usermod -aG docker $USER
   git clone https://github.com/agent-matrix/matrix-infra.git
   cd matrix-infra/platforms/oracle/compose
   ```

3. **Copy the environment template** and fill in the required variables:

   ```bash
   cp .env.example .env
   nano .env  # or your favourite editor
   ```

   At minimum you must provide:

   - `MATRIXHUB_API_BASE` – URL of the existing Matrix Hub instance (e.g.
     `https://hub.example.com`).
   - `DATABASE_URL` – Postgres connection string for Matrix Guardian (you can
     set this to `sqlite:///guardian.db` for a quick start).
   - `PROVIDER_ORDER` and API keys for Matrix AI.  See `docs/llm-providers.md`.
   - `ADMIN_TOKEN` – a secret token used by Matrix AI and Guardian for
     authentication.

4. **Start the services** using Docker Compose:

   ```bash
   docker compose pull
   docker compose up -d
   ```

   This will launch Matrix AI and Matrix Guardian containers on the VM.  Logs
   can be viewed with `docker compose logs -f`.

5. **Create Cloudflare tunnels (recommended)**.  Follow Cloudflare’s Zero Trust
   documentation to create a tunnel and point subdomains at your services.  For
   example:

   - `ai.myorg.example` → local port 7860 (Matrix AI)
   - `guardian.myorg.example` → local port 8001 (Matrix Guardian)

   Update your `.env` accordingly (e.g. `MATRIX_AI_BASE` pointing at the
   Cloudflare URL) and restart the services.

6. **Automate deployments with GitHub Actions**.  The workflow
   `.github/workflows/deploy-oracle.yml` builds new images and executes
   `deploy.sh` via SSH whenever changes are pushed to the `main` branch.  To use
   it you must add the following secrets to your GitHub repository:

   - `ORACLE_HOST` – IP or hostname of the Oracle VM
   - `ORACLE_USER` – SSH user
   - `ORACLE_KEY` – private SSH key

   The workflow logs into the VM, pulls the latest container images, and
   restarts the services.

## Notes

- **Matrix Guardian database** – Using SQLite in production is acceptable for
  small installations but Postgres is recommended for reliability.  You can
  deploy Postgres as a Docker container on the same VM or provision a free
  managed instance.
- **Matrix AI provider selection** – For a fully offline deployment you can run
  an Ollama server (see `docs/llm-providers.md`) on another VM or on your
  workstation.  Set `OLLAMA_HOST` in `.env` and leave the other API keys
  empty.
- **Scaling** – When the workload grows you can move to a Kubernetes cluster
  using the manifests in `platforms/minikube` as a starting point.  Oracle
  Container Engine for Kubernetes (OKE) or any managed K8s provider will
  support these manifests.