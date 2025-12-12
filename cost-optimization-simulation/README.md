# Cost Optimization Simulation

Local simulation tool to compare costs across different Azure container platforms without deploying to cloud.

## Overview

This tool simulates and compares costs for:
- **Azure Container Apps (ACA)**: Serverless with scale-to-zero
- **Azure Container Instances (ACI)**: Simple container hosting
- **Azure Kubernetes Service (AKS)**: With Spot instances (70% discount) and On-Demand

## How It Works

1. **Run services locally** using Docker Compose
2. **Collect real metrics** (CPU, memory, request rates) from running containers
3. **Calculate costs** based on Azure pricing models and collected metrics
4. **Compare platforms** and generate detailed reports with charts

## Prerequisites

- Docker and docker-compose
- Python 3.8+
- k6 (for load testing) - [Installation Guide](https://k6.io/docs/getting-started/installation/)
- Python packages: `pyyaml`, `matplotlib`

## Quick Start

### 1. Install Dependencies

```bash
# Install Python packages
pip3 install pyyaml matplotlib

# Install k6 (if not already installed)
# Linux:
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D9
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

### 2. Run Full Demo

```bash
cd cost-optimization-simulation/demo
./run-full-demo.sh [duration_seconds]

# Example: Run for 1 hour (3600 seconds)
./run-full-demo.sh 3600
```

The script will:
1. Start all services using docker-compose
2. Collect metrics from containers
3. Run k6 load tests
4. Calculate costs for all platforms
5. Generate comparison report with charts

### 3. View Results

Results are saved in `results/` directory:
- `comparison-report.md`: Detailed markdown report
- `cost-comparison.png`: Cost comparison charts
- `cost-breakdown.png`: Cost breakdown by service

## Manual Steps

If you prefer to run steps manually:

### Step 1: Start Services

```bash
cd /path/to/project-root
docker-compose up -d
```

### Step 2: Collect Metrics

```bash
cd cost-optimization-simulation/metrics-collector
./collect.sh ./metrics_output 3600 10
# Collects metrics for 3600 seconds (1 hour), every 10 seconds
```

### Step 3: Run Load Tests

```bash
cd cost-optimization-simulation/workload-runner
./run-k6-tests.sh ./k6-results
```

### Step 4: Parse Metrics

```bash
cd cost-optimization-simulation/metrics-collector
python3 parse-metrics.py metrics_output/metrics-*.json parsed-metrics.json
```

### Step 5: Compare Scenarios

```bash
cd cost-optimization-simulation/comparison
python3 compare-scenarios.py ../metrics-collector/parsed-metrics.json 3600 comparison-results.json
```

### Step 6: Generate Report

```bash
cd cost-optimization-simulation/comparison
python3 generate-report.py comparison-results.json ./reports
```

## Project Structure

```
cost-optimization-simulation/
├── cost-calculator/
│   ├── pricing-models.py    # Azure pricing models
│   ├── simulator.py         # Cost calculation engine
│   └── config.yaml          # Pricing configuration
├── metrics-collector/
│   ├── collect.sh           # Collect Docker metrics
│   └── parse-metrics.py     # Parse and aggregate metrics
├── workload-runner/
│   └── run-k6-tests.sh      # K6 test runner wrapper
├── comparison/
│   ├── compare-scenarios.py # Compare all platforms
│   └── generate-report.py   # Generate markdown + charts
├── demo/
│   └── run-full-demo.sh     # Full automation script
└── results/                 # Generated results (gitignored)
```

## Configuration

Edit `cost-calculator/config.yaml` to adjust:
- Azure pricing (if prices change)
- Default resource allocations
- AKS node pool configuration
- Cost calculation assumptions

## Understanding Results

### Cost Breakdown

The report shows:
- **Test Period Cost**: Actual cost for the test duration
- **Monthly Projection**: Estimated monthly cost based on test results
- **Cost per Service**: Breakdown showing which services cost the most

### Platform Comparison

- **Cheapest Platform**: Lowest cost option for your workload
- **Savings**: How much you save vs other platforms
- **Trade-offs**: Performance vs cost considerations

### Recommendations

The report includes recommendations on:
- Which platform is best for your workload
- When to use each platform
- Cost optimization strategies

## Methodology

### Metrics Collection
- Collects CPU and memory usage from Docker containers every 10 seconds
- Tracks container lifecycle (start/stop) for scale-to-zero calculations
- Records request rates from k6 tests

### Cost Calculation
- **ACA**: Pay-per-use with scale-to-zero (no cost when idle)
- **ACI**: Per-second billing, less efficient scaling
- **AKS Spot**: 70% discount on compute, but includes control plane cost
- **AKS On-Demand**: Full price, guaranteed availability

### Assumptions
- Pricing based on Azure pricing as of 2024
- Spot instances have 70% discount (actual may vary)
- Monthly projection assumes 8 peak hours/day with 2x traffic
- Scale-to-zero threshold: 5 minutes idle

## Troubleshooting

### Services not starting
```bash
# Check Docker status
docker ps

# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### Metrics collection fails
- Ensure Docker containers are running: `docker ps`
- Check container names match those in `collect.sh`
- Verify Docker stats command works: `docker stats --no-stream api-gateway`

### Cost calculation errors
- Verify metrics file is valid JSON
- Check that duration_seconds matches actual test duration
- Ensure Python packages are installed: `pip3 install pyyaml`

## Limitations

- Costs are estimates based on Azure pricing models
- Actual cloud costs may vary due to:
  - Regional pricing differences
  - Reserved instance discounts
  - Data transfer costs (not included)
  - Storage costs (not included)
- Performance metrics (latency) are from local environment, not cloud
- Scale-to-zero behavior is simulated, actual behavior may differ

## Contributing

To update pricing or add new platforms:
1. Update `cost-calculator/pricing-models.py`
2. Update `cost-calculator/config.yaml`
3. Test with sample metrics
4. Update documentation

## License

Part of the SE360 project.
