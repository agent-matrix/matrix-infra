# Roadmap

Matrix‑Infra evolves alongside Agent‑Matrix. The intent is to move from
"it runs" to "it runs reliably under audit".

## Near‑term (0–3 months)

- Publish pinned multi‑arch images for all core services via CI (GHCR/Docker Hub)
- Add Kubernetes health probes and sensible resource defaults across manifests
- Replace NodePorts with Ingress defaults and tighten network exposure
- Document a minimal observability baseline (logs, metrics, tracing)

## Mid‑term (3–6 months)

- Helm charts (or OCI Helm) as an alternative to raw Kustomize overlays
- External secrets integration (e.g., SOPS, External Secrets Operator)
- Supply‑chain hardening (SBOMs, signing, provenance)
- Reference deployment on a managed Kubernetes cluster

## Longer‑term

- Policy‑as‑code library and reusable governance packs
- Multi‑cluster patterns (edge + central control plane)
- Production incident runbooks and automated rollback hooks

Roadmaps change; the guiding constraint is that governance and auditability
remain first‑class.
