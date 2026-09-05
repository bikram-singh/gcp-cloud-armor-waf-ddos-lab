output "policy_id" {
  value = var.regional ? google_compute_region_security_policy.regional[0].id : google_compute_security_policy.global[0].id
}

output "self_link" {
  description = "Wire into a passthrough Network LB's backend service `security_policy` field — no such backend exists in this lab yet"
  value       = var.regional ? google_compute_region_security_policy.regional[0].self_link : google_compute_security_policy.global[0].self_link
}
