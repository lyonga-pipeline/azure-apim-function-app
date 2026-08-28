# Compeer Monitor Data Collection Rule

Reusable Azure Monitor Data Collection Rule module. It exposes destinations, data sources, data flows, custom streams, identity, timeouts, and tags through stable map keys so new sources or destinations can be added without recreating unrelated blocks.

The module owns only the DCR resource. Associations to VMs, Arc servers, or other resources should use the separate DCR association module so target lifecycles stay independent.
