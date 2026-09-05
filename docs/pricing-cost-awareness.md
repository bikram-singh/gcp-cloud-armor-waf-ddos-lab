# Pricing and Cost Awareness

## What actually bills in this lab

- Two VMs (e2-small nginx, e2-medium vulnbank), billed hourly while
  running, this is the largest ongoing cost if you forget to tear down
- Two external HTTPS Load Balancers, each with a forwarding rule, billed
  per forwarding rule hour plus data processed
- One extra IPv6 forwarding rule on the vulnbank LB (enable_ipv6 = true)
- Cloud Armor itself, billed per security policy per month, plus per
  rule, plus per incoming request evaluated, see current GCP Cloud Armor
  pricing page for exact figures, this changes over time
- Artifact Registry storage for the pinned vuln-bank image, small, a
  single image tag
- Cloud Logging ingestion, higher with log_level set to VERBOSE
  (currently the default in rules-logging-modes.tf) than with NORMAL
- External IP addresses themselves, GCP charges for unused reserved
  external IPs, this is not a concern here since all addresses in this
  lab are actively attached to running forwarding rules

## What does NOT bill unless you specifically enable it

- Cloud Armor Enterprise subscription, a separate monthly cost on top of
  Standard tier Cloud Armor billing, only relevant if you enable it to
  demo the Enterprise-only sections in docs/enterprise-features/ live
- reCAPTCHA Enterprise, separate product, only relevant if you build out
  the token-based bot management depth described in
  docs/enterprise-features/bot-management-tokens.md

## Why this lab is built around fast teardown

This is exactly why terraform-destroy.yml exists as its own workflow
with a strict confirmation guard, and why SECURITY-NOTICE.md tells you
not to leave this running longer than a demo session requires. Between
the two VMs, two LBs, and Cloud Armor's per-request billing, an
accidentally-left-running lab is a genuinely avoidable cost, not just a
security concern.

## Rough order of magnitude

Do not treat these as quotes, check current GCP pricing directly, but as
an order-of-magnitude sense: two small VMs plus two LB forwarding rules
plus a Cloud Armor policy with 15-ish rules, running for a few hours
during active demo work, then torn down, is a small single-digit-dollar
cost, not something that requires a budget alert on its own. The risk is
entirely in forgetting to run terraform destroy afterward and leaving it
running for days or weeks unattended.

## Recommended habit

Run terraform plan against the lab workspace before any long gap in
active work, if it shows resources still present that you thought were
torn down, that is your signal to run terraform-destroy.yml immediately
rather than investigating later.
