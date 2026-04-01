# V2 Enterprise Pattern

This document explains the active v2 architecture used in this repository.

It focuses on:

- `global/*`
- `stacks/<env>/platform-v2/*`
- `stacks/<env>/workload-v2/*`

It does not focus on the older legacy roots under `stacks/dev/workloads`.

## Purpose Of The V2 Pattern

The v2 pattern splits the Azure estate into three clear layers:

- **global governance**
  - management groups, policy, and high-scope RBAC
- **environment platform**
  - shared connectivity, identity, and management services
- **application landing zones**
  - workload-specific spokes and application resources

This split makes ownership clear, reduces blast radius, and gives new
engineers a simpler mental model:

- governance tells teams what rules exist
- platform provides shared services
- workloads consume those shared services and own their app resources

## Why This Pattern Is Easier To Scale

- Central governance is defined once and inherited by many subscriptions.
- Shared platform services are built once per environment and reused by many
  workloads.
- Workload teams can move quickly without taking ownership of tenant-level or
  platform-level resources.
- Remote state boundaries match operational boundaries, which makes apply,
  review, and troubleshooting simpler.

## The Three Layers

### 1. Global Governance

These stacks sit at tenant or management-group scope.

They answer questions like:

- Which subscriptions exist?
- Where do they sit in the management group hierarchy?
- Which policies should they inherit?
- Which central teams get high-scope RBAC?

Active stacks:

- [`global/subscriptions`](./global/subscriptions)
- [`global/management-groups`](./global/management-groups)
- [`global/policy`](./global/policy)
- [`global/role-assignments`](./global/role-assignments)

### 2. Environment Platform

These stacks create shared services for one environment.

They answer questions like:

- Where is the hub network?
- Where do shared logs go?
- Where do shared managed identities and shared keys live?

Active stacks in `dev`:

- [`stacks/dev/platform-v2/connectivity`](./stacks/dev/platform-v2/connectivity)
- [`stacks/dev/platform-v2/management`](./stacks/dev/platform-v2/management)
- [`stacks/dev/platform-v2/identity`](./stacks/dev/platform-v2/identity)

### 3. Workload Landing Zones

These stacks create application-specific resources.

They answer questions like:

- What does this application own?
- Which spoke network belongs to this application?
- Which shared platform services does it consume?

Active example:

- [`stacks/dev/workload-v2/finserv-api`](./stacks/dev/workload-v2/finserv-api)

## Stack-By-Stack Summary

### `global/subscriptions`

Purpose:

- central catalog of subscription roles and management-group placement

Used by:

- `global/management-groups`
- platform and workload stacks that validate their explicit subscription IDs

Why it matters:

- keeps subscription IDs and placement out of individual stack configs

### `global/management-groups`

Purpose:

- creates the management group hierarchy and attaches subscriptions

Used by:

- `global/policy`
- `global/role-assignments`

Why it matters:

- policy and RBAC inheritance only scale cleanly when the hierarchy is defined
  centrally

### `global/policy`

Purpose:

- defines and assigns shared governance guardrails

Used by:

- every platform and workload stack through inheritance

Why it matters:

- teams should inherit common controls instead of rebuilding them per
  subscription

### `global/role-assignments`

Purpose:

- seeds high-scope RBAC for central platform and governance roles

Used by:

- deployment identities and central operator teams

Why it matters:

- separates tenant and management-group access from workload-local RBAC
- lets you codify inherited management-group RBAC in Git instead of relying on
  manual portal assignments

Notes:

- `Reader` assignments provide visibility only and do not allow deployments
- a deployer assigned at `platform` inherits access to child branches such as
  `security`
- that same `platform` assignment does not grant access to `prod`, because
  `prod` is under the separate `landing_zones` branch
- dedicated `security` and `prod` deployer identities can be granted
  `Contributor` plus `User Access Administrator` so they can deploy resources
  and manage Terraform-created RBAC in those branches

### `platform-v2/connectivity`

Purpose:

- shared hub networking and shared Private DNS

Used by:

- identity and workload spokes

Why it matters:

- central networking and DNS are easier to standardize and reuse

### `platform-v2/management`

Purpose:

- shared monitoring, archive, alerting, and recovery services

Used by:

- identity and workload stacks that send telemetry to the shared management
  plane

Why it matters:

- gives the environment one known destination for diagnostics and operations

### `platform-v2/identity`

Purpose:

- shared identities, shared Key Vault, and shared customer-managed key

Used by:

- platform automation
- workloads that consume shared identities or the shared CMK

Why it matters:

- long-lived shared identity assets should not be tied to one application

### `workload-v2/finserv-api`

Purpose:

- reference application landing zone that consumes the shared platform

Used by:

- app deployment pipelines
- operator and validation workflows

Why it matters:

- shows teams how to build a new landing zone without breaking the platform
  ownership model

## How The Layers Work Together

1. `global/subscriptions` defines the subscription catalog.
2. `global/management-groups` creates the hierarchy and places subscriptions.
3. `global/policy` and `global/role-assignments` apply governance at the right
   scope.
4. `platform-v2/connectivity` creates the shared network and DNS foundation.
5. `platform-v2/management` creates the shared operations plane.
6. `platform-v2/identity` creates shared identities, keys, and private
   identity services.
7. `workload-v2/*` stacks create app landing zones and consume the shared
   platform outputs.

## Why The Split Matters

### Global vs platform vs workload

These layers should stay separate because they have different ownership and
different blast radius.

- A change to `global/*` can affect many subscriptions.
- A change to `platform-v2/*` can affect many workloads in one environment.
- A change to `workload-v2/*` should mainly affect one application landing
  zone.

That separation makes approvals, troubleshooting, and day-to-day operations
much easier.

### Shared services stay in platform stacks

Connectivity, shared identities, and shared monitoring are not application
features.

Keeping them in platform stacks gives every application team the same shared
foundation and keeps app stacks focused on app concerns.

### Hubs do not need to be global

In this pattern, the hub network is treated as an environment platform asset.

That means:

- a shared hub per environment is a valid and strong enterprise pattern
- one single global hub for every environment is not required
- as the organization grows, hubs are often split further by region or security
  boundary

This is usually easier to operate than forcing all spokes in every environment
through one global hub, especially in regulated environments where prod and
nonprod often need different controls.

### Workloads own workload-local resources

The workload layer should own:

- its resource group
- its spoke network
- its private endpoints
- its app services and databases
- its workload-local RBAC

This makes ownership clear and keeps platform stacks from becoming application
delivery stacks.

## New Team Onboarding Path

Use this read order when onboarding a new engineer to the repository.

The goal is to help them understand the pattern from the outside in:

- first the operating model
- then the governance model
- then the shared platform
- then the workload example

### Step 1. Read The V2 Guide First

Start here:

- [`README-v2.md`](./README-v2.md)

What the engineer should learn:

- the three-layer model
- why global, platform, and workload stacks are separate
- which stacks are shared providers and which stacks are consumers

### Step 2. Read The Global Governance Stacks

Read in this order:

1. [`global/subscriptions`](./global/subscriptions)
2. [`global/management-groups`](./global/management-groups)
3. [`global/policy`](./global/policy)
4. [`global/role-assignments`](./global/role-assignments)

What the engineer should learn:

- how subscriptions are cataloged
- how subscriptions are placed into management groups
- where policy guardrails are defined and assigned
- where high-scope RBAC is managed

Why this order matters:

- it shows the control plane before the engineer starts reading environment
  stacks
- it answers the common onboarding question, "Who controls what before a
  workload is even deployed?"

### Step 3. Read The Environment Platform Stacks

Read in this order:

1. [`stacks/dev/platform-v2/connectivity`](./stacks/dev/platform-v2/connectivity)
2. [`stacks/dev/platform-v2/management`](./stacks/dev/platform-v2/management)
3. [`stacks/dev/platform-v2/identity`](./stacks/dev/platform-v2/identity)

What the engineer should learn:

- where shared network services live
- where shared logs and alerts live
- where shared identities, shared keys, and shared Key Vault live

Why this order matters:

- connectivity is the first major shared dependency
- management is the common telemetry destination
- identity depends on connectivity and management and then becomes a provider
  for workloads

### Step 4. Read The Workload Reference Stack

Read:

- [`stacks/dev/workload-v2/finserv-api`](./stacks/dev/workload-v2/finserv-api)

What the engineer should learn:

- how a workload consumes platform outputs
- how a spoke VNet is attached to the hub
- how workload-local services are separated from shared platform services
- how feature flags are used to grow a landing zone safely

This is the best starting point for engineers who need to add a new workload
landing zone.

### Step 5. Read The Legacy Workload Only For Comparison

Read only if needed:

- [`stacks/dev/workloads`](./stacks/dev/workloads)

What the engineer should learn:

- how the older pattern worked
- why the v2 split is easier to operate and extend

This should not be the main starting point for new work.

### Step 6. Then Read The Terraform Code

After the README pass, use this code-reading order inside each stack:

1. `README.md`
2. `dev.tfvars` or environment tfvars
3. `data.tf`
4. `locals.tf`
5. `main.tf`
6. `outputs.tf`

Why this order works:

- tfvars show the real shape of the stack inputs
- `data.tf` shows dependencies on other stacks
- `locals.tf` shows naming, normalization, and composition logic
- `main.tf` becomes much easier to follow after the dependencies are clear

## Questions New Engineers Should Be Able To Answer

After following the onboarding path, an engineer should be able to answer:

- Which stack owns the management group hierarchy?
- Which stack owns shared policy?
- Which stack owns shared DNS and hub networking?
- Which stack owns shared identities and shared keys?
- Which stack owns shared monitoring?
- Which resources should stay in a workload stack instead of moving into the
  platform layer?
- Which outputs must a new workload consume from the platform stacks?

## Deployment Order

Apply the active v2 path in this order:

1. [`global/subscriptions`](./global/subscriptions)
2. [`global/management-groups`](./global/management-groups)
3. [`global/policy`](./global/policy)
4. [`global/role-assignments`](./global/role-assignments)
5. [`stacks/dev/platform-v2/connectivity`](./stacks/dev/platform-v2/connectivity)
6. [`stacks/dev/platform-v2/management`](./stacks/dev/platform-v2/management)
7. [`stacks/dev/platform-v2/identity`](./stacks/dev/platform-v2/identity)
8. [`stacks/dev/workload-v2/finserv-api`](./stacks/dev/workload-v2/finserv-api)

Why this order matters:

- downstream stacks read upstream remote state
- governance should exist before subscriptions start using it
- connectivity should exist before spokes and private endpoints
- management should exist before diagnostics are wired
- identity should exist before workloads consume shared identities and keys

## How To Grow This Pattern Org-Wide

### Add more subscriptions

- Update [`global/subscriptions`](./global/subscriptions) with the new
  subscription role and target management group.
- Attach it through [`global/management-groups`](./global/management-groups).

### Add more governance

- Extend [`global/policy`](./global/policy) for new shared controls.
- Extend [`global/role-assignments`](./global/role-assignments) for new central
  operator roles.

### Add more environments

- Copy the `dev` platform and workload structure into `test`, `stage`, or
  `prod`.
- Reuse the same layer split instead of creating a new architecture per
  environment.

### Add more workloads

- Use [`stacks/dev/workload-v2/finserv-api`](./stacks/dev/workload-v2/finserv-api)
  as the reference starting point.
- Keep shared services in platform stacks.
- Keep app-specific services inside the workload stack.

## Current Project-Specific Simplifications

This repository still has a few temporary simplifications in the active
reference environment:

- `dev` is the main validated environment
- `test` and `prod` are scaffolds, not fully promoted estates
- the shared backend is pre-created outside this repository
- the current `dev` platform still groups connectivity, management, and
  identity into one platform subscription
- the `dev` workload stack includes lower-cost toggles and an optional Windows
  validation VM path so the pattern can be tested in a personal subscription
- GitHub-hosted runners required some practical accommodations for private-only
  services; the stricter target pattern is a self-hosted runner inside the
  private network boundary

These are acceptable project constraints, but they are not the final enterprise
target.

## Recommended Reading

Use these official Microsoft references when reviewing or extending the v2
pattern:

1. Azure Landing Zone overview: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/>
2. Management groups design area: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups>
3. Network topology and connectivity design area: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/network-topology-and-connectivity>
4. Identity and access design area: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access>
5. Identity in application landing zones: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access-landing-zones>
6. Azure Policy overview: <https://learn.microsoft.com/en-us/azure/governance/policy/overview>
7. Azure Policy definition scope basics: <https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure-basics>
8. Private Link and DNS integration at scale: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale>
9. App Service VNet integration: <https://learn.microsoft.com/en-us/azure/app-service/configure-vnet-integration-enable>
10. App Service VNet integration overview: <https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration>
11. Managed identity best-practice recommendations: <https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/managed-identity-best-practice-recommendations>
12. Landing zone management and monitoring: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-monitor>
