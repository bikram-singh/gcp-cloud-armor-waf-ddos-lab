variable "address_group_name" {
  description = "Name of the address group referenced by rules-address-groups.tf — must match the `name` used when instantiating the address-groups module in environments/lab (see main.tf's `module \"trusted_ips\"`)."
  type        = string
  default     = "lab-trusted-ips"
}
