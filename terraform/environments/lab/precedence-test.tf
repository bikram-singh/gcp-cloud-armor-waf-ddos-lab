# TEMP TEST: Edge vs Backend security policy precedence -- CONFIRMED via
# real log evidence, the cleanest result across this whole project's
# negative-testing round.
#
# A request from a real IP matching this edge policy's deny rule produced
# a log entry with an "enforcedEdgeSecurityPolicy" field (DENY, priority
# 1000) -- and NO "enforcedSecurityPolicy" field at all. This proves edge
# precedence more strongly than just "edge wins a conflict": the backend
# policy (lab-baseline-policy, with its own default-allow at priority
# 9000) was never evaluated in the first place. Latency on the denied
# request was ~0.001s, consistent with a true front-door check ahead of
# any backend-layer logic.
#
# CORRECTION found along the way: edge policies attached to a regular
# backend service do NOT support CEL expression matches -- confirmed via
# a real API error ("Expression supported only for Media CDN edge
# policies"). Only plain IP-range matches (versioned_expr = SRC_IPS_V1,
# same as this rule) work here. A header-based match, which works fine on
# backend policies, is rejected outright for edge policies on standard
# backend services.
#
# Reuses the existing nginx instance group as backend, and the https-lb
# module as-is (self-signed cert, no domain needed).
module "precedence_edge_policy" {
  source      = "../../modules/cloud-armor/edge-policies"
  project_id  = var.project_id
  policy_name = "lab-precedence-edge-policy"
  description = "TEMP TEST: edge security policy for precedence test -- CONFIRMED, see comment above"

  rules = [
    {
      priority      = 1000
      action        = "deny(403)"
      description   = "TEMP TEST: deny by IP -- CONFIRMED edge precedence via enforcedEdgeSecurityPolicy log field, backend policy never evaluated"
      src_ip_ranges = ["106.219.120.23/32"]
    },
  ]
}

module "lb_precedence_test" {
  source                         = "../../modules/load-balancer/https-lb"
  project_id                     = var.project_id
  name_prefix                    = "edgetest"
  instance_group_self_link       = module.instance_groups.self_links["nginx"]
  port_name                      = "http"
  port                           = 80
  security_policy_self_link      = module.baseline_policy.self_link
  edge_security_policy_self_link = module.precedence_edge_policy.self_link
}

output "precedence_test_ip" {
  value = module.lb_precedence_test.external_ip
}
