variable "project_id" {
  type = string
}

variable "name_prefix" {
  description = "Prefix for all resources this LB instance creates, e.g. \"nginx\" or \"vulnbank\" — lets this module be instantiated more than once (one LB per backend app)"
  type        = string
}

variable "instance_group_self_link" {
  type = string
}

variable "port_name" {
  description = "Named port on the instance group this backend service forwards to"
  type        = string
}

variable "port" {
  description = "Port number matching port_name, used for the health check"
  type        = number
}

variable "protocol" {
  type    = string
  default = "HTTP" # backend-facing protocol; the LB frontend is always HTTPS here
}

variable "security_policy_self_link" {
  description = "Cloud Armor backend security policy self_link to attach — pass module.baseline_policy.self_link etc."
  type        = string
  default     = null
}

variable "edge_security_policy_self_link" {
  description = "Cloud Armor EDGE security policy self_link (attaches to the backend bucket, not this backend service — only relevant if you add a backend bucket alongside this LB for the edge-vs-backend precedence demo). Left null here; wire it in environments/lab if/when you add a backend bucket."
  type        = string
  default     = null
}

variable "enable_ipv6" {
  description = "If true, also provisions a second global IPv6 address + forwarding rule pointing at the same backend/URL map — needed to actually test rules-ip-based-ipv6.tf's IPv6 CEL rule end-to-end. Off by default to avoid provisioning resources most instances of this module won't need."
  type        = bool
  default     = false
}
