# References the address group created by the address-groups module
# (instantiated in environments/lab/main.tf as module.trusted_ips). Cloud
# Armor references address groups via the evaluateAddressGroup() CEL
# function inside a normal expression rule, NOT via a src_address_groups
# field on the match config - that field belongs to Firewall Policy
# rules, a related but separate GCP feature, corrected here after a real
# terraform plan error caught the mistake.
#
# Requires the actual address group RESOURCE ID (not just its short
# name), passed in from environments/lab/main.tf via
# var.address_group_id. Requires Cloud Armor Enterprise to enforce - the
# rule still creates fine on Standard tier.
locals {
  address_group_rules = var.address_group_id == null ? [] : [
    {
      priority    = 2030
      action      = "deny(403)"
      description = "Deny traffic from IPs in the lab trusted-ips address group (example uses deny for demo visibility - flip to allow for an actual allowlist use case)"
      expression  = "evaluateAddressGroup('${var.address_group_id}', origin.ip)"
    },
  ]
}
