# References the address group created by the `address-groups` module
# (instantiated in environments/lab/main.tf as `module "trusted_ips"`) —
# this file only defines the RULE that points at it; the group itself is a
# separate resource. Requires Cloud Armor Enterprise to actually enforce —
# see modules/address-groups/main.tf's note. The rule still creates fine on
# Standard tier, it just won't block/allow anything until Enterprise is
# active on the project.
locals {
  address_group_rules = [
    {
      priority           = 2030
      action             = "allow"
      description        = "Allow traffic from the lab's trusted-IPs address group"
      src_address_groups = [var.address_group_name]
    },
  ]
}
