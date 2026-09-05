# ---------------------------------------------------------------------------
# Self-signed TLS cert, generated automatically — this is a lab with no real
# domain, so there's no DNS to hang a Google-managed cert off. Demo scripts
# hitting this LB need `curl -k` (or your browser will show a cert warning,
# click through it). If you later attach a real domain, swap this block for
# a `google_compute_managed_ssl_certificate` referencing that domain instead.
# ---------------------------------------------------------------------------
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "${var.name_prefix}.cloud-armor-lab.internal"
    organization = "gcp-cloud-armor-waf-ddos-lab"
  }

  validity_period_hours = 24 * 90 # 90 days — re-apply if the lab outlives this
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_compute_ssl_certificate" "this" {
  project     = var.project_id
  name_prefix = "${var.name_prefix}-selfsigned-"
  private_key = tls_private_key.this.private_key_pem
  certificate = tls_self_signed_cert.this.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Backend service — Cloud Armor attaches here
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
# URL map — single default service. No path matchers needed: the path-based
# demo (/goodpath, /badpath) is a Cloud Armor CEL rule matching
# request.path, evaluated BEFORE traffic ever reaches this LB routing layer
# — not a GCP URL-map routing decision. Keep this simple on purpose.
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
  ssl_certificates = [google_compute_ssl_certificate.this.id]
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
