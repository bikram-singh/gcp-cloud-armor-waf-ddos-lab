output "external_ip" {
  value = google_compute_global_address.this.address
}

output "external_ipv6" {
  description = "Null unless enable_ipv6 = true"
  value       = var.enable_ipv6 ? google_compute_global_address.ipv6[0].address : null
}

output "backend_service_self_link" {
  value = google_compute_backend_service.this.self_link
}

output "backend_service_name" {
  value = google_compute_backend_service.this.name
}

output "url_map_self_link" {
  value = google_compute_url_map.this.self_link
}
