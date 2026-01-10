# Matrix‑Infra

Matrix‑Infra is the **open deployment and operations reference** for the
Agent‑Matrix ecosystem.

It exists to make an **alive AI system** operationally real: deployable,
inspectable, governed, and evolvable.

## What “alive” means

An *alive* system is not just an inference endpoint. It is a long‑running,
policy‑governed feedback loop that can:

1. **Discover** tools/agents and capabilities
2. **Plan** from goals, incidents, and opportunities
3. **Gate execution** under policy (risk, approvals, permissions)
4. **Act** through controlled automation
5. **Verify** outcomes and **learn** (reuse)

This repo provides the “wiring” that lets those organs run together.

## Two deployment tracks

- **Local (MiniKube/K3s):** run the full stack for end‑to‑end development and
  integration testing.
- **Cloud (Oracle VM + Compose):** run the stack on lightweight compute while
  CI builds and publishes container images.

## Audience

This documentation is intentionally written for a **balanced audience**:

- **Researchers & architects** who want clear system boundaries and concepts
- **Platform engineers** who need repeatable, auditable deployments
- **Security reviewers** evaluating governance and operational posture

Next: read the **Architecture** pages or go straight to **Deployment**.
