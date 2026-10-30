# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
output "phase2_observability" {
  description = "Additive Phase 2 resource IDs; null until capabilities are explicitly enabled."
  value       = try(module.phase2_observability[0], null)
}
