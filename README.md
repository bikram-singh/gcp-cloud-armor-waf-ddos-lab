# gcp-cloud-armor-waf-ddos-lab

A hands-on GCP Cloud Armor lab covering WAF, DDoS protection, rate limiting,
bot mitigation, and policy precedence — provisioned with Terraform via
GitHub Actions, demoed against a deliberately vulnerable banking web app.

> ⚠️ **Security notice:** this repo deploys an intentionally vulnerable
> application behind a public GCP Load Balancer for demonstration purposes.
> See [`SECURITY-NOTICE.md`](./SECURITY-NOTICE.md) before deploying anything
> in this repo to a real project.

## What this covers

This lab exists to demonstrate, hands-on wherever possible, the full current
Cloud Armor capability set:

- WAF rules (OWASP preconfigured rule sets, custom CEL expressions, rule
  tuning via sensitivity levels and field/signature exclusions)
- Rate limiting (IP-based throttle & ban, JA3/JA4 TLS fingerprinting)
- IP and geo/ASN-based access control, IPv4 + IPv6, address groups
- Redirect actions (reCAPTCHA Enterprise, external 302)
- Policy precedence (Edge vs Backend vs Regional security policies)
- Hierarchical (org/folder) policy enforcement
- Enterprise-tier capabilities documented where hands-on demos aren't
  practical without a paid subscription (Adaptive Protection, Threat
  Intelligence, Advanced Network DDoS, DDoS Attack Visibility, SCC
  integration)

See [`docs/architecture.md`](./docs/architecture.md) for the full capability
map and [`docs/standard-vs-enterprise.md`](./docs/standard-vs-enterprise.md)
for what's demoed vs. documented-only, and why.

## Repo structure

```
gcp-cloud-armor-waf-ddos-lab/
├── .gitmodules                       # vulnerable-app pinned to Commando-X/vuln-bank @ <commit-hash>
├── terraform/
│   ├── modules/
│   │   ├── compute/                  # nginx VM template + vuln-bank VM (Flask app on :5000)
│   │   ├── instance-groups/          # unmanaged IGs, multi-region
│   │   ├── load-balancer/
│   │   │   ├── https-lb/             # HTTPS LB, backend services, URL map
│   │   │   └── network-lb/           # passthrough Network LB — Advanced Network DDoS + Network Edge policy demos
│   │   ├── cloud-armor/              # security policies: backend + edge + regional
│   │   │   ├── backend-policies/
│   │   │   ├── edge-policies/
│   │   │   ├── network-edge-policies/    # L3/L4 protection for passthrough Network LBs
│   │   │   └── hierarchical-policies/    # org/folder-level policy enforcement
│   │   └── address-groups/           # org-scoped reusable IP/CIDR lists
│   ├── environments/
│   │   └── lab/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── backend.tf            # HCP Terraform remote state
│   └── policies/
│       ├── rules-baseline.tf         # default deny-all, allow-all, priorities
│       ├── rules-ip-based.tf         # allow/deny by IP, ASN
│       ├── rules-ip-based-ipv6.tf    # same allow/deny pattern, IPv6 CIDR variant
│       ├── rules-user-ip-header.tf   # evaluate original client IP behind another proxy/CDN
│       ├── rules-address-groups.tf   # reusable IP/CIDR lists referenced across policies
│       ├── rules-geo-based.tf        # region blocking
│       ├── rules-path-based.tf       # CEL path expressions (/goodpath, /badpath)
│       ├── rules-rate-limit.tf       # throttle + rate-based ban on vuln-bank /login, /transfer
│       ├── rules-rate-limit-ja4.tf   # rate limit by JA4 TLS fingerprint
│       ├── rules-rate-limit-ja3.tf   # rate limit by JA3 TLS fingerprint
│       ├── rules-redirect.tf         # reCAPTCHA Enterprise + external 302
│       ├── rules-preconfigured-waf.tf    # OWASP sqli-stable, xss-stable; one-line CVE canary note
│       ├── rules-waf-tuning.tf       # sensitivity levels (paranoia 0–4), signature opt-out, field/header/cookie exclusions
│       ├── rules-threat-intelligence.tf  # evaluateThreatIntelligence() — Enterprise
│       ├── rules-logging-modes.tf    # NORMAL vs VERBOSE logging on one existing rule
│       └── hierarchical-org-policy.tf    # applied at folder, tested for inheritance
├── .github/workflows/
│   ├── terraform-plan.yml    # PR: plan + post as comment
│   ├── terraform-apply.yml   # manual dispatch: apply to lab env
│   └── terraform-destroy.yml # manual dispatch: teardown (cost control)
├── scripts/demos/
│   ├── 01-baseline-deny-allow.sh
│   ├── 02-ip-allow-deny.sh
│   ├── 02b-ipv6-allow-deny.sh
│   ├── 03-address-groups.sh
│   ├── 04-path-based-rules.sh
│   ├── 05-throttle-vs-ban.sh         # target vuln-bank /login and /transfer
│   ├── 06-ja4-rate-limit.sh
│   ├── 06b-ja3-rate-limit.sh
│   ├── 07-geo-asn-blocking.sh
│   ├── 08-hierarchical-policy.sh
│   ├── 09-vulnbank-sqli-xss.sh       # SQLi on /login (& biller queries), XSS on feedback/profile field
│   ├── 10-user-ip-header.sh
│   ├── 11-logging-modes.sh
│   └── 12-waf-tuning-false-positive.sh   # reproduce a false positive, fix via sensitivity + field exclusion
├── vulnerable-app/                   # git submodule → Commando-X/vuln-bank (MIT), pinned to fixed commit
│   └── NOTES.md                      # commit hash pinned; AI chat agent left disabled, out of scope for this lab
├── docs/
│   ├── architecture.md
│   ├── standard-vs-enterprise.md
│   ├── enterprise-features/
│   │   ├── adaptive-protection.md
│   │   ├── threat-intelligence.md
│   │   ├── advanced-network-ddos.md
│   │   ├── bot-management-tokens.md
│   │   ├── ddos-attack-visibility.md
│   │   └── scc-integration.md        # SCC findings: Allowed traffic spike, Increasing deny ratio
│   ├── alternate-backends/
│   │   ├── serverless-neg.md
│   │   └── gke-ingress-backendconfig.md
│   ├── service-mesh-rate-limiting.md
│   ├── iam-least-privilege.md         # least-privilege roles for the GitHub Actions service account
│   ├── pricing-cost-awareness.md      # per-policy/per-rule/per-forwarding-rule billing + Enterprise subscription
│   └── screenshots/
├── README.md
└── SECURITY-NOTICE.md                # repeats vuln-bank's own warning — it now sits behind a public GCP LB
```

## Deployment approach

This project deliberately splits into two halves:

**Infrastructure — Terraform + GitHub Actions.** Everything demoable on
Cloud Armor Standard tier (VMs, instance groups, load balancers, security
policies, address groups) is provisioned declaratively:
- `terraform-plan.yml` — runs on PR, posts the plan as a comment
- `terraform-apply.yml` — manual dispatch, applies to the lab environment
- `terraform-destroy.yml` — manual dispatch, tears everything down

**Security demonstration — manual/scripted.** Attack simulation (SQLi/XSS,
rate-limit triggering, geo/ASN testing, reCAPTCHA behavior) is deliberately
**not** automated in CI. Reasons are documented in `scripts/demos/README.md`
— in short: GitHub-hosted runners have unstable egress IPs (breaks IP/geo
demos), and reCAPTCHA needs a real browser. Run these scripts manually from
your own machine or Cloud Shell.

## Prerequisites

- A GCP project with billing enabled
- **A GCP Organization node** — required for the hierarchical-policies and
  network-edge-policies modules; skip those two if you don't have org-admin
  access (everything else in the lab works at project scope)
- Terraform >= 1.3 (uses `optional()` object attributes)
- An HCP Terraform workspace configured for remote state (see
  `terraform/environments/lab/backend.tf`)
- `gcloud` CLI authenticated, for running the demo scripts

## Getting started

```bash
git clone --recurse-submodules https://github.com/bikram-singh/gcp-cloud-armor-waf-ddos-lab.git
cd gcp-cloud-armor-waf-ddos-lab

# Review terraform/environments/lab/variables.tf and set your project ID,
# region, and (optionally) org/folder ID before applying.
```

Then either run Terraform locally against the `lab` environment, or trigger
the `terraform-apply.yml` workflow from the Actions tab.

**Remember to run `terraform-destroy.yml` (or `terraform destroy` locally)
when you're done** — see
[`docs/pricing-cost-awareness.md`](./docs/pricing-cost-awareness.md) for
what's actually billing while this is running.

## Vulnerable app

The lab's SQLi/XSS/rate-limit demos target
[`Commando-X/vuln-bank`](https://github.com/Commando-X/vuln-bank) (MIT
licensed), included here as a pinned git submodule — see
[`vulnerable-app/NOTES.md`](./vulnerable-app/NOTES.md) for the pinned commit
and what's intentionally left disabled (its AI chat agent is out of scope
for this lab — that's LLM security, not Cloud Armor).

## Companion article

This repo is the code companion to a Medium article walking through each
capability above with the actual console output and demo results. Link
TBD.

## License

This project's own Terraform, scripts, and documentation are MIT licensed.
The `vulnerable-app/` submodule carries its own MIT license from upstream —
see that repo directly for its terms.
