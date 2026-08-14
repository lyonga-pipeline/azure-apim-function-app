locals {
  valid_criticalities        = ["Blocking", "Critical", "Enabling", "Deferred"]
  valid_statuses             = ["implemented", "contract", "external-governed", "cost-disabled", "advisory", "module-only", "not-composed", "documentation"]
  phase1_required_gap_status = ["advisory", "module-only", "not-composed", "documentation"]

  phase1_components = {
    "GOV-01" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Management group hierarchy"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "global-governance"
      pattern        = "management-group-baseline"
      implementation = "azurerm_management_group hierarchy"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "GOV-03" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Platform + workload subscriptions"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "subscription-vending"
      pattern        = "subscription-baseline"
      implementation = "subscription catalog and management group placement"
      status         = "implemented"
      cost_state     = "subscription-container-no-cost"
    }
    "GOV-05" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Azure Policy - core baseline initiative"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "global-governance"
      pattern        = "policy-baseline"
      implementation = "policy definitions, initiatives, and assignments"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "GOV-06" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Azure Policy - tagging enforcement"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "global-governance"
      pattern        = "tagging-baseline"
      implementation = "enterprise tag contract and Azure Policy assignments"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "GOV-07" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Azure Policy - diagnostics DINE"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "global-governance"
      pattern        = "diagnostic-policy-baseline"
      implementation = "diagnostics policy and OPA advisory controls"
      status         = "implemented"
      cost_state     = "no-cost until remediation creates diagnostic settings"
    }
    "GOV-09" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Naming convention module"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "shared-modules"
      pattern        = "naming-contract"
      implementation = "module naming inputs and OPA naming checks"
      status         = "contract"
      cost_state     = "no-cost"
    }
    "GOV-10" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Resource group topology"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform and workload roots"
      pattern        = "resource-group-baseline"
      implementation = "resource-group module per lifecycle boundary"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "GOV-12" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "MG-scoped RBAC assignments"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "global-governance"
      pattern        = "rbac-baseline"
      implementation = "custom role definitions and scoped role assignments"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "GOV-15" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Resource locks on platform resources"
      phase          = "Phase 1 (MVP)"
      criticality    = "Enabling"
      workspace      = "platform roots"
      pattern        = "management-lock-baseline"
      implementation = "azurerm_management_lock over named scope catalog"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "IAM-01" = {
      stack          = "L3 Identity"
      domain         = "Identity"
      component      = "Entra ID RBAC groups"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-identity"
      pattern        = "identity-governance-contract"
      implementation = "tenant identity process with Terraform role-assignment consumption"
      status         = "external-governed"
      cost_state     = "no-cost"
    }
    "IAM-02" = {
      stack          = "L3 Identity"
      domain         = "Identity"
      component      = "Custom RBAC role definitions"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "global-governance"
      pattern        = "rbac-baseline"
      implementation = "azurerm_role_definition"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "IAM-03" = {
      stack          = "L3 Identity"
      domain         = "Identity"
      component      = "PIM eligible assignments"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-identity"
      pattern        = "identity-governance-contract"
      implementation = "Privileged Identity Management tenant process"
      status         = "external-governed"
      cost_state     = "license-dependent"
    }
    "IAM-04" = {
      stack          = "L3 Identity"
      domain         = "Identity"
      component      = "Break-glass emergency accounts"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-identity"
      pattern        = "identity-governance-contract"
      implementation = "tenant emergency access process"
      status         = "external-governed"
      cost_state     = "license-dependent"
    }
    "IAM-05" = {
      stack          = "L3 Identity"
      domain         = "Identity"
      component      = "Workload identity federation for CI/CD"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "delivery pipelines and HCP workspaces"
      pattern        = "workload-identity-federation"
      implementation = "HCP Terraform Azure dynamic credential subject contract"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "IAM-06" = {
      stack          = "L3 Identity"
      domain         = "Identity"
      component      = "Managed identity pattern"
      phase          = "Phase 1 (MVP)"
      criticality    = "Enabling"
      workspace      = "platform-identity and workload patterns"
      pattern        = "managed-identity-baseline"
      implementation = "user-assigned identity module and workload pattern"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "IAM-07" = {
      stack          = "L3 Identity"
      domain         = "Identity"
      component      = "AD DS domain controllers (Central US)"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-identity"
      pattern        = "directory-services-contract"
      implementation = "on-prem/domain services lifecycle, consumed through DNS and routing contracts"
      status         = "external-governed"
      cost_state     = "external"
    }
    "IAM-08" = {
      stack          = "L3 Identity"
      domain         = "Identity"
      component      = "Conditional Access for management plane"
      phase          = "Phase 1 (MVP)"
      criticality    = "Enabling"
      workspace      = "platform-identity"
      pattern        = "identity-governance-contract"
      implementation = "tenant Conditional Access process"
      status         = "external-governed"
      cost_state     = "license-dependent"
    }
    "NET-01" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "IP address plan / CIDR allocation"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity and workload-spoke"
      pattern        = "network-address-contract"
      implementation = "explicit VNet and subnet CIDR inputs"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "NET-02" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Hub VNet (Central US)"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "hub-network"
      implementation = "virtual-network module"
      status         = "implemented"
      cost_state     = "low-cost"
    }
    "NET-03" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "GatewaySubnet"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "hub-network"
      implementation = "reserved hub_vnet.subnets.GatewaySubnet"
      status         = "implemented"
      cost_state     = "no incremental cost"
    }
    "NET-04" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "MgmtSubnet (firewall management)"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "reserved hub_vnet.subnets.palo_alto_management"
      status         = "implemented"
      cost_state     = "no incremental cost"
    }
    "NET-05" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "UntrustSubnet"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "reserved hub_vnet.subnets.palo_alto_untrust"
      status         = "implemented"
      cost_state     = "no incremental cost"
    }
    "NET-06" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "TrustSubnet"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "reserved hub_vnet.subnets.palo_alto_trust"
      status         = "implemented"
      cost_state     = "no incremental cost"
    }
    "NET-08" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Shared services / DNS subnet"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "hub-network"
      implementation = "reserved shared_services and dns_resolver subnets"
      status         = "implemented"
      cost_state     = "no incremental cost"
    }
    "NET-10" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Palo Alto VM-Series HA pair"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "route, subnet, HA, SKU, and Panorama contract; VM lifecycle external until approved"
      status         = "contract"
      cost_state     = "cost-disabled"
    }
    "NET-11" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Palo bootstrap storage"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "bootstrap storage contract, deployable through platform storage account map when enabled"
      status         = "contract"
      cost_state     = "cost-disabled"
    }
    "NET-12" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Panorama / Strata Cloud Manager onboarding"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "Panorama/Strata management contract"
      status         = "external-governed"
      cost_state     = "vendor-managed"
    }
    "NET-13" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Internal Load Balancer - Trust (HA ports)"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "optional load_balancers map with trust subnet frontend"
      status         = "implemented"
      cost_state     = "disabled-by-default"
    }
    "NET-14" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Internal Load Balancer - Untrust"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "optional load_balancers map with untrust subnet frontend"
      status         = "implemented"
      cost_state     = "disabled-by-default"
    }
    "NET-15" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Route tables and UDRs"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "routing-baseline"
      implementation = "route-table module and subnet route-table associations"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "NET-16" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "NSG baseline"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "nsg-baseline"
      implementation = "network-security-group module and subnet associations"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "NET-18" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "ExpressRoute Gateway"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-hybrid-connectivity"
      pattern        = "hybrid-connectivity"
      implementation = "virtual-network-gateway module, disabled in smoke-test tfvars"
      status         = "cost-disabled"
      cost_state     = "disabled-by-default"
    }
    "NET-19" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "ExpressRoute circuit connection"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-hybrid-connectivity"
      pattern        = "hybrid-connectivity"
      implementation = "expressroute-circuit and gateway-connection modules, disabled in smoke-test tfvars"
      status         = "cost-disabled"
      cost_state     = "disabled-by-default"
    }
    "NET-22" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Hub-to-spoke VNet peering"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "workload-spoke and network-peering"
      pattern        = "spoke-network"
      implementation = "workload-spoke peering contract and network-peering root"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "NET-23" = {
      stack          = "L2 Workload"
      domain         = "Network"
      component      = "Spoke VNet - internal-apps prod"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "workload-spoke"
      pattern        = "spoke-network"
      implementation = "workload-spoke root"
      status         = "implemented"
      cost_state     = "low-cost"
    }
    "NET-24" = {
      stack          = "L2 Workload"
      domain         = "Network"
      component      = "Spoke VNet - internal-apps non-prod"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "workload-spoke"
      pattern        = "spoke-network"
      implementation = "workload-spoke root"
      status         = "implemented"
      cost_state     = "low-cost"
    }
    "NET-26" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Private DNS zones (privatelink.*)"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "private-dns-baseline"
      implementation = "private-dns-zone and vnet-link modules"
      status         = "implemented"
      cost_state     = "low-cost"
    }
    "NET-27" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "DNS resolution architecture"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-connectivity"
      pattern        = "dns-resolution-contract"
      implementation = "dc-forwarders/private-resolver/hybrid mode contract"
      status         = "contract"
      cost_state     = "no-cost"
    }
    "NET-28" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "On-prem conditional forwarders"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "dns-resolution-contract"
      implementation = "on-prem DNS process referenced by hub DNS server inputs"
      status         = "external-governed"
      cost_state     = "external"
    }
    "NET-29" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Private endpoint pattern"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "workload patterns"
      pattern        = "private-endpoint-baseline"
      implementation = "private-endpoint module and function-app composition"
      status         = "implemented"
      cost_state     = "per-endpoint"
    }
    "NET-36" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Outbound egress path (Palo SNAT)"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "VirtualAppliance route validation to approved Palo Alto IPs"
      status         = "contract"
      cost_state     = "cost-disabled"
    }
    "NET-37" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Public IPs (firewall egress)"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "palo-alto-network-contract"
      implementation = "optional public_ips map"
      status         = "implemented"
      cost_state     = "disabled-by-default"
    }
    "NET-38" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "NCUS-to-CUS hub interconnect"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity"
      pattern        = "hub-interconnect-contract"
      implementation = "hub interconnect route and peering contract"
      status         = "contract"
      cost_state     = "disabled-by-default"
    }
    "SEC-01" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Microsoft Sentinel onboarding"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-management"
      pattern        = "defender-soc-posture"
      implementation = "no-cost Defender/SOC posture contract, Sentinel disabled until SOC approval"
      status         = "cost-disabled"
      cost_state     = "disabled-by-default"
    }
    "SEC-02" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Sentinel data connectors (core)"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-management"
      pattern        = "defender-soc-posture"
      implementation = "data connector posture contract"
      status         = "cost-disabled"
      cost_state     = "disabled-by-default"
    }
    "SEC-05" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Defender for Cloud"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-management"
      pattern        = "defender-soc-posture"
      implementation = "defender_plans map and no-cost posture contract"
      status         = "cost-disabled"
      cost_state     = "disabled-by-default"
    }
    "SEC-07" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Platform Key Vault"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-identity"
      pattern        = "platform-key-vault"
      implementation = "key-vault module"
      status         = "implemented"
      cost_state     = "low-cost"
    }
    "SEC-09" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Encryption at rest baseline"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform and workload modules"
      pattern        = "security-baseline"
      implementation = "module defaults and OPA advisory controls"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "SEC-10" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Encryption in transit enforcement"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform and workload modules"
      pattern        = "security-baseline"
      implementation = "TLS module defaults, HTTPS-only settings, and OPA advisory controls"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "SEC-12" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Privileged access path to platform VMs"
      phase          = "Phase 1 (MVP)"
      criticality    = "Enabling"
      workspace      = "platform-identity"
      pattern        = "privileged-access-contract"
      implementation = "PIM, CA, and operations process"
      status         = "external-governed"
      cost_state     = "license-dependent"
    }
    "OBS-01" = {
      stack          = "L2 Management"
      domain         = "Observability"
      component      = "Central Log Analytics workspace"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "platform-management"
      pattern        = "observability-baseline"
      implementation = "log-analytics module"
      status         = "implemented"
      cost_state     = "usage-based"
    }
    "OBS-02" = {
      stack          = "L2 Management"
      domain         = "Observability"
      component      = "Diagnostic settings"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform and workload roots"
      pattern        = "diagnostic-baseline"
      implementation = "diagnostic-settings module and policy/OPA advisory controls"
      status         = "implemented"
      cost_state     = "usage-based"
    }
    "OBS-03" = {
      stack          = "L2 Management"
      domain         = "Observability"
      component      = "Activity log collection"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-management"
      pattern        = "observability-baseline"
      implementation = "subscription activity-log diagnostic setting"
      status         = "implemented"
      cost_state     = "usage-based"
    }
    "PLT-01" = {
      stack          = "L2 Management"
      domain         = "Platform"
      component      = "Recovery Services Vault + policies"
      phase          = "Phase 1 (MVP)"
      criticality    = "Enabling"
      workspace      = "platform-management"
      pattern        = "platform-management-services"
      implementation = "optional recovery_services_vaults map"
      status         = "implemented"
      cost_state     = "disabled-by-default"
    }
    "PLT-06" = {
      stack          = "L2 Management"
      domain         = "Platform"
      component      = "Platform storage accounts"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-management"
      pattern        = "platform-management-services"
      implementation = "optional platform_storage_accounts map"
      status         = "implemented"
      cost_state     = "disabled-by-default"
    }
    "IAC-01" = {
      stack          = "L6 Delivery"
      domain         = "IaC"
      component      = "HCP Terraform organization structure"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "delivery"
      pattern        = "hcp-workspace-baseline"
      implementation = "workspace bootstrap and maps"
      status         = "implemented"
      cost_state     = "platform-service"
    }
    "IAC-02" = {
      stack          = "L6 Delivery"
      domain         = "IaC"
      component      = "Azure DevOps repos and pipelines"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "delivery"
      pattern        = "devsecops-pipeline"
      implementation = "azure-terraform/pipelines"
      status         = "implemented"
      cost_state     = "platform-service"
    }
    "IAC-03" = {
      stack          = "L6 Delivery"
      domain         = "IaC"
      component      = "Terraform module registry and versioning"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "delivery"
      pattern        = "module-release"
      implementation = "base module and pattern module structure"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "IAC-04" = {
      stack          = "L6 Delivery"
      domain         = "IaC"
      component      = "State management and workspace RBAC"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "delivery"
      pattern        = "hcp-workspace-baseline"
      implementation = "HCP workspace state boundaries and RBAC model"
      status         = "implemented"
      cost_state     = "platform-service"
    }
    "IAC-05" = {
      stack          = "L6 Delivery"
      domain         = "IaC"
      component      = "CI quality and security gates"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "delivery"
      pattern        = "devsecops-pipeline"
      implementation = "fmt, validate, plan capture, OPA advisory evidence"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "IAC-07" = {
      stack          = "L6 Delivery"
      domain         = "IaC"
      component      = "Subscription baseline module"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "subscription-vending"
      pattern        = "subscription-baseline"
      implementation = "subscription vending catalog and baseline placement"
      status         = "implemented"
      cost_state     = "subscription-container-no-cost"
    }
    "IAC-08" = {
      stack          = "L6 Delivery"
      domain         = "IaC"
      component      = "Environment promotion workflow"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "delivery"
      pattern        = "devsecops-pipeline"
      implementation = "workspace map and VCS-owned HCP run pattern"
      status         = "implemented"
      cost_state     = "no-cost"
    }
    "WKL-01" = {
      stack          = "L5 Workload"
      domain         = "Landing Zone"
      component      = "Spoke landing zone blueprint module"
      phase          = "Phase 1 (MVP)"
      criticality    = "Blocking"
      workspace      = "workload-spoke"
      pattern        = "spoke-network"
      implementation = "workload-spoke root and output contract"
      status         = "implemented"
      cost_state     = "low-cost"
    }
    "WKL-02" = {
      stack          = "L5 Workload"
      domain         = "Landing Zone"
      component      = "Pilot workload deployment"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "consumer-repos/online-banking/clientsync"
      pattern        = "function-app"
      implementation = "workload composition module through HCP and OPA advisory pipeline"
      status         = "implemented"
      cost_state     = "workload-owned"
    }
    "DR-03" = {
      stack          = "L1 Connectivity"
      domain         = "Resiliency"
      component      = "Zone redundancy in Central US"
      phase          = "Phase 1 (MVP)"
      criticality    = "Critical"
      workspace      = "platform-connectivity and workload roots"
      pattern        = "resiliency-contract"
      implementation = "regional selection, zone-capable modules, and disabled-by-default paid options"
      status         = "contract"
      cost_state     = "depends-on-resource"
    }
  }

  phase2_components = {
    "GOV-02" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Dormant MG placeholders"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "global-governance or subscription-vending"
      pattern        = "dormant-mg-placeholders"
      implementation = "global-governance management_groups input; subscription-vending dormant regulated/shared-services entries"
      status         = "contract"
      cost_state     = "deferred"
    }
    "GOV-04" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Subscription vending automation"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "global-governance or subscription-vending"
      pattern        = "subscription-vending"
      implementation = "subscription-vending variables: vending_enabled, billing scope, subscriptions, subscription_role_assignments"
      status         = "contract"
      cost_state     = "deferred"
    }
    "GOV-08" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Regulatory compliance initiative"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "global-governance or subscription-vending"
      pattern        = "governance-policy"
      implementation = "No deployable regulatory compliance initiative yet; use global-governance custom_policy_set_definitions and management_group_policy_assignments when approved."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "GOV-11" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Policy exemption workflow"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "global-governance or subscription-vending"
      pattern        = "governance-policy"
      implementation = "Exception workflow documented; Azure Policy exemption resource composition is not yet implemented."
      status         = "contract"
      cost_state     = "deferred"
    }
    "GOV-13" = {
      stack          = "L0 Foundation"
      domain         = "FinOps"
      component      = "Budgets and cost alerts"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "global-governance or subscription-vending"
      pattern        = "finops-baseline"
      implementation = "platform-management/main.tf azurerm_consumption_budget_subscription"
      status         = "contract"
      cost_state     = "deferred"
    }
    "GOV-14" = {
      stack          = "L0 Foundation"
      domain         = "Governance"
      component      = "Sandbox MG and subscription"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "global-governance or subscription-vending"
      pattern        = "subscription-vending"
      implementation = "subscription-vending sandbox subscription entries under sandbox-mg; creation is gated by vending_enabled and per-subscription enabled flags."
      status         = "contract"
      cost_state     = "deferred"
    }
    "NET-07" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "PartnerSubnet (Sunstream / PLANT)"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "partner-connectivity"
      implementation = "virtual-network, network-security-group, route-table, and vnet-peering modules are available; partner inputs stay deferred until requirements are approved."
      status         = "contract"
      cost_state     = "deferred"
    }
    "NET-17" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "NSG flow logs + traffic analytics"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "network-observability"
      implementation = "No Network Watcher flow-log module/root yet; add azurerm_network_watcher_flow_log or an approved module when this control is promoted."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "NET-20" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "VPN Gateway (S2S backup)"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "backup-vpn-connectivity"
      implementation = "Gateway and connection modules exist; add local network gateway plus backup routing inputs before enabling S2S VPN."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "NET-21" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Local network gateway + S2S connection"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "backup-vpn-connectivity"
      implementation = "Add local-network-gateway module/root plus virtual-network-gateway-connection inputs before enabling VPN backup."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "NET-25" = {
      stack          = "L2 Workload"
      domain         = "Network"
      component      = "Spoke VNet - external-apps"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "spoke-network"
      implementation = "virtual-network, vnet-peering, network-security-group, and route-table modules are available; external-apps spoke root is Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "NET-30" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Network Watcher and connection monitors"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "network-observability"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "NET-31" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Azure Route Server"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "route-server"
      implementation = "No Azure Route Server module/root yet; route-table and subnet-route-table-association modules are separate UDR controls."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "NET-32" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "DDoS Network Protection"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "ddos-protection"
      implementation = "ddos-protection-plan module is available; enable only after cost approval."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "NET-33" = {
      stack          = "L2 Workload"
      domain         = "Network"
      component      = "Cloudflare Tunnel connectors"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "cloudflare-connectivity-contract"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "NET-34" = {
      stack          = "L2 Workload"
      domain         = "Network"
      component      = "Cloudflare Zero Trust configuration"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "cloudflare-connectivity-contract"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "NET-35" = {
      stack          = "L2 Workload"
      domain         = "Network"
      component      = "Application Gateway + WAF (Cloudflare failover path)"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "app-gateway-waf-contract"
      implementation = "application-gateway module is available; Cloudflare failover root is Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "NET-40" = {
      stack          = "L2 Workload"
      domain         = "Network"
      component      = "Ingress failover design (Cloudflare to App Gateway)"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "app-gateway-waf-contract"
      implementation = "Design and root composition are Phase 2; pair Cloudflare controls with Application Gateway WAF before enabling."
      status         = "documentation"
      cost_state     = "deferred"
    }
    "NET-39" = {
      stack          = "L1 Connectivity"
      domain         = "Network"
      component      = "Sunstream partner hub peering"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-connectivity or workload-spoke"
      pattern        = "partner-connectivity"
      implementation = "network-peering root and vnet-peering module are available; partner peering entry is deferred until partner requirements are approved."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "SEC-03" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Palo log pipeline to Sentinel"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "defender-soc-posture"
      implementation = "No Palo-to-Sentinel data connector pipeline yet; add approved diagnostic/syslog/AMA/Sentinel connector composition in Phase 2."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "SEC-04" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Sentinel analytics, workbooks, automation"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "defender-soc-posture"
      implementation = "platform-management has the cost-disabled Defender/SOC posture contract; Sentinel analytics, workbook, and automation resources are Phase 2."
      status         = "cost-disabled"
      cost_state     = "deferred"
    }
    "SEC-06" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Defender plans - workload specific"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "defender-soc-posture"
      implementation = "platform-management has cost-disabled Defender/SOC contract; workload-specific plan expansion is Phase 2."
      status         = "cost-disabled"
      cost_state     = "deferred"
    }
    "SEC-08" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Customer-managed keys and rotation"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "secrets-management"
      implementation = "key-vault-key and storage-account-customer-managed-key modules are available; rotation automation is not yet composed."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "SEC-11" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Just-in-time VM access"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "just-in-time-vm-access"
      implementation = "Defender/SOC posture contract exists in platform-management, but JIT VM access configuration is not yet composed."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "SEC-13" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Secrets rotation automation"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "secrets-management"
      implementation = "key-vault and key-vault-* modules are available; rotation automation root is Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "SEC-14" = {
      stack          = "L4 Security"
      domain         = "Security"
      component      = "Compliance evidence and audit reporting"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "compliance-evidence"
      implementation = "pipelines capture HCP plan/policy evidence and OPA provides advisory checks; no separate audit reporting app is composed."
      status         = "contract"
      cost_state     = "deferred"
    }
    "OBS-04" = {
      stack          = "L2 Management"
      domain         = "Observability"
      component      = "Baseline alerts and action groups"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "monitoring-alerts"
      implementation = "action-group and monitor-metric-alert modules are available; a baseline alert catalog/root is Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "OBS-05" = {
      stack          = "L2 Management"
      domain         = "Observability"
      component      = "Log archive storage account"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "log-archive"
      implementation = "platform-management platform_storage_accounts map and storage-account module are available; log archive storage is disabled by default."
      status         = "cost-disabled"
      cost_state     = "deferred"
    }
    "OBS-06" = {
      stack          = "L2 Management"
      domain         = "Observability"
      component      = "Azure Monitor Agent and DCRs"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "monitor-agent"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "OBS-07" = {
      stack          = "L2 Management"
      domain         = "Observability"
      component      = "Workbooks and dashboards"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "observability-dashboards"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "OBS-08" = {
      stack          = "L2 Management"
      domain         = "Observability"
      component      = "ITSM / ticketing integration"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "itsm-integration"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "PLT-03" = {
      stack          = "L2 Management"
      domain         = "Platform"
      component      = "Compute gallery and golden images"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "compute-gallery"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "PLT-04" = {
      stack          = "L2 Management"
      domain         = "Platform"
      component      = "Azure Update Manager"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "update-management"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "PLT-05" = {
      stack          = "L2 Management"
      domain         = "Platform"
      component      = "Change tracking and inventory"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "change-inventory"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "PLT-07" = {
      stack          = "L2 Management"
      domain         = "Platform"
      component      = "Azure Site Recovery"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "resiliency-services"
      implementation = "recovery-services-vault module is available; ASR policy/fabric/replication composition is Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "PLT-08" = {
      stack          = "L2 Management"
      domain         = "Platform"
      component      = "Azure Arc for hybrid servers"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "hybrid-arc"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "IAC-06" = {
      stack          = "L6 Delivery"
      domain         = "IaC"
      component      = "Drift detection"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "delivery"
      pattern        = "drift-detection"
      implementation = "operations/drift captures the drift-detection contract; scheduled enforcement is Phase 2."
      status         = "contract"
      cost_state     = "deferred"
    }
    "WKL-03" = {
      stack          = "L5 Workload"
      domain         = "Landing Zone"
      component      = "Container platform (AKS or Container Apps)"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "workload pattern roots"
      pattern        = "container-platform"
      implementation = "container-agent module exists; AKS/Container Apps landing-zone root composition is Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "WKL-04" = {
      stack          = "L5 Workload"
      domain         = "Landing Zone"
      component      = "API Management"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "workload pattern roots"
      pattern        = "api-management"
      implementation = "apim-service, apim-api, apim-product, apim-policy, and apim-backend modules exist; APIM pattern root is Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "WKL-05" = {
      stack          = "L5 Workload"
      domain         = "Landing Zone"
      component      = "Data platform services"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "workload pattern roots"
      pattern        = "data-platform"
      implementation = "sql-server, sql-database, and synapse-related modules are available; Phase 2 data-platform root composition is pending."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "WKL-06" = {
      stack          = "L5 Workload"
      domain         = "Landing Zone"
      component      = "AVD / Citrix"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "workload pattern roots"
      pattern        = "desktop-virtualization"
      implementation = "Module/root not yet composed for this Phase 2 item."
      status         = "not-composed"
      cost_state     = "deferred"
    }
    "DR-01" = {
      stack          = "L1 Connectivity"
      domain         = "Resiliency"
      component      = "East US 2 secondary hub"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "multi-region-connectivity"
      implementation = "Reuse Phase 1 hub modules with second-region inputs; secondary hub root is not yet composed."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "DR-02" = {
      stack          = "L1 Connectivity"
      domain         = "Resiliency"
      component      = "Cross-region connectivity"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "multi-region-connectivity"
      implementation = "virtual-network-gateway-connection and vnet-peering modules are available; ExpressRoute Global Reach/provider-specific configuration remains Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "DR-04" = {
      stack          = "L2 Management"
      domain         = "Resiliency"
      component      = "Backup replication and geo-redundancy"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "resiliency-services"
      implementation = "recovery-services-vault module is available; geo-redundant backup and replication policy composition is Phase 2."
      status         = "module-only"
      cost_state     = "deferred"
    }
    "DR-05" = {
      stack          = "L2 Management"
      domain         = "Resiliency"
      component      = "RTO/RPO targets and DR runbooks"
      phase          = "Phase 2"
      criticality    = "Deferred"
      workspace      = "platform-management or platform-connectivity"
      pattern        = "dr-runbooks"
      implementation = "Documentation and test plan item; no Terraform resources should be created for this row."
      status         = "documentation"
      cost_state     = "deferred"
    }
  }

  implementation_overrides = {
    for id, override in var.implementation_overrides : id => {
      for key, value in override : key => value
      if value != null
    }
  }

  component_coverage = {
    for id, component in merge(local.phase1_components, local.phase2_components) :
    id => merge(component, try(local.implementation_overrides[id], {}))
  }

  invalid_criticality_components = [
    for id, component in local.component_coverage : id
    if !contains(local.valid_criticalities, component.criticality)
  ]

  invalid_status_components = [
    for id, component in local.component_coverage : id
    if !contains(local.valid_statuses, component.status)
  ]

  missing_required_components = [
    for id, component in local.component_coverage : id
    if component.phase == "Phase 1 (MVP)" && contains(["Blocking", "Critical"], component.criticality) && contains(local.phase1_required_gap_status, component.status)
  ]

  implementation_summary = {
    for status in local.valid_statuses :
    status => length([
      for component in values(local.component_coverage) : component
      if component.status == status
    ])
  }
}

resource "terraform_data" "coverage_contract" {
  input = local.component_coverage

  lifecycle {
    precondition {
      condition     = length(local.invalid_criticality_components) == 0
      error_message = "Every platform component must use Blocking, Critical, or Enabling criticality."
    }

    precondition {
      condition     = length(local.invalid_status_components) == 0
      error_message = "Every platform component must use an approved implementation status."
    }

    precondition {
      condition     = length(local.missing_required_components) == 0
      error_message = "Phase 1 Blocking and Critical components cannot be advisory-only or missing a deployable/root contract in the platform pattern contract."
    }
  }
}
