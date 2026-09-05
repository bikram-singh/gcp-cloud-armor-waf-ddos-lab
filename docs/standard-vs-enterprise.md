# Standard vs Enterprise

Cloud Armor Standard is included with every GCP project; Cloud Armor
Enterprise (Managed Protection Plus) is a paid subscription on top. This
doc maps every capability in this repo to which tier it needs, since
several rule files in terraform/policies/ create fine on Standard but
silently do not enforce without Enterprise.

## What is on Standard (everything in this lab that fully works today)

| Capability | File |
|---|---|
| WAF rules (preconfigured and custom CEL) | rules-preconfigured-waf.tf, rules-waf-tuning.tf |
| Rate limiting (IP, JA3, JA4) | rules-rate-limit-star.tf |
| IP / IPv6 / path-based / geo-based rules | rules-ip-based-star.tf, rules-path-based.tf, rules-geo-based.tf |
| Redirect actions (external 302; reCAPTCHA needs its own separate Enterprise-tier product, reCAPTCHA Enterprise, not Cloud Armor Enterprise) | rules-redirect.tf |
| Logging modes (NORMAL/VERBOSE) | rules-logging-modes.tf |
| User IP request header | rules-user-ip-header.tf |
| Address groups (the resource creates fine) | rules-address-groups.tf |

## What requires Cloud Armor Enterprise to actually enforce

| Capability | File | What happens without Enterprise |
|---|---|---|
| Address group rules | rules-address-groups.tf | Group and rule create fine, rule never matches |
| Google Threat Intelligence | rules-threat-intelligence.tf | Rule creates fine, never matches |
| Adaptive Protection | N/A, console-only in this repo | Cannot be enabled at all |
| Advanced Network DDoS Protection | N/A, different LB type, not built | N/A |
| DDoS Attack Visibility telemetry | N/A, console-only | Dashboard unavailable |
| Hierarchical policies | stub module | Feature itself does not require Enterprise, but see its own README for schema-verification status |

## Why this matters for the article

If you are demoing this lab on a project without an active Enterprise
subscription, be upfront in the article about which sections are
documented, not demoed live. docs/enterprise-features/ covers each of
these individually with console-based screenshots instead of Terraform,
precisely because they cannot be proven working via curl without the
subscription active.

## Cost note

Enterprise is a per-project monthly subscription, separate from the
per-policy/per-rule/per-request Standard billing covered in
pricing-cost-awareness.md. Do not enable it just to complete this lab
unless you specifically want to demo the Enterprise-only sections live,
the documented-only approach in enterprise-features/ is a legitimate way
to cover them in the article without the ongoing subscription cost.
