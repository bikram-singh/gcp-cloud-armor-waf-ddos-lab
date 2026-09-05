output "policy_id" {
  value = google_compute_organization_security_policy.this.id
}

output "association_id" {
  value = google_compute_organization_security_policy_association.this.id
}
