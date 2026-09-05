output "self_links" {
  description = "Map of group key -> instance group self_link"
  value       = { for k, v in google_compute_instance_group.this : k => v.self_link }
}

output "ids" {
  value = { for k, v in google_compute_instance_group.this : k => v.id }
}
