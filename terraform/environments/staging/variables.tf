variable "project_id" {
  description = "GCP project ID this environment deploys into. Real multi-env use would give staging/prod their OWN GCP projects (stronger isolation than just a different Terraform workspace in the same project) -- this repo defaults to reusing project_id for simplicity, but treat that as a starting point, not the recommended production pattern."
  type        = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "network_name" {
  type    = string
  default = "cloud-armor-staging-vpc"
}

variable "subnet_cidr" {
  type    = string
  default = "10.20.0.0/24" # distinct from lab's 10.10.0.0/24 -- avoids collision if ever deployed into the same project/region
}

variable "labels" {
  type    = map(string)
  default = { environment = "staging" }
}

variable "vulnbank_image_tag" {
  description = "Same pinned vuln-bank image tag as lab -- staging should run the identical app version being promoted, not latest."
  type        = string
}

variable "domain_base" {
  description = "Base domain for this environment's subdomains, e.g. gcpcloudhub.in -- staging LBs are provisioned at nginx-staging.<domain_base> and vulnbank-staging.<domain_base>."
  type        = string
}

variable "notification_email" {
  description = "Where Cloud Armor alerts for this environment go."
  type        = string
}
