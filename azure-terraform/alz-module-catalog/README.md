# Compeer ALZ Module Catalog

This directory is the platform reference catalog for the ALZ conversion. It keeps the Compeer module structure, preserves the local Terraform module boundaries, and stages the modules/patterns needed to mirror the implementation in the existing landing-zone roots.

## Review standard

The catalog follows a stricter review rule than the earlier drafts:

- Ready: the module exists in the Compeer repo under the shared source directory and is materially complete; it is a real module with matching Terraform files, variables, outputs, and a clear lifecycle boundary.
- Missing: the platform capability is required for the ALZ pattern, but there is no corresponding module under the Compeer source repo to reuse directly.
- Incomplete: the module exists in the catalog but is still placeholder/thin or not materially upgraded from the original source; it should not be marked Ready until the missing implementation is completed.

This means the review should not mark a catalog module as Ready just because it has a README and a source path. A module is Ready only if the equivalent code in the Compeer repo is actually present and complete.

## Structure

- `modules/` contains reusable Azure and Cloudflare resource modules that mirror the Compeer source layout.
- `patterns/` contains the platform compositions that wire the resource modules into the landing-zone slices.
- `implementations/platform-lz/` is the end-to-end platform landing zone that composes the patterns with Terraform Cloud registry versions where available and local paths where the module is not yet published.
- `MODULE_REVIEW.md` contains the status matrix and the module-by-module rationale.

## Source-of-truth rule for this catalog

The source of truth for module readiness is:

- `../compeer-modules` for all modules already implemented by the Compeer repo.
- `../azure-terraform/modules` for local platform modules that are required by the ALZ pattern but are not yet available in the shared Compeer module repo.

Where a module exists in Compeer and the catalog copy is materially aligned to it, it can be considered Ready. Where the module does not exist in Compeer, the row should be marked Missing. Where the module is only a thin wrapper or generated placeholder, the row should be marked Incomplete.

## Platform coverage

The catalog currently supports the platform slices needed for the net-new hub/spoke ALZ model:

- Management groups and subscription vending
- Global governance and policy baseline
- Platform management, monitoring, and log analytics
- Connectivity, private DNS, NSGs, route tables, public IPs, NAT, and load balancers
- Optional hybrid connectivity for ExpressRoute and VPN
- Platform identity and Key Vault foundation
- Workload-spoke networking and peering
- Optional Palo Alto hub and Cloudflare edge baseline

## Compeer upgrade expectation

The catalog modules are intentionally designed to stay easy to cross-reference with the Compeer code. The folder names, Terraform file names, and module boundaries mirror the existing Compeer repos so a team can compare both sides and cherry-pick the same upgrade into the source module repo.

For example, the Key Vault module was upgraded from the baseline Compeer pattern by:

- preserving the same file structure (`main.tf`, `variables.tf`, `outputs.tf`, `data.tf`, `versions.tf`),
- keeping the same lifecycle boundary as the Compeer module,
- adding RBAC compatibility, stronger defaults, and private-first network controls,
- removing placeholder behavior and aligning the catalog copy to the platform ALZ contract.

## Terraform registry usage and local fallback

The implementation root prefers the versions listed in `modules.txt` when those modules already exist in the Terraform Cloud registry. Missing or not-yet-published modules stay local to the catalog until they are available in Terraform Cloud.

This keeps the module catalog aligned with the latest registry version when the module is already available, while avoiding false readiness claims for modules that still need to be developed or published.

See `MODULE_REVIEW.md` for the detailed status matrix.
