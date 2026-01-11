# Quickstart: Running the full stack on MiniKube

This guide explains how to run **all core Agent‑Matrix services locally** using
MiniKube (or K3s).  Running the entire ecosystem on your own machine is
essential for development, testing and experimentation, especially when you
want to exercise the alive loop end‑to‑end without relying on remote
infrastructure.

## Prerequisites

1. **MiniKube** or **K3s** installed locally.  See
   <https://minikube.sigs.k8s.io/docs/start/> for installation instructions.
2. **kubectl** and **kustomize** installed.  `kubectl kustomize` is included
   with modern versions of kubectl.
3. **Docker** running locally – MiniKube will create its own Docker context.
4. (Optional) **Ollama** for local LLM inference.  If you do not have API keys
   for Groq/Gemini/HuggingFace and want to use a local model, install
   [Ollama](https://ollama.ai/) and start the service on `127.0.0.1:11434`.

## Steps

1. **Clone this repository** and navigate into it:

   ```bash
   git clone https://github.com/agent-matrix/matrix-infra.git
   cd matrix-infra
   ```

2. **Start MiniKube** with enough resources.  The full stack requires
   at least 4 CPU cores and 8 GB of memory:

   ```bash
   minikube start --cpus=4 --memory=8192
   ```

3. **Prepare a namespace** and apply the kustomization:

   ```bash
   kubectl create namespace matrix || true
   kubectl config set-context --current --namespace=matrix
   kubectl apply -k platforms/minikube
   ```

   The `kustomization.yaml` in `platforms/minikube` references the manifests
   under `apps/` for each service.  It will deploy:

   - Matrix Hub (optional – comment out if you prefer to connect to the remote
     production hub).
   - Matrix Guardian and its Postgres instance.
   - Matrix AI.
   - Matrix Architect and its dependencies (Redis, Celery workers).
   - Matrix Treasury (optional, see below).
   - Matrix UIs (Hub Admin, Network portal) and A2A Validator.
   - Ollama (if enabled via `platforms/minikube/ollama.yaml`).

4. **Wait for pods to become ready**.  You can watch their status with:

   ```bash
   kubectl get pods -w
   ```

5. **Access the services**.  For development convenience the manifests use
   `NodePort` services that expose high ports on the MiniKube VM.  To find the
   URLs run:

   ```bash
   minikube service list
   ```

   Example default ports:

   - Matrix Hub: 30081 (API)
   - Matrix Guardian: 30082
   - Matrix AI: 30083
   - Matrix Architect API: 30084, UI: 30085
   - Matrix Treasury API: 30086, UI: 30087
   - Network portal UI: 30088
   - Hub Admin UI: 30089
   - A2A Validator: 30090

   These ports are configurable in the `apps/*/deployment.yaml` files.

6. **Configure the Matrix System SDK/CLI**.  When using the `matrix-system` SDK
   in development you will need to point it at your local services.  For
   example:

   ```bash
   # Install the SDK
   pip install matrix-system

   # Configure environment
   export MATRIX_HUB_URL="http://$(minikube ip):30081"
   export MATRIX_AI_URL="http://$(minikube ip):30083"
   export MATRIX_GUARDIAN_URL="http://$(minikube ip):30082"
   export ADMIN_TOKEN="your-admin-token"

   # Test connectivity
   matrix health check --all
   ```

   **See:** [Matrix System SDK Documentation](matrix-system-sdk.md) for complete usage guide.

## LLM Provider configuration

By default the Matrix AI deployment references a ConfigMap named
`matrix-ai-config` (created by the kustomization) that sets `PROVIDER_ORDER`
and model names.  To use a hosted LLM provider (e.g. Groq, Gemini, HuggingFace)
create a Kubernetes secret named `matrix-ai-secrets` in the `matrix` namespace
with your API keys:

```bash
kubectl create secret generic matrix-ai-secrets \
  --from-literal=GROQ_API_KEY=sk-your-groq-key \
  --from-literal=GOOGLE_API_KEY=sk-your-gemini-key \
  --from-literal=HF_TOKEN=hf-your-hf-token \
  --from-literal=ADMIN_TOKEN=admin-secret
```

Alternatively, if you installed **Ollama** and want to run LLMs locally, set
`OLLAMA_HOST` to `http://ollama:11434` in the ConfigMap and include
`platforms/minikube/ollama.yaml` in your deployment (see the comments in
`platforms/minikube/kustomization.yaml`).  See `docs/llm-providers.md` for
details.

## Optional services

- **Matrix Treasury** and **Matrix Architect** are resource intensive.  For
  simple development you may comment out their references in
  `platforms/minikube/kustomization.yaml` until needed.
- **UI applications** (Hub Admin, Network portal) can also be removed or
  replaced with your own front‑end.  They default to port `30089` and
  `30088` respectively.

You now have a fully working Agent‑Matrix ecosystem running locally on
MiniKube.  Consult the other docs for production deployment guidance.