variable "project_id" {
  type = string
}

variable "name_prefix" {
  description = "Prefix for all resources this LB instance creates, e.g. \"nginx\" or \"vulnbank\" -- lets this module be instantiated more than once (one LB per backend app)"
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
  description = "Cloud Armor backend security policy self_link to attach"
  type        = string
  default     = null
}

variable "edge_security_policy_self_link" {
  description = "Cloud Armor EDGE security policy self_link (attaches to a backend bucket, not this backend service)"
  type        = string
  default     = null
}

variable "enable_ipv6" {
  description = "If true, also provisions a second global IPv6 address + forwarding rule pointing at the same backend/URL map"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "If set (e.g. \"vulnbank-lab.gcpcloudhub.in\"), provisions a Google-managed SSL certificate for this domain instead of the self-signed one, and browsers will trust the connection with no warning. Provisioning takes 15-60+ minutes after DNS actually points at this LB's IP -- see this module's README for the full sequence. Leave null to keep the current self-signed behavior (works immediately, browser warning expected)."
  type        = string
  default     = null
}
