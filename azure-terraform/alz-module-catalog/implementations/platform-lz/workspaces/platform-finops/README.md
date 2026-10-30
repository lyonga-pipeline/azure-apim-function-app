# platform-finops

## PHASE 2 Implementation

One subscription-scoped FinOps root per independently owned subscription. Policies and exemptions are deliberately not exposed here.

This is a canonical owner-aligned root, not a phase-selected workspace. See [engineering handoff](../../../phase2/ENGINEERING-HANDOFF.md) for the exact file/ownership map and release dependencies.

- `terraform.tfvars.example` is inert reference configuration; it is not auto-loaded.
- Where present, `approved-pilot.tfvars.example` exercises enabled capabilities with synthetic inputs, not production approvals.
- Use a separate HCP workspace/state, scoped run identity, main-branch working directory and trigger path. Instantiate another root for independently promoted subscriptions/environments.
- Sources are local catalog paths for integration testing. Publish and pin approved registry releases before actual deployment. Do not select environment or module version through runtime tfvars.
- Existing resources stay in their current states. These new Phase 2 roots have not been applied; no state migration is automated here.

No new ARM resource locks or Phase 3 resources are introduced. Read [live acceptance](../../../phase2/RUNBOOKS.md) before enabling a capability.
