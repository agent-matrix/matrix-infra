# Governance & Safety Model

Matrix‑Infra treats governance as a **first‑class operational requirement**.
This is essential for any system that can plan and execute actions in the world.

## Principles

### Default‑deny execution

The platform is designed so that **nothing executes by default** without an
explicit policy decision.

### Human‑in‑the‑loop by default

For higher‑risk operations, approvals are expected and auditable.

### Separable controls

Safety checks are not baked into every component ad hoc. Instead, **Matrix
Guardian centralizes control policies** and enforces them consistently.

## What to audit

When assessing a deployment, reviewers typically inspect:

- the policy decision points (what can execute, under what conditions)
- secret boundaries and service identity
- network exposure (ingress, nodeports, tunnels)
- evidence artifacts (logs, plan outputs, approvals)

## Recommended hardening

- use Kubernetes Secrets (or external secret managers) for all credentials
- run sensitive services behind private networking
- enable structured logging and retention
- treat CI workflows and container supply chain as part of the security surface

> Governance is not a feature; it is the operating posture.
