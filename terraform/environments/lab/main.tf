provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# ---------------------------------------------------------------------------
# Enable required APIs. Assumes an EXISTING GCP project (not creating one
# here — project creation needs a billing account ID, cleaner to do once via
# `gcloud projects create` / `gcloud billing projects link` before this
# applies). If compute.googleapis.com is already on, this is a harmless no-op.
# ---------------------------------------------------------------------------
locals {
  required_apis = [
    "compute.googleapis.com",             # VMs, LBs, Cloud Armor
    "networksecurity.googleapis.com",     # Address Groups
    "recaptchaenterprise.googleapis.com", # redirect-action demo
    "artifactregistry.googleapis.com",    # vuln-bank pinned image storage
    "cloudbuild.googleapis.com",          # builds the vuln-bank image (no local Docker needed)
  ]
}

resource "google_project_service" "required" {
  for_each                  = toset(local.required_apis)
  project                   = var.project_id
  service                   = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}

# ---------------------------------------------------------------------------
# Minimal networking — just enough for a backend service to exist so the
# cloud-armor module has something real to attach to. This gets replaced/
# extended once the compute, instance-groups, and load-balancer/https-lb
# modules are built (next steps after this).
# ---------------------------------------------------------------------------
resource "google_compute_network" "lab" {
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "primary" {
  name          = "${var.network_name}-primary"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.lab.id
}

# Allow Google's health checkers and the LB proxy range to reach backends.
# Required for any HTTPS LB backend to ever report healthy — a common
# first-time gotcha this lab's PDF source material called out too
# ("we have to allow firewall rule for load balancer").
resource "google_compute_firewall" "allow_lb_health_check" {
  name          = "${var.network_name}-allow-lb-healthcheck"
  network       = google_compute_network.lab.id
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  allow {
    protocol = "tcp"
  }
}

# ---------------------------------------------------------------------------
# Compute — nginx (path-based demo) + vuln-bank (SQLi/XSS/rate-limit demos)
# ---------------------------------------------------------------------------
module "compute" {
  source                = "../../modules/compute"
  project_id            = var.project_id
  region                = var.region
  zone                  = var.zone
  network_self_link     = google_compute_network.lab.self_link
  subnetwork_self_link  = google_compute_subnetwork.primary.self_link
  labels                = var.labels
  vulnbank_image_tag    = var.vulnbank_image_tag

  depends_on = [google_project_service.required]
}

# ---------------------------------------------------------------------------
# Instance groups — one per backend app (different ports, different apps)
# ---------------------------------------------------------------------------
module "instance_groups" {
  source     = "../../modules/instance-groups"
  project_id = var.project_id

  groups = {
    nginx = {
      zone       = module.compute.nginx_instance_zone
      network    = google_compute_network.lab.self_link
      instances  = [module.compute.nginx_instance_self_link]
      named_port = { name = "http", port = 80 }
    }
    vulnbank = {
      zone       = module.compute.vulnbank_instance_zone
      network    = google_compute_network.lab.self_link
      instances  = [module.compute.vulnbank_instance_self_link]
      named_port = { name = "http-vulnbank", port = 5000 }
    }
  }
}

# ---------------------------------------------------------------------------
# Cloud Armor — baseline policy
#
# TODO: once terraform/policies/rules-*.tf files exist, move the `rules`
# list below out to a local composed from those files rather than defining
# rules inline here. Kept inline for now so this environment plans/applies
# standalone.
# ---------------------------------------------------------------------------
module "baseline_policy" {
  source      = "../../modules/cloud-armor/backend-policies"
  project_id  = var.project_id
  policy_name = "lab-baseline-policy"
  description = "Baseline deny-all / allow-all priority demo"

  rules = [
    {
      priority      = 2147483647
      action        = "deny(403)"
      description   = "Default deny-all"
      src_ip_ranges = ["*"]
    },
    {
      priority      = 10
      action        = "allow"
      description   = "Allow all — demonstrates priority ordering over default deny"
      src_ip_ranges = ["*"]
    },
  ]
}

# ---------------------------------------------------------------------------
# HTTPS Load Balancers — one per backend app, both sharing the same Cloud
# Armor policy above (swap/extend policies per rules-*.tf file as those get
# built; both LBs stay wired to whichever policy `module.baseline_policy`
# currently is).
# ---------------------------------------------------------------------------
module "lb_nginx" {
  source                    = "../../modules/load-balancer/https-lb"
  project_id                = var.project_id
  name_prefix               = "nginx"
  instance_group_self_link  = module.instance_groups.self_links["nginx"]
  port_name                 = "http"
  port                      = 80
  security_policy_self_link = module.baseline_policy.self_link
}

module "lb_vulnbank" {
  source                    = "../../modules/load-balancer/https-lb"
  project_id                = var.project_id
  name_prefix               = "vulnbank"
  instance_group_self_link  = module.instance_groups.self_links["vulnbank"]
  port_name                 = "http-vulnbank"
  port                      = 5000
  security_policy_self_link = module.baseline_policy.self_link
}

# ---------------------------------------------------------------------------
# Address groups — example instantiation (commented; requires Cloud Armor
# Enterprise to actually enforce, per the module's own README). Uncomment
# once you have an Enterprise subscription active, or when demoing the
# address-groups capability specifically.
# ---------------------------------------------------------------------------
# module "trusted_ips" {
#   source     = "../../modules/address-groups"
#   name       = "lab-trusted-ips"
#   project_id = var.project_id
#   items      = ["106.219.121.230/32"] # example: your local machine's IP
# }

