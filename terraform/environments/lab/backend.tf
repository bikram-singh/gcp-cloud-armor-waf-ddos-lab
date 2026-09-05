# HCP Terraform remote state.
#
# Uses the "gcpcloudhub" HCP Terraform organization. Create a workspace
# named "gcp-cloud-armor-waf-ddos-lab" there before running `terraform init`
# (or update the name below if you want to call it something else).
terraform {
  cloud {
    organization = "gcpcloudhub"

    workspaces {
      name = "gcp-cloud-armor-waf-ddos-lab"
    }
  }

  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
