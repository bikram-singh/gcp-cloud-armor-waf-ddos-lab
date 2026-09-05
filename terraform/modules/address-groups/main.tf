# Address Groups — reusable named IP/CIDR collections referenced by Cloud
# Armor rules via `src_address_groups` in a rule's match config.
#
# NOTE: Using an address group with purpose CLOUD_ARMOR requires an active
# Cloud Armor Enterprise subscription on the project (confirmed via GCP docs,
# Sept 2025). The resource itself creates fine on Standard tier, but Cloud
# Armor rules referencing it will not enforce until Enterprise is active.
locals {
  computed_parent = coalesce(
    var.parent,
    var.org_id != null ? "organizations/${var.org_id}" : "projects/${var.project_id}"
  )
}

resource "google_network_security_address_group" "this" {
  provider    = google-beta
  name        = var.name
  parent      = local.computed_parent
  location    = var.location
  description = var.description
  type        = var.type # IPV4 | IPV6
  capacity    = var.capacity
  purposes    = var.purposes # ["CLOUD_ARMOR"] or ["DEFAULT", "CLOUD_ARMOR"] to also share with Cloud NGFW
  items       = var.items
}
