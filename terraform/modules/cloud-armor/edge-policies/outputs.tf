output "policy_id" {
  value = google_compute_security_policy.edge.id
}

output "policy_name" {
  value = google_compute_security_policy.edge.name
}

output "self_link" {
  description = "Wire this into a backend bucket's edge_security_policy field"
  value       = google_compute_security_policy.edge.self_link
}
