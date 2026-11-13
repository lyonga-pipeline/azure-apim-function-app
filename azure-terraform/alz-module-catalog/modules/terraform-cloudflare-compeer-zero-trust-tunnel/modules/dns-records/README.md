# Shared DNS Records

The edge pattern and tunnel helper use this submodule as their single DNS
resource implementation. Callers pass a map with resolved `zone_id`, `name`,
`type` and `content`; optional TTL/proxy/metadata fields are preserved.
The `ids` output retains the caller's keys. No zones or tunnels are created.

The tunnel helper supplies the tunnel CNAME and security-resource dependencies.
The edge caller preserves generic records for legacy consumers. A hostname must
have one owner; resource reuse does not authorize duplicate declarations.

Run `terraform init -backend=false`, `terraform validate` and `terraform test`.
The parent callers retain `moved` blocks for their previous DNS addresses.
Their migration tests use shared mock state (Terraform 1.11 or newer for the
test runner); normal module configuration still supports Terraform 1.5+.
