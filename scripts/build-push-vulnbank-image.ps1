<#
.SYNOPSIS
  Builds the vuln-bank web image locally via Docker Desktop and pushes it
  to Artifact Registry.

.DESCRIPTION
  Requires Docker Desktop running and the Artifact Registry repo already
  created (part of `terraform apply` on the compute module).

  IMPORTANT: builds from a TEMP COPY of vulnerable-app/, with shell script
  line endings normalized to LF and any UTF-8 BOM stripped. This is
  deliberate -- the pinned submodule commit itself is never modified (see
  vulnerable-app/NOTES.md on why it stays pinned/unmodified), but a local
  git checkout on Windows can still introduce CRLF or a BOM into .sh files
  depending on core.autocrlf and editor settings, which breaks the
  container's shebang lines with "no such file or directory" or "exec
  format error" -- both hit during this project's actual first deploy.
  Normalizing a disposable temp copy at build time avoids relying on every
  contributor's local git config being correct.

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
$TempBuildDir = Join-Path $env:TEMP "vuln-bank-build-$Tag"

Write-Host "Preparing a normalized temp copy of vulnerable-app at $TempBuildDir ..."
if (Test-Path $TempBuildDir) {
    Remove-Item $TempBuildDir -Recurse -Force
}
Copy-Item .\vulnerable-app $TempBuildDir -Recurse

Write-Host "Normalizing line endings (LF, no BOM) on all .sh files in the temp copy ..."
Get-ChildItem $TempBuildDir -Filter *.sh -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  normalized: $($_.FullName.Substring($TempBuildDir.Length))"
}

Write-Host "Configuring Docker auth for Artifact Registry ..."
gcloud auth configure-docker "$Region-docker.pkg.dev" --quiet

Write-Host "Building $Image from the normalized temp copy ..."
docker build -t $Image $TempBuildDir

Write-Host "Pushing $Image ..."
docker push $Image

Write-Host "Cleaning up temp copy ..."
Remove-Item $TempBuildDir -Recurse -Force

Write-Host ""
Write-Host "Done. Image pushed: $Image"
Write-Host ""
Write-Host "If the vulnbank VM already booted before this image existed, reset it"
Write-Host "now so its startup script re-runs and successfully pulls the image:"
Write-Host ""
Write-Host "  gcloud compute instances reset cloud-armor-lab-vulnbank --zone=<your-zone> --project=$ProjectId"
Write-Host ""
Write-Host "REMINDER: if the VM's instance group ever shows empty health-check"
Write-Host "results after a VM replacement/reset, see docs/architecture.md's"
Write-Host "known-gotchas section -- unmanaged instance groups don't always"
Write-Host "auto-track VM replacement, and may need a manual re-add:"
Write-Host "  gcloud compute instance-groups unmanaged add-instances <group> --zone=<zone> --instances=<vm-name>"
Write-Host ""
Write-Host "Set vulnbank_image_tag = `"$Tag`" in your Terraform variables to match."
