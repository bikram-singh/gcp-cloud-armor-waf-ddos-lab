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
