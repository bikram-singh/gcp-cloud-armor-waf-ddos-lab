# Hierarchical Security Policies — org/folder-level Cloud Armor enforcement.
#
# Confirmed working resource family (google-beta provider):
#   google_compute_organization_security_policy         — the policy itself
#   google_compute_organization_security_policy_association — binds it to a node
#   google_compute_organization_security_policy_rule     — individual rules
#
# Based on a confirmed-working config from a real hashicorp/terraform-
# provider-google GitHub issue. The one thing NOT exercised in that
# example — the `type` argument — is flagged in variables.tf; verify it
# against the current Terraform Registry page before applying.

resource "google_compute_organization_security_policy" "this" {
  provider     = google-beta
  display_name = var.display_name
  description  = var.description
  parent       = var.parent
  type         = var.type
}

resource "google_compute_organization_security_policy_association" "this" {
  provider      = google-beta
  name          = var.association_name
  attachment_id = var.attachment_id
  policy_id     = google_compute_organization_security_policy.this.id
}

resource "google_compute_organization_security_policy_rule" "this" {
  provider  = google-beta
  for_each  = { for r in var.rules : tostring(r.priority) => r }
  policy_id = google_compute_organization_security_policy.this.id
  priority  = each.value.priority
  action    = each.value.action

  match {
    expr {
      expression = each.value.expression
    }
  }
}
