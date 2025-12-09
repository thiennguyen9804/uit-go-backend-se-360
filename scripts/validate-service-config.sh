#!/bin/bash
# Script để validate service.yml configuration

set -euo pipefail

SERVICE_CONFIG="${1:-service.yml}"

if [ ! -f "$SERVICE_CONFIG" ]; then
  echo "❌ Error: Service config not found: $SERVICE_CONFIG"
  exit 1
fi

echo "🔍 Validating service configuration: $SERVICE_CONFIG"
echo ""

ERRORS=0

# Check if yq is available
if ! command -v yq &> /dev/null; then
  echo "⚠️  yq not found, installing..."
  sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  sudo chmod +x /usr/local/bin/yq
fi

# Validate required fields
validate_field() {
  local field=$1
  local value=$(yq eval "$field" "$SERVICE_CONFIG" 2>/dev/null || echo "null")
  
  if [ "$value" = "null" ] || [ -z "$value" ]; then
    echo "❌ Missing required field: $field"
    ERRORS=$((ERRORS + 1))
    return 1
  fi
  return 0
}

# Validate service name
SERVICE_NAME=$(yq eval '.service.name' "$SERVICE_CONFIG" 2>/dev/null || echo "")
if [ -z "$SERVICE_NAME" ] || [ "$SERVICE_NAME" = "null" ]; then
  echo "❌ service.name is required"
  ERRORS=$((ERRORS + 1))
else
  # Validate name format (lowercase, no spaces, alphanumeric and hyphens only)
  if [[ ! "$SERVICE_NAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "❌ service.name must be lowercase, alphanumeric with hyphens only"
    ERRORS=$((ERRORS + 1))
  fi
fi

# Validate required fields
validate_field '.service.build.language'
validate_field '.service.runtime.port'

# Validate port is a number
PORT=$(yq eval '.service.runtime.port' "$SERVICE_CONFIG" 2>/dev/null || echo "")
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  echo "❌ service.runtime.port must be a number"
  ERRORS=$((ERRORS + 1))
fi

# Validate CPU values
CPU=$(yq eval '.service.runtime.cpu' "$SERVICE_CONFIG" 2>/dev/null || echo "0.5")
if ! [[ "$CPU" =~ ^(0\.25|0\.5|1\.0|1\.5|2\.0)$ ]]; then
  echo "⚠️  Warning: service.runtime.cpu should be one of: 0.25, 0.5, 1.0, 1.5, 2.0"
fi

# Validate memory format
MEMORY=$(yq eval '.service.runtime.memory' "$SERVICE_CONFIG" 2>/dev/null || echo "1.0Gi")
if ! [[ "$MEMORY" =~ ^[0-9]+(\.[0-9]+)?(Gi|Mi)$ ]]; then
  echo "⚠️  Warning: service.runtime.memory should be in format: 1.0Gi or 512Mi"
fi

# Validate replicas
MIN_REPLICAS=$(yq eval '.service.runtime.min_replicas' "$SERVICE_CONFIG" 2>/dev/null || echo "0")
MAX_REPLICAS=$(yq eval '.service.runtime.max_replicas' "$SERVICE_CONFIG" 2>/dev/null || echo "3")

if ! [[ "$MIN_REPLICAS" =~ ^[0-9]+$ ]] || ! [[ "$MAX_REPLICAS" =~ ^[0-9]+$ ]]; then
  echo "❌ service.runtime.min_replicas and max_replicas must be numbers"
  ERRORS=$((ERRORS + 1))
fi

if [ "$MIN_REPLICAS" -gt "$MAX_REPLICAS" ]; then
  echo "❌ service.runtime.min_replicas ($MIN_REPLICAS) cannot be greater than max_replicas ($MAX_REPLICAS)"
  ERRORS=$((ERRORS + 1))
fi

# Validate language
LANGUAGE=$(yq eval '.service.build.language' "$SERVICE_CONFIG" 2>/dev/null || echo "")
VALID_LANGUAGES=("maven" "dotnet" "node" "python" "go")
if [[ ! " ${VALID_LANGUAGES[@]} " =~ " ${LANGUAGE} " ]]; then
  echo "⚠️  Warning: service.build.language '$LANGUAGE' not in recommended list: ${VALID_LANGUAGES[*]}"
fi

# Check Dockerfile exists
DOCKERFILE=$(yq eval '.service.build.dockerfile' "$SERVICE_CONFIG" 2>/dev/null || echo "Dockerfile")
SERVICE_DIR=$(dirname "$SERVICE_CONFIG")
if [ ! -f "$SERVICE_DIR/$DOCKERFILE" ]; then
  echo "⚠️  Warning: Dockerfile not found: $SERVICE_DIR/$DOCKERFILE"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "✅ Service configuration is valid!"
  exit 0
else
  echo "❌ Found $ERRORS error(s). Please fix and try again."
  exit 1
fi

