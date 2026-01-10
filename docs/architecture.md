# Agent‑Matrix Architecture

Agent‑Matrix is described as the first **alive, governed, super‑intelligent AI
ecosystem** for enterprises.  Rather than a single monolithic application it is
a **network of cooperating services**, each with a clear responsibility.  The
system continuously discovers agents and tools, reasons about goals and
failures, enforces policies, executes plans and learns from outcomes, forming
a self‑healing loop【739971841502895†L540-L556】.

## Core Components

The architecture can be summarised as follows:

| Service           | Role                                                        |
|------------------|------------------------------------------------------------|
| **Matrix Hub**     | Acts as the **memory** and catalogue for the ecosystem.  It ingests manifests from remote registries, validates metadata, indexes agents/tools and provides a search and installer API【739971841502895†L540-L556】.  Hub also computes install plans and (optionally) registers agents with an MCP gateway. |
| **Matrix Guardian** | Serves as the **immune system**.  It monitors the health of MCP servers, scores risk, enforces policies, sandboxes untrusted workloads and orchestrates human‑in‑the‑loop approvals【123520983733261†L409-L516】.  Guardian calls Matrix AI to generate remediation plans when failures occur. |
| **Matrix AI**       | Provides the **brain**.  Given a health context (goal, failure or opportunity) it generates a structured, auditable plan using a multi‑provider LLM cascade and strict schema validation【498656601227435†L420-L439】.  The default port is `7860`. |
| **Matrix Architect** | Represents the **hands**.  It takes plans produced by Matrix AI and executes complex workflows such as code modifications, infrastructure changes, and deployments, all under policy control【701743904111646†L616-L658】.  It uses Celery, Redis and Postgres under the hood. |
| **Matrix Treasury**  | Implements the **metabolism**.  It meters resource usage (compute, energy) and enforces an internal currency (MXU) for agents, supporting multiple currencies and chains.  Environment variables include RPC URLs, private keys and LLM API keys【582129584042370†L268-L286】. |
| **Matrix System**    | Provides SDKs, CLI and dashboards for humans to interact with the system.  The CLI and Python SDK point to Matrix Hub, AI and Guardian URLs via environment variables【284889755730163†L494-L504】. |
| **Network MatrixHub**| A portal similar to “LinkedIn for AI agents” where agents/tools can be discovered, compared and recruited【939868318427343†L468-L518】. |
| **Matrix Hub Admin** | A React/Next.js admin UI for operating Matrix Hub and the MCP gateway. |
| **A2A Validator**    | A small FastAPI app used to validate A2A protocol compliance by agents【421230682955318†L43-L67】. |

### Alive Loop

The alive system runs in a continuous loop:

1. **Register & discover** – Agents and tools are registered via Matrix Hub.  Users and services can search and install them.
2. **Reason & plan** – When a goal or failure is detected, Matrix AI generates a plan to achieve or remediate it.
3. **Govern** – Matrix Guardian evaluates the plan against safety policies and risk thresholds; human approval may be required.
4. **Fund** – Matrix Treasury checks economic viability (MXU balances) and approves resource allocation.
5. **Execute** – Matrix Architect executes the plan, interacting with code repositories, infrastructure, or MCP agents under strict controls.
6. **Verify & learn** – Outcomes are logged and indexed back into Matrix Hub.  New knowledge improves future planning.

## Deployment Considerations

The Agent‑Matrix ecosystem is designed to be cloud‑agnostic.  Each service is
containerised and can be deployed using Docker Compose (for small
installations), Kubernetes (for scale) or serverless platforms.  Services
communicate over HTTP/HTTPS and rely on environment variables to locate each
other.  The most important variables for each service include:

| Service     | Key environment variables |
|-------------|--------------------------|
| **Matrix Hub**   | `DATABASE_URL` (Postgres or SQLite), `MATRIX_REMOTES` (catalogs), `MCP_GATEWAY_URL`, `MCP_GATEWAY_TOKEN`, `INGEST_INTERVAL_MIN`, search backend settings (Elasticsearch/Postgres)【148301433309205†L0-L69】. |
| **Matrix Guardian** | `DATABASE_URL`, `MATRIXHUB_API_BASE`, `MATRIX_AI_BASE`, `API_TOKEN`, autopilot controls such as `AUTOPILOT_ENABLED`, `AUTOPILOT_INTERVAL_SEC`【123520983733261†L409-L516】. |
| **Matrix AI**     | `PROVIDER_ORDER`, `GROQ_API_KEY`, `GOOGLE_API_KEY`, `HF_TOKEN`, `ADMIN_TOKEN`, and model names.  Supports local Ollama via `OLLAMA_HOST` (see `docs/llm-providers.md`). |
| **Matrix Architect** | `REDIS_URL`, `DATABASE_URL`, `JWT_SECRET`, `MATRIX_HUB_URL`, `MATRIX_GUARDIAN_URL`, `MATRIX_AI_URL`, feature flags (`SANDBOX_ENABLED`, `SCAN_ENABLED`)【103705995859538†L0-L28】. |
| **Matrix Treasury**  | RPC endpoints (`BASE_RPC_URL`, `POLYGON_RPC_URL`, etc.), `ADMIN_PRIVATE_KEY`, LLM API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `WATSONX_API_KEY`, `OLLAMA_HOST`), `ADMIN_ENCRYPTION_KEY`, `DATABASE_URL`【582129584042370†L268-L286】. |

Detailed environment examples can be found in the `.env.example` files under
each service repository and in `platforms/oracle/compose/.env.example`.