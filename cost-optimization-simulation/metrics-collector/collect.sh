#!/bin/bash
# Metrics Collection Script
# Collects CPU, memory, and container metrics from Docker containers

set -e

OUTPUT_DIR="${1:-./metrics_output}"
DURATION_SECONDS="${2:-3600}"  # Default 1 hour
INTERVAL_SECONDS="${3:-10}"     # Collect every 10 seconds

# Services to monitor (from docker-compose.yml)
SERVICES=(
    "api-gateway"
    "user-service"
    "driver-service"
    "trip-service"
    "matching-service"
    "notification-service"
)

mkdir -p "$OUTPUT_DIR"

echo "Starting metrics collection..."
echo "Output directory: $OUTPUT_DIR"
echo "Duration: $DURATION_SECONDS seconds"
echo "Interval: $INTERVAL_SECONDS seconds"
echo "Services: ${SERVICES[*]}"
echo ""

# Create output files
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
METRICS_FILE="$OUTPUT_DIR/metrics-$TIMESTAMP.json"
DOCKER_STATS_FILE="$OUTPUT_DIR/docker-stats-$TIMESTAMP.csv"

# Initialize JSON structure
cat > "$METRICS_FILE" <<EOF
{
  "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "duration_seconds": $DURATION_SECONDS,
  "interval_seconds": $INTERVAL_SECONDS,
  "services": {}
}
EOF

# Function to collect metrics for a service
collect_service_metrics() {
    local service=$1
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Check if container is running
    if ! docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
        echo "  ⚠️  Container $service is not running"
        return
    fi
    
    # Get container stats (one-time snapshot)
    local stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" "$service" 2>/dev/null || echo "0,0/0,0")
    
    # Parse CPU percentage
    local cpu_perc=$(echo "$stats" | cut -d',' -f1 | sed 's/%//')
    
    # Parse memory (format: "100MiB / 1GiB")
    local mem_usage=$(echo "$stats" | cut -d',' -f2)
    local mem_used=$(echo "$mem_usage" | cut -d'/' -f1 | sed 's/[^0-9.]//g')
    local mem_unit=$(echo "$mem_usage" | cut -d'/' -f1 | sed 's/[0-9.]//g' | tr -d ' ')
    
    # Convert to GB
    local mem_gb=0
    case "$mem_unit" in
        "KiB") mem_gb=$(echo "$mem_used / 1048576" | bc -l) ;;
        "MiB") mem_gb=$(echo "$mem_used / 1024" | bc -l) ;;
        "GiB") mem_gb=$mem_used ;;
        *) mem_gb=0 ;;
    esac
    
    # Get container resource limits
    local cpu_limit=$(docker inspect "$service" --format '{{.HostConfig.CpuQuota}}' 2>/dev/null || echo "0")
    local mem_limit=$(docker inspect "$service" --format '{{.HostConfig.Memory}}' 2>/dev/null || echo "0")
    
    # Convert CPU quota to cores (if set)
    local cpu_cores=0.5  # Default
    if [ "$cpu_limit" != "0" ] && [ -n "$cpu_limit" ]; then
        cpu_cores=$(echo "scale=2; $cpu_limit / 100000" | bc -l)
    fi
    
    # Convert memory limit to GB
    local mem_limit_gb=1.0  # Default
    if [ "$mem_limit" != "0" ] && [ -n "$mem_limit" ]; then
        mem_limit_gb=$(echo "scale=2; $mem_limit / 1073741824" | bc -l)
    fi
    
    # Output JSON entry
    cat >> "$METRICS_FILE.tmp" <<EOF
    "$timestamp": {
      "service": "$service",
      "cpu_percent": $cpu_perc,
      "cpu_cores": $cpu_cores,
      "memory_used_gb": $mem_gb,
      "memory_limit_gb": $mem_limit_gb,
      "memory_percent": $(echo "$stats" | cut -d',' -f3 | sed 's/%//')
    },
EOF
    
    # Also log to CSV for easy analysis
    echo "$timestamp,$service,$cpu_perc,$cpu_cores,$mem_gb,$mem_limit_gb" >> "$DOCKER_STATS_FILE"
}

# Collect initial state
echo "Collecting initial metrics..."
for service in "${SERVICES[@]}"; do
    collect_service_metrics "$service"
done

# Main collection loop
START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION_SECONDS))
ITERATION=0

echo ""
echo "Collecting metrics every $INTERVAL_SECONDS seconds..."
echo "Press Ctrl+C to stop early"
echo ""

while [ $(date +%s) -lt $END_TIME ]; do
    ITERATION=$((ITERATION + 1))
    ELAPSED=$(($(date +%s) - START_TIME))
    REMAINING=$((END_TIME - $(date +%s)))
    
    printf "\r[%d/%d] Elapsed: %ds, Remaining: %ds" "$ITERATION" "$((DURATION_SECONDS / INTERVAL_SECONDS))" "$ELAPSED" "$REMAINING"
    
    # Collect metrics for all services
    for service in "${SERVICES[@]}"; do
        collect_service_metrics "$service" >> /dev/null 2>&1
    done
    
    sleep "$INTERVAL_SECONDS"
done

echo ""
echo ""
echo "Metrics collection completed!"

# Finalize JSON file
if [ -f "$METRICS_FILE.tmp" ]; then
    # Remove trailing comma and close JSON
    sed -i '$ s/,$//' "$METRICS_FILE.tmp"
    
    # Merge into main file
    python3 <<PYTHON_SCRIPT
import json
import sys

with open("$METRICS_FILE", 'r') as f:
    data = json.load(f)

# Read collected metrics
with open("$METRICS_FILE.tmp", 'r') as f:
    metrics_content = f.read()

# Parse and add metrics
data["collected_metrics"] = json.loads("{" + metrics_content + "}")
data["end_time"] = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
data["total_samples"] = $ITERATION

with open("$METRICS_FILE", 'w') as f:
    json.dump(data, f, indent=2)

print(f"Metrics saved to $METRICS_FILE")
PYTHON_SCRIPT

    rm "$METRICS_FILE.tmp"
fi

echo "Metrics saved to:"
echo "  - $METRICS_FILE (JSON)"
echo "  - $DOCKER_STATS_FILE (CSV)"
echo ""
echo "Next step: Run parse-metrics.py to process the collected data"
