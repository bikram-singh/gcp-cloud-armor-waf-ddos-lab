variable "project_id" {
  type = string
}

variable "notification_email" {
  description = "Email address to receive alerts. A real address you actually check -- alerts are only useful if someone sees them."
  type        = string
}

variable "deny_rate_threshold" {
  description = "Number of Cloud Armor DENY log entries within the alignment window that triggers the deny-rate-spike alert. Tune based on this project's normal traffic -- a lab with near-zero baseline traffic can use a low threshold; a production app needs this calibrated against real historical volume first, or it will fire constantly on normal background noise (this lab's own bot-scanner traffic, seen during earlier testing, is a good example of what a mis-tuned threshold would false-positive on)."
  type        = number
  default     = 20
}

variable "deny_rate_window_seconds" {
  description = "Alignment window (seconds) for the deny-rate-spike alert's rate calculation."
  type        = number
  default     = 300 # 5 minutes
}
