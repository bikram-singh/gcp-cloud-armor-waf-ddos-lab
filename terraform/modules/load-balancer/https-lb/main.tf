# ---------------------------------------------------------------------------
# TLS certificate -- two mutually exclusive paths:
#   1. domain_name set: Google-managed cert, auto-renews, browsers trust it,
#      but takes 15-60+ min to provision AFTER DNS actually resolves to this
#      LB's IP (provisioning starts as soon as the resource applies, but
#      Google can't validate/issue until DNS is live and correct).
#   2. domain_name null (default): self-signed cert generated at apply time,
#      works immediately, browsers show a trust warning (expected for a lab
#      with no domain).
# ---------------------------------------------------------------------------
resource "google_compute_managed_ssl_certificate" "this" {
  count   = var.domain_name != null ? 1 : 0
  project = var.project_id
  name    = "${var.name_prefix}-managed-cert"

  managed {
    domains = [var.domain_name]
  }
}

resource "tls_private_key" "this" {
  count     = var.domain_name == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "this" {
  count           = var.domain_name == null ? 1 : 0
  private_key_pem = tls_private_key.this[0].private_key_pem

  subject {
    common_name  = "${var.name_prefix}.cloud-armor-lab.internal"
    organization = "gcp-cloud-armor-waf-ddos-lab"
  }

  validity_period_hours = 24 * 90
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_compute_ssl_certificate" "this" {
  count       = var.domain_name == null ? 1 : 0
  project     = var.project_id
  name_prefix = "${var.name_prefix}-selfsigned-"
  private_key = tls_private_key.this[0].private_key_pem
  certificate = tls_self_signed_cert.this[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  ssl_certificate_ids = var.domain_name != null ? [
    google_compute_managed_ssl_certificate.this[0].id
    ] : [
    google_compute_ssl_certificate.this[0].id
  ]
}

# ---------------------------------------------------------------------------
# Backend service -- Cloud Armor attaches here
# ---------------------------------------------------------------------------
resource "google_compute_health_check" "this" {
  project = var.project_id
  name    = "${var.name_prefix}-healthcheck"

  http_health_check {
    port = var.port
  }
}

resource "google_compute_backend_service" "this" {
  project               = var.project_id
  name                  = "${var.name_prefix}-backend"
  protocol              = var.protocol
  port_name             = var.port_name
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.this.id]
  security_policy       = var.security_policy_self_link

  backend {
    group = var.instance_group_self_link
  }
}

# ---------------------------------------------------------------------------
# URL map -- single default service. No path matchers needed: the path-based
# demo (/goodpath, /badpath) is a Cloud Armor CEL rule matching request.path,
# evaluated BEFORE traffic ever reaches this LB routing layer.
# ---------------------------------------------------------------------------
resource "google_compute_url_map" "this" {
  project         = var.project_id
  name            = "${var.name_prefix}-urlmap"
  default_service = google_compute_backend_service.this.id
}

resource "google_compute_target_https_proxy" "this" {
  project          = var.project_id
  name             = "${var.name_prefix}-https-proxy"
  url_map          = google_compute_url_map.this.id
  ssl_certificates = local.ssl_certificate_ids
}

resource "google_compute_global_address" "this" {
  project = var.project_id
  name    = "${var.name_prefix}-lb-ip"
}

resource "google_compute_global_forwarding_rule" "this" {
  project               = var.project_id
  name                  = "${var.name_prefix}-fwd-rule"
  target                = google_compute_target_https_proxy.this.id
  port_range            = "443"
  ip_address            = google_compute_global_address.this.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ---------------------------------------------------------------------------
# Optional second IPv6 frontend -- same backend/URL map/proxy, second
# address + forwarding rule so IPv4 and IPv6 clients both reach the same
# backend service (and therefore the same Cloud Armor policy).
# ---------------------------------------------------------------------------
resource "google_compute_global_address" "ipv6" {
  count      = var.enable_ipv6 ? 1 : 0
  project    = var.project_id
  name       = "${var.name_prefix}-lb-ipv6"
  ip_version = "IPV6"
}

resource "google_compute_global_forwarding_rule" "ipv6" {
  count                 = var.enable_ipv6 ? 1 : 0
  project               = var.project_id
  name                  = "${var.name_prefix}-fwd-rule-ipv6"
  target                = google_compute_target_https_proxy.this.id
  port_range            = "443"
  ip_address            = google_compute_global_address.ipv6[0].id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
