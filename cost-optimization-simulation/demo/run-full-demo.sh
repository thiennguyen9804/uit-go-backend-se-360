#!/bin/bash
# Full Demo Automation Script
# Orchestrates the entire cost comparison demo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SIMULATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
DURATION_SECONDS="${1:-3600}"  # Default 1 hour
COLLECTION_INTERVAL=10
RESULTS_DIR="$SIMULATION_DIR/results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cost Optimization Demo - Full Run${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Configuration:"
echo "  Duration: $DURATION_SECONDS seconds ($(echo "scale=2; $DURATION_SECONDS/3600" | bc) hours)"
echo "  Collection Interval: $COLLECTION_INTERVAL seconds"
echo "  Results Directory: $RESULTS_DIR"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Step 1: Check prerequisites
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker installed"

# Check docker-compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: docker-compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} docker-compose available"

# Check k6
if ! command -v k6 &> /dev/null; then
    echo -e "${YELLOW}⚠ Warning: k6 is not installed${NC}"
    echo "  Install from: https://k6.io/docs/getting-started/installation/"
    echo "  Demo will continue but k6 tests will be skipped"
    SKIP_K6=true
else
    echo -e "${GREEN}✓${NC} k6 installed"
    SKIP_K6=false
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Python 3 installed"

# Check Python packages
echo "Checking Python packages..."
python3 -c "import yaml" 2>/dev/null || { echo -e "${YELLOW}⚠ Installing pyyaml...${NC}"; pip3 install pyyaml --quiet; }
python3 -c "import matplotlib" 2>/dev/null || { echo -e "${YELLOW}⚠ Installing matplotlib...${NC}"; pip3 install matplotlib --quiet; }
echo -e "${GREEN}✓${NC} Python packages ready"
echo ""

# Step 2: Start infrastructure
echo -e "${YELLOW}[2/7] Starting local infrastructure...${NC}"
cd "$PROJECT_ROOT"

# Check if services are already running
if docker ps --format "{{.Names}}" | grep -q "api-gateway"; then
    echo -e "${YELLOW}⚠ Services already running, skipping docker-compose up${NC}"
else
    echo "Starting services with docker-compose..."
    docker-compose up -d
    echo "Waiting for services to be healthy..."
    sleep 30
fi

# Verify services are running
SERVICES=("api-gateway" "user-service" "driver-service" "trip-service" "matching-service" "notification-service")
ALL_RUNNING=true
for service in "${SERVICES[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
        echo -e "${GREEN}✓${NC} $service is running"
    else
        echo -e "${RED}✗${NC} $service is NOT running"
        ALL_RUNNING=false
    fi
done

if [ "$ALL_RUNNING" = false ]; then
    echo -e "${RED}Error: Some services are not running${NC}"
    exit 1
fi
echo ""

# Step 3: Start metrics collection in background
echo -e "${YELLOW}[3/7] Starting metrics collection...${NC}"
METRICS_OUTPUT="$RESULTS_DIR/metrics-$TIMESTAMP"
"$SIMULATION_DIR/metrics-collector/collect.sh" "$METRICS_OUTPUT" "$DURATION_SECONDS" "$COLLECTION_INTERVAL" &
METRICS_PID=$!
echo "Metrics collection started (PID: $METRICS_PID)"
echo ""

# Step 4: Run k6 tests
if [ "$SKIP_K6" = false ]; then
    echo -e "${YELLOW}[4/7] Running k6 load tests...${NC}"
    K6_OUTPUT="$RESULTS_DIR/k6-$TIMESTAMP"
    "$SIMULATION_DIR/workload-runner/run-k6-tests.sh" "$K6_OUTPUT" || {
        echo -e "${YELLOW}⚠ K6 tests had issues, continuing...${NC}"
    }
    echo ""
else
    echo -e "${YELLOW}[4/7] Skipping k6 tests (not installed)${NC}"
    echo ""
fi

# Step 5: Wait for metrics collection to complete
echo -e "${YELLOW}[5/7] Waiting for metrics collection to complete...${NC}"
wait $METRICS_PID
echo -e "${GREEN}✓${NC} Metrics collection completed"
echo ""

# Step 6: Parse metrics and calculate costs
echo -e "${YELLOW}[6/7] Processing metrics and calculating costs...${NC}"

# Find the latest metrics file
METRICS_FILE=$(find "$METRICS_OUTPUT" -name "metrics-*.json" | sort | tail -1)
if [ -z "$METRICS_FILE" ]; then
    echo -e "${RED}Error: No metrics file found${NC}"
    exit 1
fi

echo "Parsing metrics from: $METRICS_FILE"
PARSED_METRICS="$RESULTS_DIR/parsed-metrics-$TIMESTAMP.json"
"$SIMULATION_DIR/metrics-collector/parse-metrics.py" "$METRICS_FILE" "$PARSED_METRICS"

# Get actual duration from parsed metrics
ACTUAL_DURATION=$(python3 -c "import json; f=open('$PARSED_METRICS'); d=json.load(f); print(d['duration_seconds'])")

echo "Comparing scenarios..."
COMPARISON_RESULT="$RESULTS_DIR/comparison-$TIMESTAMP.json"
"$SIMULATION_DIR/comparison/compare-scenarios.py" "$PARSED_METRICS" "$ACTUAL_DURATION" "$COMPARISON_RESULT"
echo -e "${GREEN}✓${NC} Cost comparison completed"
echo ""

# Step 7: Generate report
echo -e "${YELLOW}[7/7] Generating final report...${NC}"
REPORT_DIR="$RESULTS_DIR/report-$TIMESTAMP"
mkdir -p "$REPORT_DIR"
"$SIMULATION_DIR/comparison/generate-report.py" "$COMPARISON_RESULT" "$REPORT_DIR"
echo -e "${GREEN}✓${NC} Report generated"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Demo Completed Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Results:"
echo "  - Metrics: $METRICS_OUTPUT"
echo "  - Parsed Metrics: $PARSED_METRICS"
echo "  - Comparison: $COMPARISON_RESULT"
echo "  - Report: $REPORT_DIR/comparison-report.md"
echo "  - Charts: $REPORT_DIR/*.png"
echo ""
echo "Next steps:"
echo "  1. Review the report: $REPORT_DIR/comparison-report.md"
echo "  2. Check the charts in: $REPORT_DIR/"
echo "  3. Analyze cost differences and recommendations"
echo ""

# Display quick summary
echo "Quick Summary:"
python3 <<PYTHON_SCRIPT
import json
import sys

try:
    with open("$COMPARISON_RESULT", 'r') as f:
        data = json.load(f)
    
    comparison = data['comparison']
    platforms = data['platforms']
    
    print(f"  Cheapest Platform: {comparison['cheapest_platform']}")
    print(f"  Cheapest Cost: \${comparison['cheapest_cost']:.4f}")
    print("")
    print("  Platform Costs:")
    for key, platform_data in platforms.items():
        name = platform_data['platform']
        cost = platform_data['total_cost']
        monthly = platform_data['monthly_projection']['projected_monthly_cost']
        print(f"    {name}: \${cost:.4f} (Monthly: \${monthly:.2f})")
    
except Exception as e:
    print(f"  Error displaying summary: {e}")
PYTHON_SCRIPT

echo ""
echo -e "${GREEN}Demo completed!${NC}"
