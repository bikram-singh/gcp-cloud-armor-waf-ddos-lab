variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "network_self_link" {
  type = string
}

variable "subnetwork_self_link" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

# ---------------------------------------------------------------------------
# Artifact Registry — holds the pinned vuln-bank web image. The DB runs the
# public postgres:15 image directly (pulled from Docker Hub at boot); mirror
# it into this same repo later if Docker Hub rate limits become a problem.
# ---------------------------------------------------------------------------
variable "artifact_repo_id" {
  description = "Artifact Registry repository ID for this lab's images"
  type        = string
  default     = "cloud-armor-lab-images"
}

variable "vulnbank_image_tag" {
  description = "Tag to push/pull the vuln-bank web image as (typically the pinned upstream commit hash, per vulnerable-app/NOTES.md)"
  type        = string
}

# ---------------------------------------------------------------------------
# Machine sizing
# ---------------------------------------------------------------------------
variable "nginx_machine_type" {
  type    = string
  default = "e2-small"
}

variable "vulnbank_machine_type" {
  type    = string
  default = "e2-medium" # small headroom for Flask + Postgres on one VM
}

# ---------------------------------------------------------------------------
# vuln-bank runtime config (matches its own .env.example — see upstream repo)
# ---------------------------------------------------------------------------
variable "db_name" {
  type    = string
  default = "vulnerable_bank"
}

variable "db_user" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  description = "Postgres password for the vuln-bank DB container. Intentionally weak by upstream design (this app is deliberately insecure) — do not reuse this password anywhere real."
  type        = string
  sensitive   = true
  default     = "postgres"
}
