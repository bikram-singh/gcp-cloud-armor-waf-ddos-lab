variable "parent" {
  description = "\"organizations/<org_id>\" or \"folders/<folder_id>\" — where this policy is created"
  type        = string
}

variable "display_name" {
  type = string
}

variable "description" {
  type    = string
  default = "Managed by Terraform - gcp-cloud-armor-waf-ddos-lab"
}

variable "type" {
  description = "VERIFY before relying on this: mirrors gcloud's `compute org-security-policies create --type=CLOUD_ARMOR` flag. The confirmed working example this module is based on didn't exercise this specific argument — check the current Terraform Registry page for google_compute_organization_security_policy before applying, in case the argument name or accepted values differ."
  type        = string
  default     = "CLOUD_ARMOR"
}

variable "attachment_id" {
  description = "The org/folder resource this policy is ASSOCIATED to (usually the same as `parent`, but kept separate since GCP's own model separates policy creation from association — a policy can exist without being associated anywhere, in which case it's inert)"
  type        = string
}

variable "association_name" {
  type = string
}

variable "rules" {
  description = "Same rule shape as backend-policies — priority, action, description, plus a CEL expression. Kept intentionally simpler than backend-policies' full schema (no rate-limit/redirect/WAF-exclusion support here) since hierarchical policies are typically used for broad allow/deny decisions, not fine-grained per-app tuning."
  type = list(object({
    priority    = number
    action      = string
    description = optional(string, "")
    expression  = string
  }))
  default = []
}
