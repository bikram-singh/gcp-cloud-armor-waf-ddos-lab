# hierarchical-policies module

No longer a stub — built against a confirmed-working resource family
(`google_compute_organization_security_policy` +
`_association` + `_rule`, all `google-beta`).

## One residual uncertainty

The `type` argument (default `"CLOUD_ARMOR"`) wasn't exercised in the
working example this module is based on. Verify it against the current
Terraform Registry page for `google_compute_organization_security_policy`
before your first apply — if the argument name or accepted value is
wrong, `terraform plan` will reject it with a clear validation error, not
fail silently.

## Usage

```hcl
module "hierarchical_policy" {
  source            = "../../modules/cloud-armor/hierarchical-policies"
  parent            = "folders/351047376392" # gch-IT folder, per this project's org
  attachment_id     = "folders/351047376392"
  display_name      = "lab-hierarchical-policy"
  association_name  = "lab-hierarchical-association"

  rules = [
    {
      priority    = 100
      action      = "deny(403)"
      description = "Example folder-level deny — adjust for your demo"
      expression  = "origin.region_code == 'US'"
    },
  ]
}
```

## Prerequisites

Requires the `roles/compute.orgSecurityPolicyAdmin` IAM role (confirmed
role name via GCP's own CLI docs) on the target org/folder, plus
`roles/compute.orgSecurityResourceAdmin` to create the association
specifically. Neither of these is currently listed in
`docs/iam-least-privilege.md` — that doc only covers the two
project-scoped service accounts (lab VM, HCP Terraform/Actions). Add a
short section there if you actually instantiate this module, since it's
a genuinely different permission scope (org/folder, not project).

## Why this isn't wired into environments/lab by default

This lab's Cloud Armor demos are project-scoped (`baseline_policy`
attached directly to backend services). A hierarchical policy is
additive on top of that — it applies across every project under the
folder/org node, not just this lab's project. Wiring it in by default
would silently affect other projects under `gch-IT`
(`gcphub-dev`, `gcphub-prod`) without their owners necessarily expecting
it. Instantiate this module deliberately, in its own apply, when you're
specifically ready to demo it — not as part of the routine
`terraform-apply.yml` workflow.
