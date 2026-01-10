# Oracle Deployment Guide

This folder contains everything you need to run the missing Agent‑Matrix services
on an Oracle Cloud VM using Docker Compose.  The services assume that
**Matrix Hub** and the main **PostgreSQL** database are already running on other
hosts (see `docs/current-state.md`).

## Files

| File                 | Purpose |
|----------------------|---------|
| `docker-compose.yml` | Defines the `matrix-ai`, `matrix-guardian` and optional `ollama` services.  Reads configuration from `.env`. |
| `.env.example`       | Template environment variables.  Copy to `.env` and edit. |
| `deploy.sh`          | Script used by CI to pull images and restart services. |

## Usage

1. **Copy the environment template**:

   ```bash
   cp .env.example .env
   nano .env  # edit values
   ```

2. **Start the services**:

   ```bash
   docker compose up -d
   ```

   This pulls the images and runs `matrix-ai` on port 7860 and
   `matrix-guardian` on port 8001.  If `AUTOPILOT_ENABLED` is set to `true` in
   `.env`, Guardian will periodically probe the Matrix Hub and call Matrix AI to
   remediate issues【123520983733261†L409-L516】.

3. **(Optional) Setup Cloudflare Tunnel**:  To avoid exposing these ports
   directly on the public internet you can create a Cloudflare Zero Trust
   tunnel.  Map subdomains (e.g. `ai.example.com` and `guardian.example.com`) to
   the local ports 7860 and 8001.  Then update `MATRIX_AI_BASE` and
   `MATRIXHUB_API_BASE` in your `.env` accordingly and restart the services.

4. **(Optional) Continuous deployment**:  The GitHub Actions workflow in
   `.github/workflows/deploy-oracle.yml` can be configured to SSH into your VM
   and execute `deploy.sh` after new images are pushed.  Populate the
   repository secrets `ORACLE_HOST`, `ORACLE_USER` and `ORACLE_KEY` to enable
   this.

## Notes

- For small installations you can leave `GUARDIAN_DATABASE_URL` set to
  `sqlite:///data/guardian.db`.  For reliability and concurrency use a Postgres
  instance instead and update the variable accordingly.
- If you do not want to run a local Ollama server, set `PROVIDER_ORDER` to
  another provider (e.g. `groq,gemini`) and provide the corresponding API
  keys.  See `docs/llm-providers.md` for examples.
- To add more services (e.g. Matrix Architect, Matrix Treasury), extend
  `docker-compose.yml` in the same pattern.