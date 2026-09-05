variable "name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "org_id" {
  description = "Set only if creating an organization-scoped address group (GA Aug 2025). Leave null for project scope."
  type        = string
  default     = null
}

variable "parent" {
  description = "Override the computed parent (\"projects/<id>\" or \"organizations/<id>\"). Usually leave null and let locals compute it."
  type        = string
  default     = null
}

variable "location" {
  type    = string
  default = "global"
}

variable "description" {
  type    = string
  default = "Managed by Terraform - gcp-cloud-armor-waf-ddos-lab"
}

variable "type" {
  type    = string
  default = "IPV4"
}

variable "capacity" {
  type    = number
  default = 100
}

variable "purposes" {
  type    = list(string)
  default = ["CLOUD_ARMOR"]
}

variable "items" {
  description = "List of IP addresses / CIDR ranges in this group"
  type        = list(string)
}
