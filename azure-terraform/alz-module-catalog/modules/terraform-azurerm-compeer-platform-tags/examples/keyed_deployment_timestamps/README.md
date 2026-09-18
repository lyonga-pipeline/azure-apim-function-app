# Keyed Deployment Timestamps

Demonstrates the per-resource variant of the `created_on` idiom shown in
`../basic`: instead of one root-wide `time_static`, key a `time_static` by
the same stable key as a growing resource map (here, storage accounts).

Use this shape when a root deploys resources on different dates over time -
a single shared `time_static` would give every resource the same
`created_on`, including ones added months later. Keying it lets each entry
keep its own frozen first-deployed date: adding a new key later creates only
that key's `time_static` (and therefore only that key's `created_on`) -
every already-existing key's value is read back from state, unchanged. See
`tests/keyed.tftest.hcl` for a direct demonstration.
