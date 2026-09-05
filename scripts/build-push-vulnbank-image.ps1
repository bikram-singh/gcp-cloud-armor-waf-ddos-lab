<#
.SYNOPSIS
  Builds the vuln-bank web image locally via Docker Desktop and pushes it
  to Artifact Registry.

.DESCRIPTION
  Requires Docker Desktop running (confirmed) and the Artifact Registry
  repo already created (part of `terraform apply` on the compute module).
  Faster than Cloud Build for repeated rebuilds since everything happens
  locally — no upload-and-queue round trip.

.EXAMPLE
  .\scripts\build-push-vulnbank-image.ps1 -ProjectId project-cloud-armor `
      -Region us-central1 -RepoId cloud-armor-lab-images -Tag 5e5ea54
#>

param(
    [Parameter(Mandatory = $true)][string]$ProjectId,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$RepoId,
    [Parameter(Mandatory = $true)][string]$Tag
)

$ErrorActionPreference = "Stop"

$Image = "$Region-docker.pkg.dev/$ProjectId/$RepoId/vuln-bank-web:$Tag"

Write-Host "Configuring Docker auth for Artifact Registry ..."
gcloud auth configure-docker "$Region-docker.pkg.dev" --quiet

Write-Host "Building $Image from .\vulnerable-app ..."
docker build -t $Image .\vulnerable-app

Write-Host "Pushing $Image ..."
docker push $Image

Write-Host ""
Write-Host "Done. Image pushed: $Image"
Write-Host ""
Write-Host "If the vulnbank VM already booted before this image existed, reset it"
Write-Host "now so its startup script re-runs and successfully pulls the image:"
Write-Host ""
Write-Host "  gcloud compute instances reset cloud-armor-lab-vulnbank --zone=<your-zone> --project=$ProjectId"
Write-Host ""
Write-Host "Set vulnbank_image_tag = `"$Tag`" in your Terraform variables to match."
