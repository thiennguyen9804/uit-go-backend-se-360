#!/bin/bash
# K6 Test Runner Wrapper
# Runs k6 tests and collects performance metrics

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$PROJECT_ROOT/test/main-flow"
OUTPUT_DIR="${1:-./k6-results}"

mkdir -p "$OUTPUT_DIR"

echo "Running k6 tests..."
echo "Test directory: $TEST_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

cd "$TEST_DIR"

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "Error: k6 is not installed"
    echo "Install from: https://k6.io/docs/getting-started/installation/"
    exit 1
fi

# Check if test file exists
TEST_FILE="user-booking-test.ts"
if [ ! -f "$TEST_FILE" ]; then
    echo "Error: Test file not found: $TEST_FILE"
    exit 1
fi

# Run k6 test
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/k6-summary-$TIMESTAMP.json"

echo "Starting k6 test..."
echo "Results will be saved to: $OUTPUT_FILE"
echo ""

# Run k6 with JSON output
k6 run \
    --out json="$OUTPUT_FILE" \
    --summary-export="$OUTPUT_FILE" \
    "$TEST_FILE"

echo ""
echo "K6 test completed!"
echo "Results saved to: $OUTPUT_FILE"
echo ""

# Also generate human-readable summary
SUMMARY_FILE="$OUTPUT_DIR/k6-summary-$TIMESTAMP.txt"
k6 run --summary "$TEST_FILE" > "$SUMMARY_FILE" 2>&1 || true

echo "Summary saved to: $SUMMARY_FILE"
echo ""

# Extract key metrics using Python
python3 <<PYTHON_SCRIPT
import json
import sys

try:
    with open("$OUTPUT_FILE", 'r') as f:
        data = json.load(f)
    
    metrics = data.get('metrics', {})
    
    print("Key Metrics:")
    print("=" * 50)
    
    # HTTP requests
    http_reqs = metrics.get('http_reqs', {})
    if http_reqs:
        print(f"Total Requests: {http_reqs.get('values', {}).get('count', 0)}")
        print(f"Request Rate: {http_reqs.get('values', {}).get('rate', 0):.2f} req/s")
    
    # Duration
    http_req_duration = metrics.get('http_req_duration', {})
    if http_req_duration:
        values = http_req_duration.get('values', {})
        print(f"Avg Duration: {values.get('avg', 0):.2f} ms")
        print(f"P95 Duration: {values.get('p(95)', 0):.2f} ms")
        print(f"P99 Duration: {values.get('p(99)', 0):.2f} ms")
    
    # Errors
    errors = metrics.get('errors', {})
    if errors:
        error_rate = errors.get('values', {}).get('rate', 0)
        print(f"Error Rate: {error_rate * 100:.2f}%")
    
    # Custom metrics
    booking_success = metrics.get('successful_bookings', {})
    if booking_success:
        print(f"Successful Bookings: {booking_success.get('values', {}).get('count', 0)}")
    
    accept_success = metrics.get('successful_accepts', {})
    if accept_success:
        print(f"Successful Accepts: {accept_success.get('values', {}).get('count', 0)}")
    
    print("=" * 50)
    
except Exception as e:
    print(f"Error parsing results: {e}", file=sys.stderr)
PYTHON_SCRIPT

echo ""
echo "Test run completed successfully!"
