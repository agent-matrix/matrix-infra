# Operations & Deployment Notes

This page complements the quickstarts with **operator‑grade guidance**.

## Image strategy

You have two supported approaches:

1. **CI publishes images** (recommended): use GitHub Actions to build and push
   multi‑arch images to GHCR or Docker Hub.
2. **Local builds**: run `make build` and load images into MiniKube.

### Local image loading (MiniKube)

If you build locally, make sure MiniKube can see the images:

```bash
minikube image load agent-matrix/matrix-hub:latest
minikube image load agent-matrix/matrix-guardian:latest
minikube image load agent-matrix/matrix-ai:latest
```

## Configuration management

- Keep runtime config in **Kubernetes Secrets** and ConfigMaps.
- Avoid baking `.env` files or credentials into images.
- For production, prefer an external secret manager.

## Networking

- Use Ingress (or Cloudflare Tunnel) to expose only required services.
- Prefer private cluster networking for internal service communication.
- Avoid broad NodePort exposure for production.

## Persistence

Some services require persistence in production:

- PostgreSQL for Matrix Hub (and potentially other services)
- volume mounts for logs/artifacts as needed

For MiniKube, you can use hostPath or dynamic storage classes.

## Observability

Minimum recommended signals:

- structured logs (JSON)
- basic health endpoints and readiness/liveness probes
- request tracing / correlation IDs (where possible)

## Upgrade discipline

Treat upgrades like infrastructure changes:

- pin image tags in production
- roll forward with canary or staged deployment
- keep rollback procedures documented and tested

The aim is not only to run the system, but to run it in a way that is
**reviewable, repeatable, and safe**.
