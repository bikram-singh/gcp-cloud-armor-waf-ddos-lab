resource "google_compute_instance_group" "this" {
  for_each  = var.groups
  project   = var.project_id
  name      = "cloud-armor-lab-${each.key}-ig"
  zone      = each.value.zone
  network   = each.value.network
  instances = each.value.instances

  named_port {
    name = each.value.named_port.name
    port = each.value.named_port.port
  }
}
