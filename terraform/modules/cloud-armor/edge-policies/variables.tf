variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "policy_name" {
  description = "Name of the Cloud Armor edge security policy"
  type        = string
}

variable "description" {
  description = "Description of the edge security policy"
  type        = string
  default     = "Managed by Terraform - gcp-cloud-armor-waf-ddos-lab"
}

# Edge policies attach to a backend bucket (Cloud CDN) or, per the GCP docs,
# a global external Application LB backend service in some configurations.
# This lab's precedence demo (edge vs backend) attaches it to the backend
# bucket fronting the vulnerable-app's static assets — see docs/architecture.md.
variable "rules" {
  description = "List of edge security policy rules"
  type = list(object({
    priority      = number
    action        = string
    description   = optional(string, "")
    preview       = optional(bool, false)
    src_ip_ranges = optional(list(string))
    expression    = optional(string)
  }))
  default = []
}
