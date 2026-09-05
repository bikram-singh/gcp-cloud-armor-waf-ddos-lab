# Hierarchical Security Policies — STUB, verify before use

Cloud Armor's Hierarchical Security Policies (org/folder-level enforcement)
went GA on **2025-09-24**. That's recent enough that I'm not confident
asserting the exact Terraform resource name and schema from memory — the
provider may expose this under a dedicated resource, or as an extension of
the existing `google_compute_organization_security_policy` family used for
hierarchical **firewall** policies (a related but different feature).

**Before writing main.tf here:**

1. Check the current Google provider docs on the Terraform Registry:
   https://registry.terraform.io/providers/hashicorp/google/latest/docs
   — search "security policy" and "hierarchical" to find the GA resource.
2. Confirm whether it's `google-beta` only or has graduated to the `google`
   provider (recent GA features often sit in `google-beta` for a release
   or two first).
3. Confirm the association mechanism — likely a separate `_association`
   resource binding the policy to a folder/org node, mirroring how
   `google_compute_organization_security_policy_association` works for
   firewall policies.

**What this module needs to do once confirmed:**
- Create the policy at the org or folder level (`parent = "organizations/<id>"`
  or `"folders/<id>"`)
- Define rules (same rule shape as backend-policies: priority, action, match)
- Associate the policy to one or more folders/projects so it actually
  enforces (a policy with no association is inert)

**Demo it against:** your existing GCP Org node — the same prerequisite
your original slide deck flagged ("Need to have Org Node"). Confirm
org-admin / `roles/orgpolicy.policyAdmin`-equivalent access before wiring
this into the GitHub Actions apply workflow, since a permissions gap here
will fail Actions mid-apply rather than at plan time.
