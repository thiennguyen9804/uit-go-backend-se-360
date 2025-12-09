#!/bin/bash
# Script để check health của service sau khi deploy

set -euo pipefail

SERVICE_NAME=$1
RESOURCE_GROUP=${2:-"rg-self-service-example"}
MAX_RETRIES=${3:-30}
RETRY_INTERVAL=${4:-10}

if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: ./scripts/health-check.sh <service-name> [resource-group] [max-retries] [retry-interval]"
  exit 1
fi

echo "🏥 Health Check for service: $SERVICE_NAME"
echo "📋 Resource Group: $RESOURCE_GROUP"
echo ""

# Get service URL
SERVICE_URL=$(az containerapp show \
  --name "$SERVICE_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.configuration.ingress.fqdn" \
  -o tsv 2>/dev/null || echo "")

if [ -z "$SERVICE_URL" ]; then
  echo "❌ Service not found or not externally accessible"
  exit 1
fi

echo "🔗 Service URL: https://$SERVICE_URL"
echo ""

# Get health check path from service config
HEALTH_PATH="/actuator/health"
if [ -f "$SERVICE_NAME/service.yml" ]; then
  if command -v yq &> /dev/null; then
    HEALTH_PATH=$(yq eval '.service.runtime.health_check_path' "$SERVICE_NAME/service.yml" || echo "/actuator/health")
  fi
fi

HEALTH_URL="https://$SERVICE_URL$HEALTH_PATH"
echo "🏥 Health Check URL: $HEALTH_URL"
echo ""

# Retry logic
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
  echo "⏳ Attempt $((RETRY + 1))/$MAX_RETRIES..."
  
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$HEALTH_URL" || echo "000")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Service is healthy! (HTTP $HTTP_CODE)"
    exit 0
  elif [ "$HTTP_CODE" = "000" ]; then
    echo "⚠️  Service not responding (connection timeout)"
  else
    echo "⚠️  Service returned HTTP $HTTP_CODE"
  fi
  
  if [ $RETRY -lt $((MAX_RETRIES - 1)) ]; then
    echo "⏸️  Waiting ${RETRY_INTERVAL}s before retry..."
    sleep $RETRY_INTERVAL
  fi
  
  RETRY=$((RETRY + 1))
done

echo ""
echo "❌ Health check failed after $MAX_RETRIES attempts"
echo "💡 Check service logs:"
echo "   az containerapp logs show --name $SERVICE_NAME --resource-group $RESOURCE_GROUP --follow"
exit 1

