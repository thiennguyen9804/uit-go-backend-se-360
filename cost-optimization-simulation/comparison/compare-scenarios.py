#!/usr/bin/env python3
"""
Compare cost scenarios across different platforms
"""

import json
import sys
from pathlib import Path
from decimal import Decimal

# Add parent directory to path to import simulator
sys.path.insert(0, str(Path(__file__).parent.parent / "cost-calculator"))

from simulator import CostSimulator


def compare_scenarios(metrics_file: str, duration_seconds: float) -> dict:
    """
    Compare all cost scenarios
    
    Args:
        metrics_file: Path to parsed metrics JSON file
        duration_seconds: Test duration in seconds
    
    Returns:
        Comparison results dictionary
    """
    simulator = CostSimulator()
    
    # Load metrics
    with open(metrics_file, 'r') as f:
        metrics_data = json.load(f)
    
    # Extract service metrics
    all_metrics = metrics_data.get('services', {})
    duration = Decimal(str(duration_seconds))
    
    # Calculate for each platform
    print("Calculating costs for ACA...")
    aca_result = simulator.calculate_platform_cost("aca", all_metrics, duration)
    
    print("Calculating costs for ACI...")
    aci_result = simulator.calculate_platform_cost("aci", all_metrics, duration)
    
    print("Calculating costs for AKS (Spot)...")
    aks_spot_result = simulator.calculate_platform_cost("aks", all_metrics, duration, use_spot=True)
    
    print("Calculating costs for AKS (On-Demand)...")
    aks_ondemand_result = simulator.calculate_platform_cost("aks", all_metrics, duration, use_spot=False)
    
    # Project monthly costs
    print("Projecting monthly costs...")
    aca_monthly = simulator.project_monthly_cost(Decimal(str(aca_result['cost_per_hour'])))
    aci_monthly = simulator.project_monthly_cost(Decimal(str(aci_result['cost_per_hour'])))
    aks_spot_monthly = simulator.project_monthly_cost(Decimal(str(aks_spot_result['cost_per_hour'])))
    aks_ondemand_monthly = simulator.project_monthly_cost(Decimal(str(aks_ondemand_result['cost_per_hour'])))
    
    # Find cheapest option
    costs = {
        "ACA": aca_result['total_cost'],
        "ACI": aci_result['total_cost'],
        "AKS Spot": aks_spot_result['total_cost'],
        "AKS On-Demand": aks_ondemand_result['total_cost'],
    }
    cheapest = min(costs.items(), key=lambda x: x[1])
    
    # Calculate savings
    savings = {}
    for platform, cost in costs.items():
        if cost > 0:
            savings[platform] = {
                "vs_cheapest": float(cost - cheapest[1]),
                "savings_percentage": float((cost - cheapest[1]) / cost * 100) if cost > 0 else 0,
            }
    
    return {
        "test_duration_seconds": float(duration_seconds),
        "test_duration_hours": float(duration_seconds / 3600),
        "platforms": {
            "aca": {
                **aca_result,
                "monthly_projection": aca_monthly,
            },
            "aci": {
                **aci_result,
                "monthly_projection": aci_monthly,
            },
            "aks_spot": {
                **aks_spot_result,
                "monthly_projection": aks_spot_monthly,
            },
            "aks_ondemand": {
                **aks_ondemand_result,
                "monthly_projection": aks_ondemand_monthly,
            },
        },
        "comparison": {
            "cheapest_platform": cheapest[0],
            "cheapest_cost": float(cheapest[1]),
            "cost_differences": {
                platform: float(cost - cheapest[1])
                for platform, cost in costs.items()
            },
            "savings": savings,
        },
        "summary": {
            "total_services": len(all_metrics),
            "services_analyzed": list(all_metrics.keys()),
        },
    }


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: compare-scenarios.py <metrics_file> <duration_seconds> [output_file]")
        print("Example: compare-scenarios.py parsed-metrics.json 3600 comparison-results.json")
        sys.exit(1)
    
    metrics_file = sys.argv[1]
    duration_seconds = float(sys.argv[2])
    output_file = sys.argv[3] if len(sys.argv) > 3 else "comparison-results.json"
    
    print(f"Comparing scenarios...")
    print(f"  Metrics file: {metrics_file}")
    print(f"  Duration: {duration_seconds} seconds ({duration_seconds/3600:.2f} hours)")
    print("")
    
    try:
        results = compare_scenarios(metrics_file, duration_seconds)
        
        # Save results
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"\nComparison completed!")
        print(f"Results saved to: {output_file}")
        print("")
        print("Summary:")
        print("=" * 60)
        print(f"Cheapest Platform: {results['comparison']['cheapest_platform']}")
        print(f"Cheapest Cost: ${results['comparison']['cheapest_cost']:.4f}")
        print("")
        print("Cost Comparison:")
        for platform, data in results['platforms'].items():
            cost = data['total_cost']
            monthly = data['monthly_projection']['projected_monthly_cost']
            print(f"  {platform.upper()}:")
            print(f"    Test Cost: ${cost:.4f}")
            print(f"    Monthly Projection: ${monthly:.2f}")
            if platform in results['comparison']['savings']:
                savings = results['comparison']['savings'][platform]
                print(f"    Savings vs Cheapest: ${savings['vs_cheapest']:.4f} ({savings['savings_percentage']:.1f}%)")
        print("=" * 60)
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
