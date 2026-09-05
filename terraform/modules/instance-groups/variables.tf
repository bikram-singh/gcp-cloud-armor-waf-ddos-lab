variable "project_id" {
  type = string
}

# One unmanaged instance group per entry. Each entry typically corresponds
# to one VM from the `compute` module (nginx, vulnbank) — kept generic here
# so the same module also serves the multi-region geo-blocking demo later
# (a second zone/region running a copy of one of these VMs).
variable "groups" {
  description = "Map of instance groups to create"
  type = map(object({
    zone       = string
    network    = string
    instances  = list(string) # instance self_links
    named_port = object({
      name = string
      port = number
    })
  }))
}
