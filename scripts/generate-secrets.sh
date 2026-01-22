#!/usr/bin/env bash

# Generate production-ready secrets for Agent-Matrix deployment
# This script creates secure random values for all required secrets
# Usage:
#   ./generate-secrets.sh [output-file]
#
# If output-file is not specified, secrets are printed to stdout
# For Kubernetes: Use kubectl to create secrets from generated values
# For Docker Compose: Append to .env file or use as environment variables

set -euo pipefail

# Colors for output
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Generate a random hex string
generate_hex() {
  local length=${1:-32}
  openssl rand -hex "$length"
}

# Generate a base64 encoded random string
generate_base64() {
  local length=${1:-32}
  openssl rand -base64 "$length" | tr -d '\n'
}

# Generate an alphanumeric token
generate_token() {
  local length=${1:-64}
  LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

main() {
  local output_file="${1:-}"

  echo -e "${BLUE}Generating production-ready secrets...${NC}" >&2

  # Generate all secrets
  local admin_token=$(generate_token 64)
  local jwt_secret=$(generate_hex 32)
  local admin_private_key=$(generate_base64 32)
  local admin_encryption_key=$(generate_hex 32)
  local mcp_gateway_token=$(generate_token 64)
  local network_secret_key=$(generate_hex 32)
  local nextauth_secret=$(generate_hex 32)

  # Build output
  local secrets=""
  secrets+="# Generated secrets for Agent-Matrix - $(date -u +"%Y-%m-%d %H:%M:%S UTC")\n"
  secrets+="# WARNING: Keep these values secret and secure!\n"
  secrets+="\n"
  secrets+="# Admin token for inter-service authentication\n"
  secrets+="ADMIN_TOKEN=${admin_token}\n"
  secrets+="\n"
  secrets+="# Compatibility aliases (same value) for hardened Matrix-Hub ecosystem\n"
  secrets+="# - MATRIX_HUB_TOKEN: used by CLI/SDK/operator tools\n"
  secrets+="# - HUB_API_TOKEN: used by matrix-hub-admin server-side proxy routes\n"
  secrets+="MATRIX_HUB_TOKEN=${admin_token}\n"
  secrets+="HUB_API_TOKEN=${admin_token}\n"
  secrets+="\n"
  secrets+="# Matrix-Hub expects API_TOKEN for admin endpoints (alias of ADMIN_TOKEN)\n"
  secrets+="API_TOKEN=${admin_token}\n"
  secrets+="\n"
  secrets+="# JWT secret for token signing\n"
  secrets+="JWT_SECRET=${jwt_secret}\n"
  secrets+="\n"
  secrets+="# Admin private key for encryption\n"
  secrets+="ADMIN_PRIVATE_KEY=${admin_private_key}\n"
  secrets+="\n"
  secrets+="# Admin encryption key\n"
  secrets+="ADMIN_ENCRYPTION_KEY=${admin_encryption_key}\n"
  secrets+="\n"
  secrets+="# MCP Gateway token (if using MCP gateway)\n"
  secrets+="MCP_GATEWAY_TOKEN=${mcp_gateway_token}\n"
  secrets+="\n"
  secrets+="# Network secret key for Network MatrixHub\n"
  secrets+="NETWORK_SECRET_KEY=${network_secret_key}\n"
  secrets+="\n"
  secrets+="# NextAuth secret for authentication\n"
  secrets+="NEXTAUTH_SECRET=${nextauth_secret}\n"
  secrets+="\n"
  secrets+="# LLM Provider API Keys (add your own values)\n"
  secrets+="GROQ_API_KEY=\n"
  secrets+="GOOGLE_API_KEY=\n"
  secrets+="HF_TOKEN=\n"
  secrets+="OPENAI_API_KEY=\n"
  secrets+="ANTHROPIC_API_KEY=\n"
  secrets+="WATSONX_API_KEY=\n"

  if [ -n "$output_file" ]; then
    echo -e "$secrets" > "$output_file"
    echo -e "${GREEN}✓ Secrets written to: $output_file${NC}" >&2
    echo -e "${YELLOW}⚠ Remember to add your LLM provider API keys to the file!${NC}" >&2
  else
    echo -e "$secrets"
  fi

  echo -e "\n${BLUE}For Kubernetes deployment:${NC}" >&2
  echo -e "${YELLOW}kubectl create secret generic matrix-secrets --from-env-file=$output_file -n matrix${NC}" >&2

  echo -e "\n${BLUE}For Docker Compose deployment:${NC}" >&2
  echo -e "${YELLOW}cat $output_file >> platforms/oracle/compose/.env${NC}" >&2
}

main "$@"
