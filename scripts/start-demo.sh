#!/bin/bash
# Launch Claude Code with Databricks-managed Claude endpoint
# Usage: ./scripts/start-demo.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Find .env file
ENV_FILE=""
if [ -f "$PROJECT_DIR/.env" ]; then
  ENV_FILE="$PROJECT_DIR/.env"
elif [ -f "$SCRIPT_DIR/.env" ]; then
  ENV_FILE="$SCRIPT_DIR/.env"
elif [ -f ".env" ]; then
  ENV_FILE=".env"
fi

if [ -z "$ENV_FILE" ]; then
  echo "Error: .env file not found."
  echo "Copy .env.example to .env and fill in your values."
  exit 1
fi

# Load env vars
set -a
source "$ENV_FILE"
set +a

echo "Starting Claude Code with Databricks AI Dev Kit..."
echo "  Workspace: $ANTHROPIC_BASE_URL"
echo "  Model:     $ANTHROPIC_MODEL"
echo ""
claude
