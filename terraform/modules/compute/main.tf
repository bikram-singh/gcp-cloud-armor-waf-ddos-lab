# ---------------------------------------------------------------------------
# Artifact Registry â€” pinned vuln-bank web image lives here. Build/push it
# with scripts/build-push-vulnbank-image.sh (see repo root) BEFORE running
# `terraform apply` on this module â€” Terraform references the image by tag,
# it doesn't build it.
# ---------------------------------------------------------------------------
resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = var.artifact_repo_id
  format        = "DOCKER"
  description   = "Pinned images for gcp-cloud-armor-waf-ddos-lab (vuln-bank web image)"
  labels        = var.labels
}

locals {
  vulnbank_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_id}/vuln-bank-web:${var.vulnbank_image_tag}"
}

# ---------------------------------------------------------------------------
# Service account for both VMs â€” least-privilege: only what's needed to pull
# from Artifact Registry. See docs/iam-least-privilege.md for the full
# reasoning (this mirrors the same principle applied to the Actions SA).
# ---------------------------------------------------------------------------
resource "google_service_account" "lab_vm" {
  project      = var.project_id
  account_id   = "cloud-armor-lab-vm"
  display_name = "Cloud Armor Lab VM (least-privilege: Artifact Registry read only)"
}

resource "google_project_iam_member" "lab_vm_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.lab_vm.email}"
}

resource "google_project_iam_member" "lab_vm_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.lab_vm.email}"
}

# ---------------------------------------------------------------------------
# nginx VM â€” simple backend for the path-based CEL demo (/goodpath, /badpath)
# ---------------------------------------------------------------------------
resource "google_compute_instance" "nginx" {
  project      = var.project_id
  zone         = var.zone
  name         = "cloud-armor-lab-nginx"
  machine_type = var.nginx_machine_type
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link

  }

  metadata_startup_script = file("${path.module}/startup-nginx.sh")

  service_account {
    email  = google_service_account.lab_vm.email
    scopes = ["cloud-platform"]
  }

  tags = ["cloud-armor-lab", "backend-nginx"]
}

# ---------------------------------------------------------------------------
# vuln-bank VM â€” pulls the pre-built pinned image, no build at boot
# ---------------------------------------------------------------------------
resource "google_compute_instance" "vulnbank" {
  project      = var.project_id
  zone         = var.zone
  name         = "cloud-armor-lab-vulnbank"
  machine_type = var.vulnbank_machine_type
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20 # a little headroom for the Postgres volume
    }
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link

  }

  metadata_startup_script = templatefile("${path.module}/startup-vulnbank.sh.tpl", {
    region          = var.region
    vulnbank_image  = local.vulnbank_image
    db_name         = var.db_name
    db_user         = var.db_user
    db_password     = var.db_password
  })

  service_account {
    email  = google_service_account.lab_vm.email
    scopes = ["cloud-platform"]
  }

  tags = ["cloud-armor-lab", "backend-vulnbank"]

  depends_on = [google_artifact_registry_repository.images]
}
