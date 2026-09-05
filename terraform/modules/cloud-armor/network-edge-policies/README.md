# network-edge-policies module

No longer a stub. Confirmed: `google_compute_security_policy` /
`google_compute_region_security_policy` directly support
`type = "CLOUD_ARMOR_NETWORK"` — the module reuses the same dynamic
IP/CEL rule pattern as `backend-policies`, simplified since this policy
type filters packets (L3/L4), not HTTP requests.

## Why this module exists but isn't instantiated anywhere in this lab

There's genuinely nothing to attach it to — every LB this lab builds
(`terraform/modules/load-balancer/https-lb`) is a Global external
Application Load Balancer (L7/HTTPS). A `CLOUD_ARMOR_NETWORK` policy
attaches to a backend service fronting a **passthrough Network Load
Balancer**, which this lab doesn't provision (see
`docs/architecture.md` and
`docs/enterprise-features/advanced-network-ddos.md` — same gap,
documented in both places).

## If you want to actually demo this

You'd need to build a `terraform/modules/load-balancer/network-lb`
module first (a `google_compute_region_backend_service` with
`load_balancing_scheme = "EXTERNAL"`, `protocol = "TCP"` or `"UDP"`,
fronting a target VM), then wire this module's `self_link` output into
that backend service's `security_policy` field. Not built here —
this lab's scope stopped at documenting the concept and building a
working policy module, not standing up a second load balancer
architecture just to demo one capability.
