# Global Governance Root

This root creates the management-group scaffold and subscription placement for the net-new landing-zone path.

It receives IDs explicitly from HCP workspace variables or an approved governance catalog. It does not read legacy remote state or infer subscription placement from environment names.

The root supports both individual Azure Policy definitions and policy set definitions/initiatives. Use policy set definitions for the baseline landing-zone initiative so approved regions, required tags, public access, encryption, diagnostics, identity, and connectivity guardrails can be assigned as one scoped package at the net-new landing-zone management group.
