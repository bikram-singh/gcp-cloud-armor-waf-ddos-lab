locals {
  ip_rules  = { for r in var.rules : tostring(r.priority) => r if r.src_ip_ranges != null }
  cel_rules = { for r in var.rules : tostring(r.priority) => r if r.src_ip_ranges == null }
}

resource "google_compute_security_policy" "edge" {
  project     = var.project_id
  name        = var.policy_name
  description = var.description
  type        = "CLOUD_ARMOR_EDGE"
}

resource "google_compute_security_policy_rule" "edge_ip" {
  for_each        = local.ip_rules
  project         = var.project_id
  security_policy = google_compute_security_policy.edge.name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action
  preview         = each.value.preview

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = each.value.src_ip_ranges
    }
  }
}

resource "google_compute_security_policy_rule" "edge_cel" {
  for_each        = local.cel_rules
  project         = var.project_id
  security_policy = google_compute_security_policy.edge.name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action
  preview         = each.value.preview

  match {
    expr {
      expression = each.value.expression
    }
  }
}

# NOTE — precedence demo:
# If both a backend security policy and this edge security policy are
# attached to the same path, the edge policy is evaluated FIRST. A deny here
# blocks the request before it ever reaches the backend policy. Wire this
# policy's self_link into the backend bucket's `edge_security_policy` field
# (see terraform/modules/load-balancer/https-lb) to reproduce the lab's
# precedence test.
