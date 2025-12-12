#!/usr/bin/env python3
"""
Generate comparison report with charts
"""

import json
import sys
from pathlib import Path
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# Try to import plotly for interactive charts (optional)
try:
    import plotly.graph_objects as go
    import plotly.express as px
    HAS_PLOTLY = True
except ImportError:
    HAS_PLOTLY = False
    print("Warning: plotly not installed, will use matplotlib only")


def generate_markdown_report(comparison_file: str, output_file: str):
    """Generate markdown report from comparison results"""
    
    with open(comparison_file, 'r') as f:
        data = json.load(f)
    
    platforms = data['platforms']
    comparison = data['comparison']
    summary = data.get('summary', {})
    
    report = f"""# Cost Optimization Comparison Report

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Executive Summary

This report compares the cost and performance of different Azure container platforms:
- **Azure Container Apps (ACA)**: Serverless with scale-to-zero
- **Azure Container Instances (ACI)**: Simple container hosting
- **Azure Kubernetes Service (AKS)**: With Spot instances (70% discount) and On-Demand

### Test Duration
- **Duration**: {data['test_duration_hours']:.2f} hours ({data['test_duration_seconds']:.0f} seconds)
- **Services Analyzed**: {summary.get('total_services', 0)} services
- **Services**: {', '.join(summary.get('services_analyzed', []))}

## Cost Comparison

### Test Period Costs

| Platform | Total Cost | Cost per Hour | Monthly Projection | Annual Projection |
|----------|------------|---------------|---------------------|-------------------|
"""
    
    for platform_key, platform_data in platforms.items():
        platform_name = platform_data['platform']
        total_cost = platform_data['total_cost']
        hourly_cost = platform_data['cost_per_hour']
        monthly = platform_data['monthly_projection']['projected_monthly_cost']
        annual = platform_data['monthly_projection']['projected_annual_cost']
        
        report += f"| {platform_name} | ${total_cost:.4f} | ${hourly_cost:.4f} | ${monthly:.2f} | ${annual:.2f} |\n"
    
    report += f"""
### Cost Savings Analysis

**Cheapest Option**: {comparison['cheapest_platform']} (${comparison['cheapest_cost']:.4f})

| Platform | Additional Cost vs Cheapest | Savings Percentage |
|----------|----------------------------|-------------------|
"""
    
    for platform, savings_data in comparison['savings'].items():
        additional = savings_data['vs_cheapest']
        percentage = savings_data['savings_percentage']
        report += f"| {platform} | ${additional:.4f} | {percentage:.1f}% |\n"
    
    report += """
## Cost Breakdown by Service

"""
    
    for platform_key, platform_data in platforms.items():
        platform_name = platform_data['platform']
        report += f"### {platform_name}\n\n"
        report += "| Service | vCPU-seconds | Memory GB-seconds | vCPU Cost | Memory Cost | Total Cost |\n"
        report += "|---------|--------------|-------------------|-----------|-------------|------------|\n"
        
        for service_cost in platform_data.get('service_costs', []):
            service = service_cost['service']
            vcpu_sec = service_cost['vcpu_seconds']
            mem_sec = service_cost['memory_gb_seconds']
            vcpu_cost = service_cost['vcpu_cost']
            mem_cost = service_cost['memory_cost']
            total = service_cost['total_cost']
            
            report += f"| {service} | {vcpu_sec:.2f} | {mem_sec:.2f} | ${vcpu_cost:.4f} | ${mem_cost:.4f} | ${total:.4f} |\n"
        
        if 'control_plane_cost' in platform_data:
            report += f"\n**Additional Costs:**\n"
            report += f"- Control Plane: ${platform_data['control_plane_cost']:.4f}\n"
            report += f"- Node Overhead: ${platform_data.get('node_overhead_cost', 0):.4f}\n"
        
        report += "\n"
    
    report += """
## Recommendations

### Best for Cost Optimization
"""
    
    cheapest = comparison['cheapest_platform']
    report += f"- **{cheapest}** offers the lowest cost for this workload\n"
    
    report += """
### Platform Selection Guide

1. **Azure Container Apps (ACA)**
   - Best for: Variable traffic, microservices with scale-to-zero
   - Advantages: Automatic scaling, pay-per-use, no infrastructure management
   - Use when: Traffic is unpredictable, need to minimize idle costs

2. **Azure Container Instances (ACI)**
   - Best for: Simple container hosting, predictable workloads
   - Advantages: Simple deployment, per-second billing
   - Use when: Need simple container hosting without orchestration

3. **Azure Kubernetes Service (AKS) with Spot**
   - Best for: Stable workloads that can tolerate interruptions
   - Advantages: Significant cost savings (60-80%), full Kubernetes features
   - Use when: Need Kubernetes features, can handle spot evictions

4. **Azure Kubernetes Service (AKS) On-Demand**
   - Best for: Critical workloads requiring guaranteed availability
   - Advantages: Full control, no eviction risk
   - Use when: High availability is critical, cost is secondary

## Methodology

- **Metrics Collection**: Docker container stats collected every 10 seconds
- **Cost Calculation**: Based on Azure pricing as of 2024
- **Scale-to-Zero**: Applied for ACA (services with no traffic don't incur costs)
- **Spot Discount**: 70% discount applied for AKS Spot instances
- **Monthly Projection**: Based on average hourly cost with peak/off-peak patterns

## Notes

- Costs are estimates based on collected metrics and Azure pricing models
- Actual costs may vary based on:
  - Regional pricing differences
  - Reserved instance discounts
  - Data transfer costs
  - Storage costs (not included in this analysis)
- Performance metrics (latency, throughput) should be considered alongside costs
"""
    
    # Save report
    with open(output_file, 'w') as f:
        f.write(report)
    
    print(f"Markdown report generated: {output_file}")
    return report


def generate_charts(comparison_file: str, output_dir: str):
    """Generate visualization charts"""
    
    with open(comparison_file, 'r') as f:
        data = json.load(f)
    
    platforms = data['platforms']
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    # 1. Cost Comparison Bar Chart
    platform_names = []
    test_costs = []
    monthly_costs = []
    
    for platform_key, platform_data in platforms.items():
        platform_names.append(platform_data['platform'])
        test_costs.append(platform_data['total_cost'])
        monthly_costs.append(platform_data['monthly_projection']['projected_monthly_cost'])
    
    # Bar chart: Test period costs
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']
    bars1 = ax1.bar(platform_names, test_costs, color=colors[:len(platform_names)])
    ax1.set_ylabel('Cost (USD)')
    ax1.set_title('Cost Comparison - Test Period')
    ax1.set_xticklabels(platform_names, rotation=45, ha='right')
    ax1.grid(axis='y', alpha=0.3)
    
    # Add value labels on bars
    for bar in bars1:
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height,
                f'${height:.4f}',
                ha='center', va='bottom', fontsize=9)
    
    bars2 = ax2.bar(platform_names, monthly_costs, color=colors[:len(platform_names)])
    ax2.set_ylabel('Cost (USD)')
    ax2.set_title('Projected Monthly Cost')
    ax2.set_xticklabels(platform_names, rotation=45, ha='right')
    ax2.grid(axis='y', alpha=0.3)
    
    # Add value labels on bars
    for bar in bars2:
        height = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2., height,
                f'${height:.2f}',
                ha='center', va='bottom', fontsize=9)
    
    plt.tight_layout()
    chart_file = f"{output_dir}/cost-comparison.png"
    plt.savefig(chart_file, dpi=300, bbox_inches='tight')
    print(f"Chart saved: {chart_file}")
    plt.close()
    
    # 2. Cost Breakdown by Service (stacked bar)
    fig, ax = plt.subplots(figsize=(12, 8))
    
    service_names = set()
    for platform_data in platforms.values():
        for service_cost in platform_data.get('service_costs', []):
            service_names.add(service_cost['service'])
    
    service_names = sorted(service_names)
    
    # Prepare data for stacked bar
    bottom = [0] * len(platform_names)
    colors_map = plt.cm.Set3(range(len(service_names)))
    
    for i, service in enumerate(service_names):
        service_costs = []
        for platform_key, platform_data in platforms.items():
            # Find service cost for this platform
            cost = 0
            for sc in platform_data.get('service_costs', []):
                if sc['service'] == service:
                    cost = sc['total_cost']
                    break
            service_costs.append(cost)
        
        ax.bar(platform_names, service_costs, bottom=bottom, 
               label=service, color=colors_map[i])
        bottom = [b + c for b, c in zip(bottom, service_costs)]
    
    ax.set_ylabel('Cost (USD)')
    ax.set_title('Cost Breakdown by Service')
    ax.set_xticklabels(platform_names, rotation=45, ha='right')
    ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    ax.grid(axis='y', alpha=0.3)
    
    plt.tight_layout()
    chart_file = f"{output_dir}/cost-breakdown.png"
    plt.savefig(chart_file, dpi=300, bbox_inches='tight')
    print(f"Chart saved: {chart_file}")
    plt.close()
    
    print(f"\nAll charts saved to: {output_dir}/")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: generate-report.py <comparison_file> [output_dir]")
        print("Example: generate-report.py comparison-results.json ./reports")
        sys.exit(1)
    
    comparison_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "./reports"
    
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    print(f"Generating report from: {comparison_file}")
    print(f"Output directory: {output_dir}")
    print("")
    
    # Generate markdown report
    report_file = f"{output_dir}/comparison-report.md"
    generate_markdown_report(comparison_file, report_file)
    
    # Generate charts
    print("")
    print("Generating charts...")
    generate_charts(comparison_file, output_dir)
    
    print("")
    print("Report generation completed!")
    print(f"  - Markdown report: {report_file}")
    print(f"  - Charts: {output_dir}/")
