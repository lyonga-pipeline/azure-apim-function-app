# Platform Management Root

This root creates the shared observability foundation for a landing-zone environment.

It produces the Log Analytics workspace ID and action group ID consumed by platform and workload roots.

For short smoke tests, `terraform.tfvars` leaves `defender_plans = {}` so Microsoft Defender for Cloud paid Standard plans are not enabled accidentally. The Standard plan map is left commented in the tfvars file; uncomment it only after cost approval and when you are ready to test the security baseline.

Use this root for central monitoring, activity-log diagnostics, Entra diagnostics, action groups, subscription budgets, security contact configuration, and Defender plan enablement. Add Sentinel onboarding and data-collection rules here when the SOC/SIEM design is approved.
