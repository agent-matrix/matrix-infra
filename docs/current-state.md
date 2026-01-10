# Current State of Deployment

As of **January 2026** the Agent‑Matrix ecosystem has only a subset of
components deployed in production.  This document records what is live today
and what remains to be rolled out.

## Live Services

| Service         | Location | Notes |
|-----------------|----------|-------|
| **Matrix Hub**     | Oracle Cloud VM #1 | A production instance of Matrix Hub is running on a single Oracle Arm VM.  It serves as the central catalog and installer for agents/tools.  Traffic is exposed via HTTPS on the default port.  Environment variables are configured to point at a PostgreSQL database on a separate VM. |
| **PostgreSQL**    | Oracle Cloud VM #2 | A managed Postgres 16 instance used by Matrix Hub.  The credentials are stored in the Oracle secret store. |
| **Catalog & Network Portals** | n/a | The public catalog (GitHub repo) and the Network MatrixHub portal are hosted statically (GitHub Pages/Cloudflare Pages). |

## Pending Deployment

The following services are **not yet deployed** and must be provisioned either on
Oracle VMs or via Kubernetes (MiniKube in development, K8s in production):

- **Matrix Guardian** – the governance and health monitoring service.  Should
  run close to Matrix Hub for low latency and will need its own database
  (Postgres).  Connects to the Matrix Hub API (`MATRIXHUB_API_BASE`) and
  Matrix AI (`MATRIX_AI_BASE`).
- **Matrix AI** – the reasoning/planning microservice.  Requires LLM
  provider credentials (e.g. Groq, Gemini, HuggingFace or local
  Ollama) and may need GPU resources depending on model choice【498656601227435†L420-L439】.
- **Matrix Architect** – the execution layer for applying remediation plans,
  including code patches and infrastructure changes【701743904111646†L616-L658】.  It
  depends on Celery, Redis and a Postgres database.
- **Matrix Treasury** – the economic runtime.  Not critical for the
  first production release but required for complete autonomy.  Requires
  blockchain RPC endpoints and secret keys【582129584042370†L268-L286】.
- **Matrix Hub Admin** and **Network MatrixHub** UIs – web portals for
  administrators and users.  Can be hosted via Cloudflare Pages or on the
  same VM as the API services.
- **A2A Validator** – a developer tool for testing agents.  Useful in
  integration environments but not needed on production.

## Roadmap

| Phase       | Description |
|-------------|-------------|
| **Phase 1** | Deploy **Matrix AI** and **Matrix Guardian** on a single Oracle
VM (using Docker Compose) and connect them to the existing Matrix Hub
instance.  Configure Cloudflare Zero Trust tunnels for secure
connectivity and set up GitHub Actions for continuous deployment. |
| **Phase 2** | Add **Matrix Architect** and optional UIs (Hub Admin,
Network MatrixHub).  Evaluate whether to run Matrix Hub locally in
development (MiniKube) for end‑to‑end tests. |
| **Phase 3** | Introduce **Matrix Treasury** and migrate to a full
Kubernetes cluster.  At this stage, services run under K3s/K8s with
helm/kustomize, and the LLM provider can be swapped (e.g. on‑prem GPUs
replacing hosted services). |

The remainder of this repository contains the manifests and instructions to
realise these phases.