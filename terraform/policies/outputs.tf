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

output "waf_tuning_rules" {
  value = local.waf_tuning_rules
}

output "demo_log_level" {
  value = local.demo_log_level
}

output "demo_user_ip_headers" {
  value = local.demo_user_ip_headers
}

output "hierarchical_example_rules" {
  value = local.hierarchical_example_rules
}

output "xff_ip_test_rules" {
  value = local.xff_ip_test_rules
}
