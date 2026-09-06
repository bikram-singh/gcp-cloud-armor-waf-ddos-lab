terraform {
  cloud {
    organization = "gcpcloudhub"

    workspaces {
      name = "gcp-cloud-armor-waf-ddos-staging"
    }
  }

  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

# NOTE: create this workspace in HCP Terraform before first use (Overview
# > New workspace), set it to LOCAL execution mode (same reasoning as
# lab -- Remote mode can't resolve ../../modules relative paths), and
# set project_id / vulnbank_image_tag / domain_base / notification_email
# either as workspace variables (if ever switched to Remote mode) or via
# a local terraform.tfvars (gitignored) matching lab's pattern. See
# terraform.tfvars.example in this directory.
