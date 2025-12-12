"""
Azure Pricing Models for Cost Simulation
Supports ACA, ACI, and AKS with Spot instances pricing
"""

from dataclasses import dataclass
from typing import Dict, Optional
from decimal import Decimal


@dataclass
class PricingModel:
    """Base pricing model"""
    name: str
    vcpu_per_second: Decimal
    memory_per_gb_second: Decimal
    supports_scale_to_zero: bool = False
    minimum_containers: int = 0
    additional_costs: Optional[Dict[str, Decimal]] = None


class ACAPricing(PricingModel):
    """Azure Container Apps Consumption Pricing"""
    
    def __init__(self):
        super().__init__(
            name="Azure Container Apps (ACA)",
            # Pricing as of 2024: $0.000012 per vCPU-second, $0.0000015 per GB-second
            vcpu_per_second=Decimal("0.000012"),
            memory_per_gb_second=Decimal("0.0000015"),
            supports_scale_to_zero=True,
            minimum_containers=0,
            additional_costs={}
        )


class ACIPricing(PricingModel):
    """Azure Container Instances Pricing"""
    
    def __init__(self):
        super().__init__(
            name="Azure Container Instances (ACI)",
            # Similar pricing to ACA but less efficient scale-to-zero
            vcpu_per_second=Decimal("0.000012"),
            memory_per_gb_second=Decimal("0.0000015"),
            supports_scale_to_zero=False,  # ACI doesn't scale to zero as well
            minimum_containers=1,  # At least 1 container running
            additional_costs={}
        )


class AKSPricing(PricingModel):
    """Azure Kubernetes Service Pricing with Spot Instances"""
    
    def __init__(self, use_spot: bool = True, spot_discount: Decimal = Decimal("0.70")):
        """
        Args:
            use_spot: Whether to use Spot instances (70% discount)
            spot_discount: Discount percentage for spot instances (default 70%)
        """
        # Control plane cost: $0.10/hour (free for first cluster)
        control_plane_per_hour = Decimal("0.10")
        
        # Node pricing: On-demand vs Spot
        # On-demand: ~$0.048 per vCPU-hour, ~$0.005 per GB-hour
        # Convert to per-second
        on_demand_vcpu_per_second = Decimal("0.048") / Decimal("3600")  # $0.0000133 per vCPU-second
        on_demand_memory_per_gb_second = Decimal("0.005") / Decimal("3600")  # $0.00000139 per GB-second
        
        if use_spot:
            # Spot instances: 70% discount
            vcpu_per_second = on_demand_vcpu_per_second * (Decimal("1") - spot_discount)
            memory_per_gb_second = on_demand_memory_per_gb_second * (Decimal("1") - spot_discount)
        else:
            vcpu_per_second = on_demand_vcpu_per_second
            memory_per_gb_second = on_demand_memory_per_gb_second
        
        super().__init__(
            name=f"Azure Kubernetes Service (AKS) - {'Spot' if use_spot else 'On-Demand'}",
            vcpu_per_second=vcpu_per_second,
            memory_per_gb_second=memory_per_gb_second,
            supports_scale_to_zero=False,  # Nodes always running
            minimum_containers=0,
            additional_costs={
                "control_plane_per_hour": control_plane_per_hour,
                "node_overhead_per_node": Decimal("0.01"),  # Estimated overhead per node
            }
        )
        self.use_spot = use_spot
        self.spot_discount = spot_discount
        self.control_plane_per_hour = control_plane_per_hour


def get_pricing_model(platform: str, **kwargs) -> PricingModel:
    """
    Factory function to get pricing model
    
    Args:
        platform: 'aca', 'aci', or 'aks'
        **kwargs: Additional arguments for specific platforms
            - For AKS: use_spot (bool), spot_discount (Decimal)
    
    Returns:
        PricingModel instance
    """
    platform_lower = platform.lower()
    
    if platform_lower == "aca":
        return ACAPricing()
    elif platform_lower == "aci":
        return ACIPricing()
    elif platform_lower == "aks":
        use_spot = kwargs.get("use_spot", True)
        spot_discount = kwargs.get("spot_discount", Decimal("0.70"))
        return AKSPricing(use_spot=use_spot, spot_discount=spot_discount)
    else:
        raise ValueError(f"Unknown platform: {platform}. Supported: 'aca', 'aci', 'aks'")


# Pricing configuration for easy updates
PRICING_CONFIG = {
    "aca": {
        "vcpu_per_second": 0.000012,
        "memory_per_gb_second": 0.0000015,
        "scale_to_zero": True,
    },
    "aci": {
        "vcpu_per_second": 0.000012,
        "memory_per_gb_second": 0.0000015,
        "scale_to_zero": False,
    },
    "aks_spot": {
        "vcpu_per_second": 0.000004,  # ~70% discount
        "memory_per_gb_second": 0.0000004,  # ~70% discount
        "control_plane_per_hour": 0.10,
        "spot_discount": 0.70,
    },
    "aks_ondemand": {
        "vcpu_per_second": 0.0000133,
        "memory_per_gb_second": 0.00000139,
        "control_plane_per_hour": 0.10,
    }
}
