# Compeer Sentinel

Onboards a Log Analytics workspace to Microsoft Sentinel when enabled and records the approved connector contract.

The connector contract is intentionally separated from onboarding because SOC ownership and licensing often require a staged rollout. Add concrete `azurerm_sentinel_data_connector_*` resources after connector ownership and cost are approved.
