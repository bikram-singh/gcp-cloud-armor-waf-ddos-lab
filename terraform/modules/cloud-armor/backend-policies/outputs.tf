output "policy_id" {
  description = "ID of the created security policy (global or regional)"
  value       = var.regional ? google_compute_region_security_policy.regional[0].id : google_compute_security_policy.global[0].id
}

output "policy_name" {
  description = "Name of the created security policy"
  value       = var.regional ? google_compute_region_security_policy.regional[0].name : google_compute_security_policy.global[0].name
}

output "self_link" {
  description = "Self-link, for wiring into a backend service's security_policy field"
  value       = var.regional ? google_compute_region_security_policy.regional[0].self_link : google_compute_security_policy.global[0].self_link
}
