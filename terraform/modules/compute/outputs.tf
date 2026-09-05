output "nginx_instance_self_link" {
  value = google_compute_instance.nginx.self_link
}

output "nginx_instance_zone" {
  value = google_compute_instance.nginx.zone
}

output "vulnbank_instance_self_link" {
  value = google_compute_instance.vulnbank.self_link
}

output "vulnbank_instance_zone" {
  value = google_compute_instance.vulnbank.zone
}

output "artifact_registry_repo_url" {
  description = "Full path prefix — push images as <this>/vuln-bank-web:<tag>"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_id}"
}

output "vulnbank_image" {
  value = local.vulnbank_image
}
