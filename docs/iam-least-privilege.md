# IAM Least Privilege

## Two service accounts in this repo, both scoped narrowly

### 1. Lab VM service account

Defined in terraform/modules/compute/main.tf as
google_service_account.lab_vm, attached to both the nginx and vulnbank
VMs. Granted exactly two roles:

- roles/artifactregistry.reader, needed only so the vulnbank VM can pull
  its pinned image at boot
- roles/logging.logWriter, needed for basic VM logging

Deliberately NOT granted broader roles like Editor or Compute Admin,
which would let a compromised VM (this lab deliberately runs a
vulnerable app, remember) do far more damage than reading one Artifact
Registry repo and writing logs.

### 2. GitHub Actions / HCP Terraform

The .github/workflows/*.yml files authenticate to HCP Terraform via the
TF_TOKEN_APP_TERRAFORM_IO secret, HCP Terraform itself then applies
Terraform using whatever GCP credentials are configured on the HCP
Terraform workspace (typically a GCP service account key or Workload
Identity Federation, configured directly in HCP Terraform, not in this
repo).

Recommended minimum roles for that HCP Terraform-side service account,
scoped to the project:

- roles/compute.admin, needed for the VMs, LBs, instance groups, and
  firewall rules this lab provisions
- roles/compute.securityAdmin, needed specifically for Cloud Armor
  security policies and rules
- roles/artifactregistry.admin, needed to create the Artifact Registry
  repository itself (separate from the VM's read-only access to it)
- roles/iam.serviceAccountUser, needed so Terraform can attach the
  lab_vm service account to the VMs it creates
- roles/serviceusage.serviceUsageAdmin, needed for the
  google_project_service API-enablement resources in environments/lab

Deliberately NOT Owner or Editor at the project level, even though it
would be simpler to set up, since this same credential is what the
terraform-destroy.yml workflow uses, and a broader-than-necessary
credential is a bigger blast radius if that workflow or its trigger is
ever misused.

## Why this matters more than usual for this specific repo

Because this lab deliberately deploys a vulnerable application on
purpose, the usual "it is just a lab, permissions do not matter much"
reasoning does not fully apply here, an actually-compromised vuln-bank
VM is a real scenario this lab invites by design, so keeping its service
account narrowly scoped is the whole point, not a formality.
