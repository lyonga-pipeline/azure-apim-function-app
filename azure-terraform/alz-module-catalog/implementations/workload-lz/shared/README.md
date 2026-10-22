# Legacy Workload Deployment Adapter

Deprecated for new deployments. Active production/non-production roots call an
independently pinned blueprint directly; they no longer load this directory.
See [environment isolation and migration](../ISOLATION.md).

This adapter is retained for existing explicit consumers and its compatibility
tests. Do not remove it from an existing deployment without reviewing the
same-state `moved` declarations supplied in the new roots. It does not share
state by itself, but its local source couples consumers to the live checkout.
