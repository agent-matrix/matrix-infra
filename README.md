<p align="center">
  <img src="https://raw.githubusercontent.com/agent-matrix/.github/refs/heads/main/profile/logo.png" alt="Agent-Matrix Logo" width="180">
</p>

<h1 align="center">Matrix-Infra</h1>

<p align="center">
  <strong>Open infrastructure to deploy, operate, and study governed, long-lived (“alive”) AI systems.</strong>
</p>

<p align="center">
  <a href="https://www.apache.org/licenses/LICENSE-2.0">
    <img alt="License" src="https://img.shields.io/badge/License-Apache%202.0-blue" />
  </a>
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Kubernetes%20%7C%20Docker%20Compose-informational" />
  <img alt="Focus" src="https://img.shields.io/badge/Focus-Governance%20%7C%20Auditability%20%7C%20Reproducibility-success" />
</p>

---

## What this repository is

**Matrix-Infra** is the **deployment and operations reference** for the Agent-Matrix ecosystem.

Its purpose is to make *alive AI systems* practical to **run, inspect, govern, and evolve** in real environments.  
This repository does not define new algorithms or models; it defines **how a complex, long-running AI system is assembled and operated safely**.

Matrix-Infra focuses on:

- Continuous, long-lived operation (not one-shot pipelines)
- Governance-first autonomy with human oversight
- Explicit, auditable infrastructure and configuration
- Reproducible deployments across local and cloud environments
- Clear separation of responsibilities between system components

### Important positioning

This is an **open-source infrastructure and research project**.

It is **not a commercial product**, **not a hosted service**, and **not marketed for sale**.  
The intent is to provide a **serious, public reference implementation** for building and operating *alive* AI systems in a disciplined, inspectable way.

---

## What “alive” means in this context

An *alive* AI system is not simply an inference endpoint or a workflow runner.  
It is a governed, continuously operating system that can:

1. Discover agents, tools, and capabilities dynamically  
2. Reason and plan based on goals, failures, and system state  
3. Make decisions under explicit policy and risk constraints  
4. Execute actions with controlled automation and approvals  
5. Verify outcomes and retain reusable knowledge over time  

Agent-Matrix decomposes these responsibilities into specialized services, each with a clearly defined role and trust boundary.

---

## Core components (high level)

Matrix-Infra orchestrates the deployment of the following services:

| Component | Responsibility in the alive loop | Primary repository |
|---------|----------------------------------|--------------------|
| **Matrix Hub** | Catalog, registry, discovery, install plans (“system memory”) | `agent-matrix/matrix-hub` |
| **Matrix Guardian** | Governance, policy enforcement, approvals, health monitoring | `agent-matrix/matrix-guardian` |
| **Matrix AI** | Planning, remediation, and reasoning | `agent-matrix/matrix-ai` |
| **Matrix Architect** | High-risk execution, system evolution, controlled automation | `agent-matrix/matrix-architect` |
| **Matrix Treasury** | Resource accounting and economic constraints | `agent-matrix/matrix-treasury` |
| **Admin UI & Network** | Operational visibility and agent discovery | `matrix-hub-admin`, `network.matrixhub` |

Matrix-Infra does not redefine these services; it **codifies how they are built, deployed, and operated coherently**.

---

## Deployment targets

Matrix-Infra supports two complementary deployment modes.

### Local full stack (MiniKube / K3s)

Intended for:

- end-to-end development
- integration testing
- architecture exploration
- governance and safety experiments

Characteristics:

- Kubernetes manifests with Kustomize overlays
- Optional local LLM inference using Ollama
- No external cloud dependencies required

### Cost-effective cloud deployment (Oracle VM + CI)

Intended for:

- early production-like environments
- long-running validation
- CI-driven image builds

Characteristics:

- Docker Compose for operational simplicity
- GitHub Actions for reproducible image builds (GHCR / Docker Hub)
- Designed to evolve toward full Kubernetes clusters later

---

## Quickstart

### Local (MiniKube)

Prerequisites:

- Docker
- kubectl
- minikube
- kustomize

Deploy the full stack locally:

```bash
make install-minikube
````

See: `docs/quickstart-local-minikube.md`

### Oracle VM (Docker Compose)

```bash
make install-oracle
```

See: `docs/quickstart-oracle.md`

---

## Developer workflows

Matrix-Infra provides structured workflows for operators and contributors:

* `make help` — discover available commands and workflows
* `make build` — build all Agent-Matrix container images locally
* `scripts/install.sh` — interactive installer (local vs cloud)
* `scripts/setup_minikube.sh` — dependency checks and local setup

The goal is to reduce ambiguity and make system behavior reproducible.

---

## Documentation (MkDocs)

This repository includes a **MkDocs** configuration and a professional documentation skeleton.

* Serve documentation locally:

```bash
mkdocs serve
```

* Build static documentation:

```bash
mkdocs build
```

Documentation covers architecture, deployment, governance, and roadmap.
See `mkdocs.yml` and the `docs/` directory.

---

## Security and auditability principles

Matrix-Infra is structured for environments where inspection and control matter:

* Explicit configuration (no hidden runtime defaults)
* Clear separation of concerns between services
* Least-privilege networking and secret scopes
* Reproducible builds via CI workflows
* Human-in-the-loop enforcement by default

This repository should be reviewed and treated as **infrastructure code**.

---

## Repository layout

```text
matrix-infra/
  apps/                 # Kubernetes manifests per service
  platforms/            # Environment overlays (minikube, oracle)
  scripts/              # Install and build helpers
  docs/                 # MkDocs content and operational guides
  todo/                 # Known gaps and hardening checklist
```

---

## Contributing

Matrix-Infra is an open research and infrastructure effort.

High-value contributions include:

* hardening Kubernetes overlays
* improving security defaults
* strengthening CI reproducibility
* clarifying audit trails and runbooks
* improving documentation clarity

---

## License

Apache-2.0 (unless a sub-repository states otherwise).


