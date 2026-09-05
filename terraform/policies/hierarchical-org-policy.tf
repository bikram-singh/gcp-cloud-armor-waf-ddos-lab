# Hierarchical policy example — NOT instantiated in environments/lab by
# default. See modules/cloud-armor/hierarchical-policies/README.md for
# why: this policy scope is folder/org-wide (gch-IT, which also holds
# gcphub-dev and gcphub-prod), not project-scoped like the rest of this
# lab, so applying it automatically alongside the routine
# terraform-apply.yml workflow risks affecting projects that aren't part
# of this lab at all.
#
# To actually demo this: instantiate the module directly, in its own
# apply, outside the normal lab workflow — see the module's own README
# for a usage example.
locals {
  hierarchical_example_rules = [
    {
      priority    = 100
      action      = "deny(403)"
      description = "Example folder-level deny — replace with something meaningful for your actual demo"
      expression  = "origin.region_code == 'US'"
    },
  ]
}
