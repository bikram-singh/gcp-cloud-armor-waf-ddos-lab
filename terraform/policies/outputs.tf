# Each rules-*.tf file in this directory defines one `locals` block. This
# file exposes them as outputs so environments/lab (or any other
# environment later) can call this directory as a module and merge the
# rule lists together — Terraform does NOT auto-load sibling directories,
# so without this file these rules would silently never apply anywhere.

output "baseline_rules" {
  value = local.baseline_rules
}

output "preconfigured_waf_rules" {
  value = local.preconfigured_waf_rules
}

output "ip_based_rules" {
  value = local.ip_based_rules
}

output "ipv6_rules" {
  value = local.ipv6_rules
}

output "geo_based_rules" {
  value = local.geo_based_rules
}

output "address_group_rules" {
  value = local.address_group_rules
}

output "path_based_rules" {
  value = local.path_based_rules
}

output "rate_limit_rules" {
  value = local.rate_limit_rules
}

output "rate_limit_ja3_rules" {
  value = local.rate_limit_ja3_rules
}

output "rate_limit_ja4_rules" {
  value = local.rate_limit_ja4_rules
}

output "redirect_rules" {
  value = local.redirect_rules
}

output "threat_intelligence_rules" {
  value = local.threat_intelligence_rules
}

# NOT included in environments/lab's default concat() — see the file's own
# comment for why (shares a priority with the SQLi rule, is a swap-in fix,
# not an additive rule).
output "waf_tuning_rules" {
  value = local.waf_tuning_rules
}

output "demo_log_level" {
  value = local.demo_log_level
}

output "demo_user_ip_headers" {
  value = local.demo_user_ip_headers
}

# NOT consumed by environments/lab/main.tf's default concat() or module
# instantiation — see terraform/policies/hierarchical-org-policy.tf and
# modules/cloud-armor/hierarchical-policies/README.md for why this stays
# a manual, deliberate apply rather than part of the routine lab workflow.
output "hierarchical_example_rules" {
  value = local.hierarchical_example_rules
}
