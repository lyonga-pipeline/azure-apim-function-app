# Compeer Palo Alto Hub Pattern

Composes Azure-side Palo Alto VM-Series hub resources:

- Optional bootstrap storage account and shares
- Zone-redundant Standard public IPs
- Palo Alto NICs with IP forwarding
- Trust and untrust load balancers
- Palo Alto VM-Series Linux virtual machines

Panorama or Strata Cloud Manager policy onboarding remains a separate operational contract unless the team chooses a PAN-OS provider workflow. Keep this pattern disabled until firewall licensing, image plan acceptance, bootstrap process, and routing ownership are approved.
