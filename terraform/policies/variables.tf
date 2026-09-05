variable "address_group_id" {
  description = "Real resource ID of the address group (module.trusted_ips.id from environments/lab/main.tf), not just its short name. Cloud Armor evaluateAddressGroup() CEL function needs the full ID. Left null by default so rules-address-groups.tf produces no rule until this is actually wired in."
  type        = string
  default     = null
}
