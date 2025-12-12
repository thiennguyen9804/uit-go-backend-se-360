#!/usr/bin/env python3
"""
Parse collected metrics and aggregate into format for cost calculation
"""

import json
import sys
from pathlib import Path
from typing import Dict, List
from datetime import datetime


def parse_metrics_file(metrics_file: str) -> Dict:
    """
    Parse metrics JSON file and aggregate by service
    
    Args:
        metrics_file: Path to metrics JSON file
    
    Returns:
        Dictionary with aggregated metrics per service
    """
    with open(metrics_file, 'r') as f:
        data = json.load(f)
    
    # Get collection parameters
    duration_seconds = data.get('duration_seconds', 0)
    interval_seconds = data.get('interval_seconds', 10)
    collected_metrics = data.get('collected_metrics', {})
    
    # Aggregate by service
    service_metrics = {}
    
    for timestamp, metric in collected_metrics.items():
        service = metric.get('service')
        if not service:
            continue
        
        if service not in service_metrics:
            service_metrics[service] = {
                'samples': [],
                'cpu_cores': metric.get('cpu_cores', 0.5),
                'memory_limit_gb': metric.get('memory_limit_gb', 1.0),
            }
        
        service_metrics[service]['samples'].append({
            'timestamp': timestamp,
            'cpu_percent': metric.get('cpu_percent', 0),
            'cpu_cores': metric.get('cpu_cores', 0.5),
            'memory_used_gb': metric.get('memory_used_gb', 0),
            'memory_limit_gb': metric.get('memory_limit_gb', 1.0),
        })
    
    # Calculate aggregated metrics
    result = {}
    
    for service, metrics in service_metrics.items():
        samples = metrics['samples']
        if not samples:
            continue
        
        # Calculate totals
        total_vcpu_seconds = 0
        total_memory_gb_seconds = 0
        max_cpu_percent = 0
        max_memory_gb = 0
        avg_cpu_percent = 0
        avg_memory_gb = 0
        
        cpu_cores = metrics['cpu_cores']
        memory_limit_gb = metrics['memory_limit_gb']
        
        for sample in samples:
            # CPU: convert percentage to vCPU-seconds
            # Assuming CPU percent is out of 100% for allocated cores
            cpu_utilization = sample['cpu_percent'] / 100.0
            vcpu_used = cpu_cores * cpu_utilization
            total_vcpu_seconds += vcpu_used * (interval_seconds)
            
            # Memory: use actual usage
            memory_used = sample['memory_used_gb']
            total_memory_gb_seconds += memory_used * interval_seconds
            
            # Track max and avg
            max_cpu_percent = max(max_cpu_percent, sample['cpu_percent'])
            max_memory_gb = max(max_memory_gb, memory_used)
            avg_cpu_percent += sample['cpu_percent']
            avg_memory_gb += memory_used
        
        num_samples = len(samples)
        avg_cpu_percent = avg_cpu_percent / num_samples if num_samples > 0 else 0
        avg_memory_gb = avg_memory_gb / num_samples if num_samples > 0 else 0
        
        # Estimate replicas (simplified: assume 1 replica if running)
        # In real scenario, would track actual replica counts
        replicas = [{
            'count': 1,
            'duration_seconds': duration_seconds,
            'start_time': samples[0]['timestamp'] if samples else None,
            'end_time': samples[-1]['timestamp'] if samples else None,
        }]
        
        result[service] = {
            'vcpu_seconds': total_vcpu_seconds,
            'memory_gb_seconds': total_memory_gb_seconds,
            'cpu_cores_allocated': cpu_cores,
            'memory_gb_allocated': memory_limit_gb,
            'max_cpu_percent': max_cpu_percent,
            'max_memory_gb': max_memory_gb,
            'avg_cpu_percent': avg_cpu_percent,
            'avg_memory_gb': avg_memory_gb,
            'replicas': replicas,
            'num_samples': num_samples,
        }
    
    return {
        'duration_seconds': duration_seconds,
        'interval_seconds': interval_seconds,
        'start_time': data.get('start_time'),
        'end_time': data.get('end_time'),
        'services': result,
    }


def export_to_json(parsed_metrics: Dict, output_file: str):
    """Export parsed metrics to JSON file for cost calculator"""
    with open(output_file, 'w') as f:
        json.dump(parsed_metrics, f, indent=2)
    print(f"Exported metrics to: {output_file}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: parse-metrics.py <metrics_file> [output_file]")
        print("Example: parse-metrics.py metrics-20240101-120000.json parsed-metrics.json")
        sys.exit(1)
    
    metrics_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "parsed-metrics.json"
    
    print(f"Parsing metrics from: {metrics_file}")
    
    try:
        parsed = parse_metrics_file(metrics_file)
        export_to_json(parsed, output_file)
        
        print(f"\nSummary:")
        print(f"  Duration: {parsed['duration_seconds']} seconds ({parsed['duration_seconds']/3600:.2f} hours)")
        print(f"  Services: {len(parsed['services'])}")
        for service, metrics in parsed['services'].items():
            print(f"    - {service}:")
            print(f"        vCPU-seconds: {metrics['vcpu_seconds']:.2f}")
            print(f"        Memory GB-seconds: {metrics['memory_gb_seconds']:.2f}")
            print(f"        Avg CPU: {metrics['avg_cpu_percent']:.1f}%")
            print(f"        Avg Memory: {metrics['avg_memory_gb']:.2f} GB")
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
