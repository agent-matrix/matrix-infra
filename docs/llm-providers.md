# Configuring LLM Providers for Matrix AI

Matrix AI delegates plan generation to large language models (LLMs).  The
service supports multiple providers and falls back automatically if the first
provider fails【498656601227435†L500-L522】.  To run Matrix AI you must define
several environment variables; this document explains your options.

## Provider cascade

The planning microservice uses a configurable cascade.  By default it tries
providers in the order specified by the `PROVIDER_ORDER` variable.  For each
provider you must supply API keys and model names via environment variables.

### Supported providers

| Provider | Required variables | Example value |
|---------|--------------------|---------------|
| **Groq** | `GROQ_API_KEY`, `GROQ_MODEL` | `llama3-70b-8192` |
| **Gemini** | `GOOGLE_API_KEY`, `GEMINI_MODEL` | `gemini-pro` |
| **HuggingFace** | `HF_TOKEN`, `HF_MODEL` | `mistralai/Mistral-7B-Instruct-v0.2` |
| **Ollama** | `OLLAMA_HOST`, `OLLAMA_MODEL` | `http://ollama:11434`, `llama3` |

Set `PROVIDER_ORDER` to a comma‑separated list of provider names (e.g.
`groq,gemini,huggingface,ollama`).  The service will try each provider in
sequence.

## Minimum configuration

At minimum you must set `PROVIDER_ORDER` and `ADMIN_TOKEN`.  If you are using
only one provider, it should appear first in `PROVIDER_ORDER` and the others
can be omitted.

Example `.env` for Groq + Gemini:

```bash
PROVIDER_ORDER="groq,gemini"
GROQ_API_KEY="sk-groq-..."
GROQ_MODEL="llama3-70b-8192"
GOOGLE_API_KEY="sk-gemini-..."
GEMINI_MODEL="gemini-pro"
ADMIN_TOKEN="super-secret-token"
```

## Running with Ollama only

If you prefer not to rely on external APIs, you can run a local model using
[Ollama](https://ollama.ai/).  Ollama provides an HTTP API and can host models
such as **llama3** or **mistral** locally.  To use Ollama:

1. Install Ollama on the host where Matrix AI runs and start it:

   ```bash
   # see https://ollama.ai for installation
   ollama serve
   ollama pull llama3
   ```

2. Set the following environment variables in your `.env`:

   ```bash
   PROVIDER_ORDER="ollama"
   OLLAMA_HOST="http://localhost:11434"  # or service name if running in K8s
   OLLAMA_MODEL="llama3"
   ADMIN_TOKEN="super-secret-token"
   ```

When running in Kubernetes, include `platforms/minikube/ollama.yaml` which
deploys an Ollama pod and service, and set `OLLAMA_HOST` to
`http://ollama:11434`.

## Admin token and security

`ADMIN_TOKEN` is used by Matrix AI and Matrix Guardian for authentication
between services.  Choose a long, random string and set it in all services that
need to talk to Matrix AI.  Do **not** expose this token publicly.

## Additional providers

Adding a new provider is as simple as defining additional variables (e.g.
`OPENAI_API_KEY` and `OPENAI_MODEL`) and including the provider name in
`PROVIDER_ORDER`.  Refer to the `matrix-ai` repository for the exact variable
names and supported models【498656601227435†L500-L522】.