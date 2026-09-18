# Basic Platform Tags

This example emits the standard enterprise tag map used by platform and
workload patterns. It creates one `time_static` resource in the consuming
root and passes its date to the tag module as `created_on`.

## Use this example when

- The root deploys one component or deployment unit.
- Every resource in the root should share the root's first-deployed date.
- A simple, stable `created_on` value is more accurate than a separate date
  for every repeated resource.

`time_static` generates its value during the first apply and stores it in
Terraform state. Later plans reuse the same value, so `created_on` does not
change on every run. Do not replace it with `timestamp()`, which is evaluated
again and can create perpetual tag changes.

## When to use the keyed example instead

Use [`../keyed_deployment_timestamps`](../keyed_deployment_timestamps) when
the root manages a growing `for_each` collection and each entry needs its own
true first-deployed date. For example, a storage account added in March should
not inherit the January creation date of an existing storage account.

The tag module does not enforce missing tags. It reports them through
`missing_mandatory`; OPA and Azure Policy enforce the final tag requirements
for landing-zone deployments.

The test in `tests/basic.tftest.hcl` applies the example and then plans it
again to prove that the original `created_on` value remains unchanged.
