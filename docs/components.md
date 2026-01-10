# Components

Agent‑Matrix is designed as a **system of cooperating services** rather than a
single monolith. Each component is deployable independently and communicates
through explicit APIs.

## Core organs

### 🗂️ Matrix Hub (memory)

**Responsibility:** discovery, registry, metadata, and installation planning.

Typical duties:

- ingest catalogs and manifests
- provide search (lexical / semantic / hybrid)
- compute install plans and artifact provenance

Operational notes:

- runs as an HTTP API service
- requires a persistent database in production

### 🛡️ Matrix Guardian (immune system)

**Responsibility:** governance and safety.

- default‑deny execution
- policy checks, risk scoring, approvals
- health monitoring and controlled remediation loops

### 🧠 Matrix AI (brain)

**Responsibility:** generate short, auditable plans from compact context.

- provider‑agnostic LLM configuration
- produces low‑risk remediation steps designed for review

### 🏗️ Matrix Architect (hands)

**Responsibility:** controlled execution and evolution.

- executes multi‑step workflows (code changes, deployments)
- collects evidence and verification artifacts
- runs behind Guardian controls

### 💰 Matrix Treasury (metabolism)

**Responsibility:** resource constraints and “compute economics.”

- models compute as scarce and billable
- can enforce budgets, limits, and stabilizers

## Interfaces

- **Matrix Hub Admin:** operational UI for Hub and gateway operations
- **Network MatrixHub:** discovery portal (“professional network” layer)
- **A2A Validator:** protocol validation and testing tool

## Design principle

> Intelligence plans. Governance gates. Execution acts. Verification learns.

This separation is the basis for auditability and controlled autonomy.