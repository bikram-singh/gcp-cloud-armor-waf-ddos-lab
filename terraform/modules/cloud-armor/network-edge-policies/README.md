# Network Edge Security Policies — STUB, verify before use

This protects **passthrough Network Load Balancers** (L3/L4) — distinct
from the `edge-policies` module, which protects Cloud CDN / backend
buckets. Same word ("edge"), two different features — this is exactly the
disambiguation your article's Network Edge Security Policies section is
meant to call out.

**Known pieces (verify exact syntax against the Terraform Registry before
applying):**
- A `google_compute_security_policy` with `type = "CLOUD_ARMOR_NETWORK"`
  holds the rules (this part is stable/documented).
- A `google_compute_network_edge_security_service` resource attaches that
  policy to a region + network, which is what actually enforces it against
  a passthrough Network LB's forwarding rules.

**Before writing main.tf here:**
1. Confirm `google_compute_network_edge_security_service`'s exact required
   arguments (region, network self_link, security_policy self_link) on the
   Terraform Registry — this resource has had schema changes across
   provider versions.
2. Confirm which forwarding rule / backend service needs to reference this,
   since Network LB wiring differs from the HTTPS LB module elsewhere in
   this repo.

**Demo it against:** the `network-lb` module under
`terraform/modules/load-balancer/network-lb/` — this is a genuinely
different architecture from the rest of this lab (passthrough TCP/UDP, not
HTTP(S)), so keep it in its own Terraform apply/destroy cycle rather than
bundling it with the main HTTPS LB stack.
