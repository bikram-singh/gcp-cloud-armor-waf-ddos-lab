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
# here -- project creation needs a billing account ID, cleaner to do once
# via gcloud projects create / gcloud billing projects link before this
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
  for_each                   = toset(local.required_apis)
  project                    = var.project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}

# ---------------------------------------------------------------------------
# Networking. No external IPs on the VMs (org policy
# constraints/compute.vmExternalIpAccess blocks it) -- Cloud NAT below
# gives them outbound internet for apt-get / docker pull / gcloud calls
# during their startup scripts, and traffic reaches them through the LBs
# via internal IP, never directly.
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

resource "google_compute_router" "lab" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.lab.id
}

resource "google_compute_router_nat" "lab" {
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.lab.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Allow Google's health checkers and the LB proxy range to reach backends.
# Required for any HTTPS LB backend to ever report healthy -- a common
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

# Allows SSH via IAP tunneling (gcloud compute ssh --tunnel-through-iap)
# since the VMs have no external IP for direct SSH anymore.
resource "google_compute_firewall" "allow_iap_ssh" {
  name          = "${var.network_name}-allow-iap-ssh"
  network       = google_compute_network.lab.id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"] # Google's IAP TCP forwarding range

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# ---------------------------------------------------------------------------
# Compute -- nginx (path-based demo) + vuln-bank (SQLi/XSS/rate-limit demos)
# ---------------------------------------------------------------------------
module "compute" {
  source               = "../../modules/compute"
  project_id           = var.project_id
  region               = var.region
  zone                 = var.zone
  network_self_link    = google_compute_network.lab.self_link
  subnetwork_self_link = google_compute_subnetwork.primary.self_link
  labels               = var.labels
  vulnbank_image_tag   = var.vulnbank_image_tag

  depends_on = [google_project_service.required]
}

# ---------------------------------------------------------------------------
# Instance groups -- one per backend app (different ports, different apps)
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
# Cloud Armor rules -- sourced from terraform/policies (a shared module so
# future environments can reuse the same rule definitions).
#
# address_group_rules and threat_intelligence_rules are DELIBERATELY
# EXCLUDED from the concat() below -- confirmed via real terraform apply
# error that this project does not have a Cloud Armor Enterprise
# subscription, which both of those rule types require. See
# docs/standard-vs-enterprise.md. Re-add both lines to the concat() list
# if/when Enterprise is active on this project.
# ---------------------------------------------------------------------------
module "policies" {
  source           = "../../policies"
  address_group_id = "projects/${var.project_id}/locations/global/addressGroups/lab-trusted-ips"
}

module "baseline_policy" {
  source      = "../../modules/cloud-armor/backend-policies"
  project_id  = var.project_id
  policy_name = "lab-baseline-policy"
  description = "Baseline + preconfigured WAF rules for gcp-cloud-armor-waf-ddos-lab"

  # Policy-wide settings (not per-rule -- see rules-logging-modes.tf and
  # rules-user-ip-header.tf for why these two aren't part of the rules list)
  log_level               = module.policies.demo_log_level
  user_ip_request_headers = module.policies.demo_user_ip_headers

  rules = concat(
    module.policies.baseline_rules,
    module.policies.preconfigured_waf_rules,
    module.policies.ip_based_rules,
    module.policies.ipv6_rules,
    module.policies.geo_based_rules,
    module.policies.path_based_rules,
    module.policies.rate_limit_rules,
    module.policies.rate_limit_ja3_rules,
    module.policies.rate_limit_ja4_rules,
    module.policies.redirect_rules,
    # module.policies.address_group_rules,       # Enterprise required
    # module.policies.threat_intelligence_rules,  # Enterprise required
    # module.policies.waf_tuning_rules is intentionally NOT included here --
    # it's a swap-in replacement for preconfigured_waf_rules, not additive.
    # See rules-waf-tuning.tf for the demo procedure.
  )
}

# ---------------------------------------------------------------------------
# HTTPS Load Balancers -- one per backend app, both sharing the same Cloud
# Armor policy above (swap/extend policies per rules-*.tf file as those get
# built; both LBs stay wired to whichever policy module.baseline_policy
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
  enable_ipv6               = true # needed for rules-ip-based-ipv6.tf's demo -- see 02b-ipv6-allow-deny.sh
}

# ---------------------------------------------------------------------------
# Address groups -- COMMENTED OUT. Confirmed via real terraform apply
# error: "does not have a Cloud Armor Enterprise subscription, which is
# required to use the CLOUD_ARMOR purpose". Uncomment (and re-add
# address_group_rules to the concat() above) once Enterprise is active on
# this project.
# ---------------------------------------------------------------------------
# module "trusted_ips" {
#   source     = "../../modules/address-groups"
#   name       = "lab-trusted-ips"
#   project_id = var.project_id
#   items      = ["106.219.121.230/32"]
# }
