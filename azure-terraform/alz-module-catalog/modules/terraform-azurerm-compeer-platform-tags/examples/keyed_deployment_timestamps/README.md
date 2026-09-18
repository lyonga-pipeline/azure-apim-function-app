# Keyed Deployment Timestamps

Demonstrates the per-resource variant of the `created_on` idiom shown in
`../basic`: instead of one root-wide `time_static`, key a `time_static` by
the same stable key as a growing resource map (here, storage accounts).

## Use this example when

- A root manages a growing collection with `for_each`.
- Collection entries can be added on different dates.
- Each resource needs its own accurate first-deployed date.
- The same stable keys are used for the resource, `time_static`, and tag
  module instances.

A single shared `time_static` would give every resource the same `created_on`,
including resources added months later. Keying it lets each entry keep its own
frozen date. Adding a new key creates only that key's `time_static`; existing
keys continue reading their original values from state.

Use meaningful, stable keys such as `orders` and `invoices`. Do not derive
keys from list indexes, because reordering a list could change instance
identity and produce unnecessary replacement.

## When to use the basic example instead

Use [`../basic`](../basic) when the root represents one deployment unit or
all resources should share one deployment-level `created_on` value. That is
the simpler default and avoids creating timestamp state for every item when
independent dates provide no benefit.

The test in `tests/keyed.tftest.hcl` first creates one key and then adds a
second. It proves that the first key keeps its original date while the new key
receives its own timestamp.
