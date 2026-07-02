# Platform Management Root

This root creates the shared observability foundation for a landing-zone environment.

It produces the Log Analytics workspace ID and action group ID consumed by platform and workload roots.

For short smoke tests, `terraform.tfvars` leaves `defender_plans = {}` so Microsoft Defender for Cloud paid Standard plans are not enabled accidentally. The Standard plan map is left commented in the tfvars file; uncomment it only after cost approval and when you are ready to test the security baseline.

The smoke-test tfvars also leave `security_contact = null` and `security_center_settings = {}`. Defender settings such as `MCAS` and `WDATP` commonly already exist in Azure subscriptions, so Terraform must import them before it can manage them. Leave them unmanaged for quick platform validation; import and enable them when promoting the enterprise security baseline.

Use this root for central monitoring, activity-log diagnostics, Entra diagnostics, action groups, subscription budgets, security contact configuration, and Defender plan enablement. Add Sentinel onboarding and data-collection rules here when the SOC/SIEM design is approved.

## HCP Azure Dynamic Credentials

If a run fails before planning with `AADSTS700213: No matching federated identity record found`, the Entra app configured by `TFC_AZURE_RUN_CLIENT_ID` does not trust this HCP workspace subject yet.

For workspace `platform-management` in HCP organization `lyonga-org` and project `demo`, create federated identity credentials on the Entra application for both run phases:

```text
organization:lyonga-org:project:demo:workspace:platform-management:run_phase:plan
organization:lyonga-org:project:demo:workspace:platform-management:run_phase:apply
```

Use issuer `https://app.terraform.io` with no trailing slash and audience `api://AzureADTokenExchange` unless `TFC_AZURE_WORKLOAD_IDENTITY_AUDIENCE` is explicitly configured. Repeat this per workspace because Azure federated identity credentials are matched by exact subject string.
