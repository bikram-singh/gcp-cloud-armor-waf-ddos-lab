resource "google_compute_subnetwork" "regional_test_proxy" {
  project       = var.project_id
  name          = "regional-test-proxy-subnet"
  region        = var.region
  ip_cidr_range = "10.20.0.0/24"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = google_compute_network.lab.id
}

resource "google_compute_firewall" "allow_regional_proxy" {
  project       = var.project_id
  name          = "${var.network_name}-allow-regional-proxy"
  network       = google_compute_network.lab.id
  direction     = "INGRESS"
  source_ranges = ["10.20.0.0/24"]

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }
}

module "regional_test_policy" {
  source      = "../../modules/cloud-armor/backend-policies"
  project_id  = var.project_id
  regional    = true
  region      = var.region
  policy_name = "lab-regional-test-policy"
  description = "TEMP TEST: regional backend security policy, separate from the global lab-baseline-policy"

  rules = [
    {
      priority    = 1000
      action      = "deny(403)"
      description = "TEMP TEST: deny by custom header to prove this REGIONAL policy enforces independently from the global one"
      expression  = "request.headers['x-lab-regional-test'] == 'true'"
    },
  ]
}

resource "google_compute_region_health_check" "regional_test" {
  project = var.project_id
  region  = var.region
  name    = "regional-test-healthcheck"

  http_health_check {
    port = 5000
  }
}

resource "google_compute_region_backend_service" "regional_test" {
  provider              = google-beta
  project               = var.project_id
  region                = var.region
  name                  = "regional-test-backend"
  protocol              = "HTTP"
  port_name             = "http-vulnbank"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.regional_test.id]
  security_policy       = module.regional_test_policy.self_link

  backend {
    group           = module.instance_groups.self_links["vulnbank"]
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_region_url_map" "regional_test" {
  project         = var.project_id
  region          = var.region
  name            = "regional-test-urlmap"
  default_service = google_compute_region_backend_service.regional_test.id
}

resource "google_compute_region_target_http_proxy" "regional_test" {
  project = var.project_id
  region  = var.region
  name    = "regional-test-http-proxy"
  url_map = google_compute_region_url_map.regional_test.id
}

resource "google_compute_address" "regional_test_ip" {
  project      = var.project_id
  region       = var.region
  name         = "regional-test-ip"
  network_tier = "STANDARD"
}

resource "google_compute_forwarding_rule" "regional_test" {
  project               = var.project_id
  region                = var.region
  name                  = "regional-test-fwd-rule"
  ip_address            = google_compute_address.regional_test_ip.id
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.regional_test.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network               = google_compute_network.lab.id
  network_tier          = "STANDARD"

  depends_on = [google_compute_subnetwork.regional_test_proxy]
}

output "regional_test_ip" {
  value = google_compute_address.regional_test_ip.address
}
