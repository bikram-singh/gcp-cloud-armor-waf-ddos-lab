variable "project_id" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "description" {
  type    = string
  default = "Managed by Terraform - gcp-cloud-armor-waf-ddos-lab - CLOUD_ARMOR_NETWORK (L3/L4)"
}

variable "regional" {
  description = "If true, creates a regional network security policy instead of global"
  type        = bool
  default     = false
}

variable "region" {
  type    = string
  default = null
}

# Simpler rule shape than backend-policies — CLOUD_ARMOR_NETWORK filters
# packets (L3/L4), not HTTP requests, so most of backend-policies' HTTP-
# specific match fields (path, headers, WAF signatures) don't apply here.
variable "rules" {
  type = list(object({
    priority      = number
    action        = string # allow | deny(...) | rate_based_ban — verify accepted actions for this policy type against current docs, HTTP-specific actions like redirect likely don't apply
    description   = optional(string, "")
    src_ip_ranges = optional(list(string))
    expression    = optional(string)
  }))
  default = []
}
