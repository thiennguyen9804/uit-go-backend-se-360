"""
Cost Simulator - Calculate costs for different Azure platforms
based on actual metrics collected from local Docker containers
"""

import json
import yaml
from decimal import Decimal
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from pathlib import Path
from pricing_models import get_pricing_model, PricingModel


class CostSimulator:
    """Simulate costs for different Azure platforms"""
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Args:
            config_path: Path to config.yaml (optional)
        """
        self.config_path = config_path or Path(__file__).parent / "config.yaml"
        self.config = self._load_config()
        
    def _load_config(self) -> dict:
        """Load configuration from YAML file"""
        with open(self.config_path, 'r') as f:
            return yaml.safe_load(f)
    
    def calculate_service_cost(
        self,
        pricing_model: PricingModel,
        service_name: str,
        metrics: Dict,
        duration_seconds: Decimal
    ) -> Dict:
        """
        Calculate cost for a single service
        
        Args:
            pricing_model: Pricing model to use
            service_name: Name of the service
            metrics: Dictionary with 'vcpu_seconds', 'memory_gb_seconds', 'replicas'
            duration_seconds: Total duration of the test in seconds
        
        Returns:
            Dictionary with cost breakdown
        """
        # Get resource usage
        vcpu_seconds = Decimal(str(metrics.get('vcpu_seconds', 0)))
        memory_gb_seconds = Decimal(str(metrics.get('memory_gb_seconds', 0)))
        replicas = metrics.get('replicas', [])
        
        # Handle scale-to-zero
        if pricing_model.supports_scale_to_zero:
            # Only count time when replicas > 0
            active_seconds = sum(
                Decimal(str(r.get('duration_seconds', 0)))
                for r in replicas
                if r.get('count', 0) > 0
            )
            # Adjust vcpu and memory seconds proportionally
            if duration_seconds > 0:
                scale_factor = active_seconds / duration_seconds
                vcpu_seconds = vcpu_seconds * scale_factor
                memory_gb_seconds = memory_gb_seconds * scale_factor
        else:
            # For platforms without scale-to-zero, use minimum containers
            min_containers = pricing_model.minimum_containers
            if min_containers > 0:
                # Ensure minimum containers are always running
                min_vcpu_seconds = Decimal(str(min_containers)) * Decimal("0.5") * duration_seconds
                min_memory_seconds = Decimal(str(min_containers)) * Decimal("1.0") * duration_seconds
                vcpu_seconds = max(vcpu_seconds, min_vcpu_seconds)
                memory_gb_seconds = max(memory_gb_seconds, min_memory_seconds)
        
        # Calculate costs
        vcpu_cost = vcpu_seconds * pricing_model.vcpu_per_second
        memory_cost = memory_gb_seconds * pricing_model.memory_per_gb_second
        
        # Additional costs (e.g., AKS control plane)
        additional_cost = Decimal("0")
        if pricing_model.additional_costs:
            for cost_name, cost_value in pricing_model.additional_costs.items():
                if "per_hour" in cost_name:
                    # Convert to per-second
                    hours = duration_seconds / Decimal("3600")
                    additional_cost += cost_value * hours
                else:
                    additional_cost += cost_value
        
        total_cost = vcpu_cost + memory_cost + additional_cost
        
        return {
            "service": service_name,
            "vcpu_seconds": float(vcpu_seconds),
            "memory_gb_seconds": float(memory_gb_seconds),
            "vcpu_cost": float(vcpu_cost),
            "memory_cost": float(memory_cost),
            "additional_cost": float(additional_cost),
            "total_cost": float(total_cost),
            "replicas": replicas,
        }
    
    def calculate_platform_cost(
        self,
        platform: str,
        all_metrics: Dict[str, Dict],
        duration_seconds: Decimal,
        **kwargs
    ) -> Dict:
        """
        Calculate total cost for a platform across all services
        
        Args:
            platform: 'aca', 'aci', or 'aks'
            all_metrics: Dictionary mapping service_name -> metrics
            duration_seconds: Total duration in seconds
            **kwargs: Additional arguments for pricing model (e.g., use_spot for AKS)
        
        Returns:
            Dictionary with total cost and breakdown
        """
        pricing_model = get_pricing_model(platform, **kwargs)
        
        service_costs = []
        total_cost = Decimal("0")
        
        for service_name, metrics in all_metrics.items():
            service_cost = self.calculate_service_cost(
                pricing_model,
                service_name,
                metrics,
                duration_seconds
            )
            service_costs.append(service_cost)
            total_cost += Decimal(str(service_cost['total_cost']))
        
        # AKS-specific: Add control plane and node overhead
        if platform == "aks":
            # Control plane cost
            hours = duration_seconds / Decimal("3600")
            control_plane_cost = pricing_model.control_plane_per_hour * hours
            
            # Estimate node overhead (simplified)
            # Assume average 2 nodes running
            node_overhead = Decimal("0.01") * Decimal("2") * hours
            
            total_cost += control_plane_cost + node_overhead
            
            return {
                "platform": pricing_model.name,
                "duration_seconds": float(duration_seconds),
                "duration_hours": float(duration_seconds / Decimal("3600")),
                "service_costs": service_costs,
                "control_plane_cost": float(control_plane_cost),
                "node_overhead_cost": float(node_overhead),
                "total_cost": float(total_cost),
                "cost_per_hour": float(total_cost / (duration_seconds / Decimal("3600"))),
            }
        
        return {
            "platform": pricing_model.name,
            "duration_seconds": float(duration_seconds),
            "duration_hours": float(duration_seconds / Decimal("3600")),
            "service_costs": service_costs,
            "total_cost": float(total_cost),
            "cost_per_hour": float(total_cost / (duration_seconds / Decimal("3600"))),
        }
    
    def project_monthly_cost(
        self,
        hourly_cost: Decimal,
        peak_hours_per_day: int = 8,
        off_peak_hours_per_day: int = 16,
        peak_multiplier: Decimal = Decimal("2.0"),
        days_per_month: int = 30
    ) -> Dict:
        """
        Project monthly cost based on hourly cost
        
        Args:
            hourly_cost: Cost per hour from test
            peak_hours_per_day: Number of peak hours per day
            off_peak_hours_per_day: Number of off-peak hours per day
            peak_multiplier: Multiplier for peak hours (default 2x)
            days_per_month: Days in month
        
        Returns:
            Dictionary with monthly projections
        """
        # Calculate average hourly cost
        # Peak hours: 2x traffic, off-peak: 1x traffic
        avg_hourly_cost = (
            (hourly_cost * peak_multiplier * Decimal(peak_hours_per_day)) +
            (hourly_cost * Decimal(off_peak_hours_per_day))
        ) / Decimal(24)
        
        monthly_cost = avg_hourly_cost * Decimal(24) * Decimal(days_per_month)
        
        return {
            "hourly_cost_baseline": float(hourly_cost),
            "peak_hours_per_day": peak_hours_per_day,
            "off_peak_hours_per_day": off_peak_hours_per_day,
            "peak_multiplier": float(peak_multiplier),
            "average_hourly_cost": float(avg_hourly_cost),
            "projected_monthly_cost": float(monthly_cost),
            "projected_annual_cost": float(monthly_cost * Decimal("12")),
        }
    
    def compare_platforms(
        self,
        metrics_file: str,
        duration_seconds: Decimal
    ) -> Dict:
        """
        Compare costs across all platforms
        
        Args:
            metrics_file: Path to JSON file with metrics
            duration_seconds: Test duration in seconds
        
        Returns:
            Comparison results
        """
        # Load metrics
        with open(metrics_file, 'r') as f:
            all_metrics = json.load(f)
        
        # Calculate for each platform
        aca_result = self.calculate_platform_cost("aca", all_metrics, duration_seconds)
        aci_result = self.calculate_platform_cost("aci", all_metrics, duration_seconds)
        aks_spot_result = self.calculate_platform_cost("aks", all_metrics, duration_seconds, use_spot=True)
        aks_ondemand_result = self.calculate_platform_cost("aks", all_metrics, duration_seconds, use_spot=False)
        
        # Project monthly costs
        aca_monthly = self.project_monthly_cost(Decimal(str(aca_result['cost_per_hour'])))
        aci_monthly = self.project_monthly_cost(Decimal(str(aci_result['cost_per_hour'])))
        aks_spot_monthly = self.project_monthly_cost(Decimal(str(aks_spot_result['cost_per_hour'])))
        aks_ondemand_monthly = self.project_monthly_cost(Decimal(str(aks_ondemand_result['cost_per_hour'])))
        
        # Find cheapest option
        costs = {
            "ACA": aca_result['total_cost'],
            "ACI": aci_result['total_cost'],
            "AKS Spot": aks_spot_result['total_cost'],
            "AKS On-Demand": aks_ondemand_result['total_cost'],
        }
        cheapest = min(costs.items(), key=lambda x: x[1])
        
        return {
            "test_duration_seconds": float(duration_seconds),
            "test_duration_hours": float(duration_seconds / Decimal("3600")),
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
                "savings_percentage": {
                    platform: float((cost - cheapest[1]) / cost * 100)
                    for platform, cost in costs.items()
                    if cost > 0
                },
            },
        }


if __name__ == "__main__":
    # Example usage
    simulator = CostSimulator()
    
    # Example metrics (would come from actual collection)
    example_metrics = {
        "api-gateway": {
            "vcpu_seconds": 1800,
            "memory_gb_seconds": 3600,
            "replicas": [{"count": 1, "duration_seconds": 3600}],
        },
        "user-service": {
            "vcpu_seconds": 1800,
            "memory_gb_seconds": 3600,
            "replicas": [{"count": 1, "duration_seconds": 3600}],
        },
    }
    
    duration = Decimal("3600")  # 1 hour
    
    result = simulator.calculate_platform_cost("aca", example_metrics, duration)
    print(json.dumps(result, indent=2))
