output "external_ip" {
  value = google_compute_global_address.this.address
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
