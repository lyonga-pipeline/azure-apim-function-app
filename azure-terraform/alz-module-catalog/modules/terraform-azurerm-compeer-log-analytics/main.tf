/*
This module intentionally owns only the Log Analytics workspace resource.

Compose resource groups, workspace RBAC, Defender for Cloud associations,
diagnostic settings, and management solutions in a pattern/root module so each
concern can evolve with a distinct lifecycle.
*/
