# Network Edge Security Policies — L3/L4 protection for passthrough
# Network Load Balancers. CONFIRMED: google_compute_security_policy (and
# its regional counterpart) directly supports type = "CLOUD_ARMOR_NETWORK"
# — no separate service-attachment resource needed for the policy itself,
# correcting my earlier assumption that a google_compute_network_edge_
# security_service resource was required.
#
# Attachment: wire this policy's self_link into the `security_policy`
# field of a google_compute_region_backend_service (or equivalent) that
# fronts a passthrough Network LB — NOT built in this lab, since this
# lab's LBs are both Application/HTTPS LBs (see docs/architecture.md and
# docs/enterprise-features/advanced-network-ddos.md for the same
# architectural gap already documented there).

locals {
  ip_rules  = { for r in var.rules : tostring(r.priority) => r if r.src_ip_ranges != null }
  cel_rules = { for r in var.rules : tostring(r.priority) => r if r.src_ip_ranges == null }
}

resource "google_compute_security_policy" "global" {
  count       = var.regional ? 0 : 1
  project     = var.project_id
  name        = var.policy_name
  description = var.description
  type        = "CLOUD_ARMOR_NETWORK"
}

resource "google_compute_security_policy_rule" "global_ip" {
  for_each        = var.regional ? {} : local.ip_rules
  project         = var.project_id
  security_policy = google_compute_security_policy.global[0].name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = each.value.src_ip_ranges
    }
  }
}

resource "google_compute_security_policy_rule" "global_cel" {
  for_each        = var.regional ? {} : local.cel_rules
  project         = var.project_id
  security_policy = google_compute_security_policy.global[0].name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action

  match {
    expr {
      expression = each.value.expression
    }
  }
}

resource "google_compute_region_security_policy" "regional" {
  count       = var.regional ? 1 : 0
  project     = var.project_id
  region      = var.region
  name        = var.policy_name
  description = var.description
  type        = "CLOUD_ARMOR_NETWORK"
}

resource "google_compute_region_security_policy_rule" "regional_ip" {
  for_each        = var.regional ? local.ip_rules : {}
  project         = var.project_id
  region          = var.region
  security_policy = google_compute_region_security_policy.regional[0].name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action

  match {
    config {
      src_ip_ranges = each.value.src_ip_ranges
    }
  }
}

resource "google_compute_region_security_policy_rule" "regional_cel" {
  for_each        = var.regional ? local.cel_rules : {}
  project         = var.project_id
  region          = var.region
  security_policy = google_compute_region_security_policy.regional[0].name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action

  match {
    expr {
      expression = each.value.expression
    }
  }
}
