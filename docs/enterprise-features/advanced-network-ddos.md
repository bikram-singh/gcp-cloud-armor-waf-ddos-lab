# Advanced Network DDoS Protection

## What it does

Provides L3/L4 DDoS protection for passthrough Network Load Balancers
and VMs with public IPs directly attached, distinct from the L7
(application-layer) protection the rest of this lab focuses on. Part of
Cloud Armor Enterprise.

## Why this is architecturally separate from the rest of this lab

Every LB this lab builds (terraform/modules/load-balancer/https-lb) is a
Global external Application Load Balancer, an L7 HTTPS load balancer.
Advanced Network DDoS Protection applies to a genuinely different
resource type, a passthrough Network Load Balancer, which this repo does
not currently provision.

The stub module at
terraform/modules/cloud-armor/network-edge-policies/README.md is the
closest related piece already scoped in this repo, it covers Network
Edge Security Policies for that same passthrough Network LB scenario.
Both would need a real Network LB built first (see
terraform/modules/load-balancer/network-lb/, also not yet built) before
either could be demoed hands-on.

## What it protects against

- Volumetric L3/L4 attacks (SYN floods, UDP floods, etc.) against a
  Network LB's forwarding rules or a VM's public IP directly
- Always-on for global external Application Load Balancers, classic
  Application Load Balancers, and external proxy Network Load Balancers,
  regardless of tier, for the always-on baseline
- The Enterprise-tier "Advanced" protection extends this with additional
  always-on coverage and DDoS attack visibility telemetry

## How to enable it

Requires an active Cloud Armor Enterprise subscription. Applies
automatically to supported load balancer types once the subscription is
active, no additional rule configuration needed for the baseline
protection itself.
