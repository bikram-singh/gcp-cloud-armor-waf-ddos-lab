variable "project_id" {
  description = "GCP project ID this lab deploys into"
  type        = string
}

variable "region" {
  description = "Primary region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Primary zone for zonal resources (VMs)"
  type        = string
  default     = "us-central1-a"
}

variable "secondary_region" {
  description = "Second region for the multi-region instance-group demos"
  type        = string
  default     = "asia-south1"
}

variable "org_id" {
  description = "GCP Organization ID. Required only for the hierarchical-policies module — leave null if you don't have org-admin access; everything else in this lab works at project scope."
  type        = string
  default     = null
}

variable "network_name" {
  description = "Name for the VPC network created by this lab"
  type        = string
  default     = "cloud-armor-lab-vpc"
}

variable "subnet_cidr" {
  description = "CIDR range for the lab subnet in the primary region"
  type        = string
  default     = "10.10.0.0/24"
}

variable "labels" {
  description = "Common labels applied to lab resources"
  type        = map(string)
  default = {
    project = "gcp-cloud-armor-waf-ddos-lab"
    managed = "terraform"
  }
}

variable "vulnbank_image_tag" {
  description = "Pinned vuln-bank image tag (matches vulnerable-app/NOTES.md's pinned commit). Build/push it first via scripts/build-push-vulnbank-image.ps1."
  type        = string
}
