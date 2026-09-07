# gcp-cloud-armor-waf-ddos-lab

A hands-on GCP Cloud Armor lab — WAF, DDoS/rate-limiting, bot mitigation,
regional and edge policy precedence, monitoring, and CI/CD — provisioned
with Terraform, tested against a deliberately vulnerable banking web app,
and validated with real traffic, real logs, and real attack payloads
rather than just documentation claims.

This isn't a "here's the happy path" tutorial repo. Every capability listed
below was actually exercised against live infrastructure, and a meaningful
number of the findings **corrected an initial assumption** or **caught a
real bug** — those are called out explicitly, because that's the part
worth reading if you're evaluating Cloud Armor for real.

> ⚠️ **Security notice:** this repo deploys an intentionally vulnerable
> application behind a public GCP Load Balancer for demonstration purposes.
> See [`SECURITY-NOTICE.md`](./SECURITY-NOTICE.md) before deploying anything
> in this repo to a real project. Don't leave it running longer than you're
> actively testing — it *will* attract bot/scanner traffic the moment it's
> reachable on a real domain (confirmed: this happened within the same
> session it went live).

## Why Cloud Armor — the actual case for it

Having now tested this hands-on rather than just read the docs, here's
what Cloud Armor genuinely buys you, backed by what's demonstrated in this
repo:

- **Blocks real attacks before they reach your app.** Confirmed here with
  live SQL injection and stored-XSS payloads against a real, deliberately
  vulnerable banking app — Cloud Armor stopped every one at the edge,
  without the app itself needing any input validation of its own.
- **Rate limiting and bot mitigation without touching app code.** Brute-force
  login attempts, scripted attacks, and abusive clients get throttled or
  banned at the load balancer, confirmed with real threshold tests, before
  they ever reach a database or business-logic layer.
- **Defense in depth, evaluated in layers.** Edge policies, regional
  policies, and backend policies each evaluate independently — confirmed
  here that an edge-layer deny wins even when a backend-layer default-allow
  exists, meaning a compromised or misconfigured backend policy doesn't
  automatically expose you if the edge layer is doing its job.
- **Visibility that doesn't require you to build it yourself.** Every
  enforcement decision is logged with enough detail (which rule, which
  field matched, TLS fingerprints, geo/ASN) to actually investigate an
  incident — confirmed by using these exact logs to diagnose every finding
  in this repo.
- **It's also not magic, and this repo shows where the edges are.** A
  misconfigured WAF sensitivity level can block *legitimate* users just as
  effectively as it blocks attackers — confirmed here with a real
  registration-blocking false positive. Knowing that failure mode before
  you hit it in production is arguably more valuable than the happy-path
  demos alone.

## What's actually demonstrated here (tested, not just documented)

Every item below was exercised against live infrastructure with real
requests, and the result (confirmed working, or corrected from an initial
assumption) is documented at the point in the code/docs where it's relevant.

**Core WAF & attack protection**
- OWASP preconfigured WAF rules (SQLi, XSS) — confirmed blocking 4 distinct
  real SQLi payload shapes (4 different CRS rule IDs caught across testing)
  and a real stored-XSS payload against the vulnerable app's own documented
  vulnerability
- WAF sensitivity levels — confirmed sensitivity 2 catches more payload
  shapes than sensitivity 1, **and** confirmed sensitivity 2 causes a
  severe false positive (blocks all new user registration) — this repo
  ships sensitivity 1 as the safe default specifically because of that
  finding
- Field-level WAF exclusions — tested as an alternative to a blanket
  sensitivity change; confirmed it fixes one endpoint's false positive
  while **silently disabling protection on a different endpoint** that
  happens to share the same field name. Documented as a real, non-obvious
  risk, not shipped as the default.

**Rate limiting & bot mitigation**
- IP-based throttle (429) and rate-based ban (403, timed) — both confirmed
  with real threshold tests and log evidence
- JA3 and JA4 TLS fingerprint-based rate limiting — confirmed via real
  browser-vs-curl tests: a client hitting its own rate limit doesn't affect
  a different client (different TLS fingerprint) on the same real IP

**Access control**
- IP/CIDR and ASN-based allow/deny rules
- Geo-blocking — confirmed with a real request from an actual `us-central1`
  origin (not simulated), correctly denied by a region-based rule
- IPv6 support — provisioned and reachable in principle; full end-to-end
  verification wasn't possible from this network (no outbound IPv6), an
  honest environment limitation rather than a gap in the work
- `user_ip_request_headers` (trusting a proxy's forwarded-IP header) —
  tested and the actual scope turned out narrower than initially assumed:
  it does **not** make plain IP-match or CEL `origin.ip`/`origin.asn` rules
  trust a spoofed header, but it **does** correctly affect rate-limit
  keying (`enforce_on_key = "XFF_IP"`) — both confirmed via isolated tests

**Redirect & challenge actions**
- External 302 redirect — confirmed working
- reCAPTCHA Enterprise challenge — confirmed the rule goes effectively
  **inert** without an actual reCAPTCHA Enterprise key configured (a
  stronger finding than "won't render a visual challenge")

**Policy architecture**
- Backend security policies (the default, most common attachment point)
- Regional backend security policies — built and tested end-to-end on a
  real regional external Application LB; confirmed a `google-beta`
  provider requirement and an explicit `capacity_scaler` field requirement
  not needed on global backend services
- Edge security policies and Edge-vs-Backend precedence — confirmed an
  edge-layer deny wins before the backend policy is even evaluated (the
  backend decision doesn't appear in the log at all for a request an edge
  rule already denied); also confirmed edge policies on standard backend
  services only support IP-range matches, not CEL expressions
- Preview mode — confirmed via a distinct `previewSecurityPolicy` log
  field: a rule in preview logs what it *would* have done without actually
  enforcing it

**Operational maturity**
- Automated security regression testing, running daily in CI — and this
  isn't a hypothetical safety net: **it already caught a real regression**
  on its first run (a rate-limit rule fix earlier in this project had
  silently broken an unrelated redirect rule sharing the same path)
- Cloud Monitoring alerting — a deny-rate-spike alert and a
  policy-change-detection alert, both live and wired to a real
  notification channel
- BigQuery log export with example analysis queries (top blocked IPs,
  SQLi attempts over time, denies by rule)
- A working CI/CD pipeline (GitHub Actions, Terraform, HCP Terraform,
  Workload Identity Federation) — genuinely working end-to-end, not just
  written; getting there surfaced six distinct real bugs, all fixed and
  documented in [`docs/cicd-setup.md`](./docs/cicd-setup.md)
- Multi-environment structure (a `staging` template alongside the live
  `lab` environment) and a documented promotion workflow
- An incident response runbook grounded in this project's own confirmed
  findings, not generic advice

**Documented but not independently demonstrated** (genuine limitations,
stated plainly rather than glossed over):
- Enterprise-tier features (Adaptive Protection, Threat Intelligence,
  Advanced Network DDoS, DDoS Attack Visibility, SCC integration, Address
  Groups enforcement) — this project doesn't have a Cloud Armor Enterprise
  subscription; each is documented in
  [`docs/enterprise-features/`](./docs/enterprise-features/) based on
  public documentation, clearly marked as not independently verified here
- Hierarchical (org/folder) policies — the module exists and is documented,
  but applying it needs org-admin access this project didn't exercise
  against a real org hierarchy end-to-end

See [`docs/architecture.md`](./docs/architecture.md) and
[`docs/standard-vs-enterprise.md`](./docs/standard-vs-enterprise.md) for
the full breakdown, and browse `terraform/policies/*.tf` directly — every
rule file's comments carry the real evidence (log excerpts, error
messages, the actual test that confirmed or corrected the assumption) for
that specific capability.

## Repo structure

```
gcp-cloud-armor-waf-ddos-lab/
├── .gitmodules                       # vulnerable-app pinned to Commando-X/vuln-bank @ fixed commit
├── terraform/
│   ├── modules/
│   │   ├── compute/                  # nginx VM + vuln-bank VM (Flask app on :5000)
│   │   ├── instance-groups/          # unmanaged IGs
│   │   ├── load-balancer/
│   │   │   └── https-lb/             # HTTPS LB -- self-signed or Google-managed cert,
│   │   │                             # optional IPv6 frontend, optional edge_security_policy
│   │   ├── cloud-armor/
│   │   │   ├── backend-policies/     # global AND regional (var.regional), confirmed both work
│   │   │   └── edge-policies/        # confirmed: IP-range matches only, no CEL
│   │   ├── address-groups/           # built; enforcement requires Enterprise, confirmed via
│   │   │                             # a real API error, not just documentation
│   │   ├── monitoring/                # Cloud Monitoring alert policies + notification channel
│   │   └── log-export/                # BigQuery sink for LB/Cloud Armor logs
│   ├── environments/
│   │   ├── README.md                  # multi-environment promotion workflow
│   │   ├── lab/                       # ACTIVELY DEPLOYED -- this whole project's test sandbox
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── monitoring.tf
│   │   │   └── backend.tf             # HCP Terraform remote state, LOCAL execution mode
│   │   └── staging/                   # NOT YET APPLIED -- clean reference environment,
│   │                                   # confirmed-safe config only, monitoring/log-export
│   │                                   # wired in from the start
│   └── policies/
│       ├── rules-baseline.tf          # deny-all + a real allow rule (NOT the priority-10 bug
│       │                              # this project shipped with initially -- see its comment)
│       ├── rules-ip-based.tf          # IP/ASN allow-deny
│       ├── rules-ip-based-ipv6.tf
│       ├── rules-user-ip-header.tf    # corrected scope, see comment -- XFF_IP rate-limit only
│       ├── rules-address-groups.tf    # Enterprise required, confirmed via real error
│       ├── rules-geo-based.tf         # confirmed via a real us-central1-origin test
│       ├── rules-path-based.tf
│       ├── rules-rate-limit.tf        # throttle + ban on vuln-bank /login, /transfer
│       ├── rules-rate-limit-ja3.tf    # own dedicated path -- see comment on why
│       ├── rules-rate-limit-ja4.tf    # own dedicated path -- see comment on why
│       ├── rules-redirect.tf          # reCAPTCHA (confirmed inert w/o Enterprise) + 302
│       ├── rules-preconfigured-waf.tf # sensitivity 1 -- see comment for the registration
│       │                              # false-positive finding that decided this
│       ├── rules-waf-tuning.tf        # field-exclusion test -- see comment for the real risk found
│       ├── rules-threat-intelligence.tf   # Enterprise required, excluded from the applied policy
│       ├── rules-logging-modes.tf     # corrected: no observed difference NORMAL vs VERBOSE
│       ├── rules-preview-test.tf      # preview mode, confirmed via previewSecurityPolicy log field
│       └── rules-xff-ip-test.tf       # kept as an empty list -- see file comment
├── .github/workflows/
│   ├── terraform-plan.yml             # WORKING -- Workload Identity Federation, TF_VAR_* injection
│   ├── terraform-apply.yml
│   ├── terraform-destroy.yml
│   └── security-regression.yml        # daily automated regression run -- already caught a real bug
├── scripts/
│   ├── security-regression-tests.sh   # the suite security-regression.yml runs
│   ├── build-push-vulnbank-image.ps1  # normalizes line endings in a temp copy, never touches
│   │                                  # the pinned submodule
│   └── demos/                         # manual demo scripts, one per capability above
├── vulnerable-app/                    # git submodule -> Commando-X/vuln-bank (MIT), pinned commit
├── docs/
│   ├── architecture.md                # includes a real gotcha: unmanaged instance groups
│   │                                  # silently emptying after VM replacement
│   ├── standard-vs-enterprise.md      # includes the confirmed reCAPTCHA-without-Enterprise finding
│   ├── cicd-setup.md                  # the full CI/CD debugging journey -- 6 real bugs, all fixed
│   ├── iam-least-privilege.md         # includes the CI service account's confirmed real role list
│   ├── incident-response-runbook.md   # attack vs. false-positive triage, grounded in real findings
│   ├── dashboard-queries/             # example BigQuery SQL for a Looker Studio dashboard
│   ├── enterprise-features/           # documented-only, clearly marked as such
│   ├── alternate-backends/
│   ├── service-mesh-rate-limiting.md
│   └── pricing-cost-awareness.md
├── README.md
└── SECURITY-NOTICE.md
```

## Deployment approach

**Infrastructure — Terraform + GitHub Actions, genuinely working end to
end.** `terraform-plan.yml` runs on PR and posts the plan as a comment;
`terraform-apply.yml` and `terraform-destroy.yml` are manual-dispatch with
confirmation guards. Authentication to GCP uses Workload Identity
Federation (no service account key file — this org's policy blocks key
creation entirely, which is itself a good default to copy). See
[`docs/cicd-setup.md`](./docs/cicd-setup.md) for the complete, honest
account of what it took to get this actually working, including every
real error hit along the way.

**Automated security regression testing** runs daily via
`security-regression.yml`, hitting the live endpoints with real payloads
and asserting the expected Cloud Armor response — not a mock, the actual
deployed policy. See [`scripts/security-regression-tests.sh`](./scripts/security-regression-tests.sh).

**Manual/scripted demos** (`scripts/demos/`) cover capabilities that don't
suit automated CI well — geo-blocking needs a real non-local origin,
reCAPTCHA needs a real browser, JA3/JA4 needs a genuinely different TLS
client. Run these from your own machine.

## Prerequisites

- A GCP project with billing enabled
- Terraform >= 1.3
- An HCP Terraform workspace configured for remote state, set to **Local**
  execution mode (Remote mode can't resolve this repo's relative module
  paths — confirmed the hard way; see `terraform/environments/lab/backend.tf`)
- `gcloud` CLI authenticated, for running demo scripts and initial setup
- A domain you control, if you want trusted HTTPS (self-signed works
  without one, with a browser warning)
- For the CI/CD pipeline: a GitHub repo with Workload Identity Federation
  configured against your GCP project (see `docs/cicd-setup.md` for the
  exact `gcloud` commands) — a service account key file will not work if
  your org blocks key creation, which is a common and good default policy

## Getting started

```bash
git clone --recurse-submodules https://github.com/bikram-singh/gcp-cloud-armor-waf-ddos-lab.git
cd gcp-cloud-armor-waf-ddos-lab

# Copy and fill in terraform/environments/lab/terraform.tfvars (gitignored)
# with your project_id, vulnbank_image_tag, and notification_email.
```

Then run Terraform locally against the `lab` environment, or trigger
`terraform-apply.yml` from the Actions tab once CI/CD is configured.

**Remember to tear down when you're done** —
`terraform destroy` locally or `terraform-destroy.yml` — see
[`docs/pricing-cost-awareness.md`](./docs/pricing-cost-awareness.md) for
what's actually billing while this runs, and remember the vulnerable app
will attract real internet scanning traffic the moment it's reachable.

## Vulnerable app

The SQLi/XSS/rate-limit demos target
[`Commando-X/vuln-bank`](https://github.com/Commando-X/vuln-bank) (MIT
licensed), included as a pinned git submodule — see
[`vulnerable-app/NOTES.md`](./vulnerable-app/NOTES.md) for the pinned
commit. Its AI chat agent is intentionally left disabled — out of scope
for a Cloud Armor lab.

## Companion article

This repo is the code companion to a Medium article walking through the
real findings above in narrative form — what was assumed going in, what
testing actually showed, and the bugs and corrections along the way.
Link TBD.

## License

This project's own Terraform, scripts, and documentation are MIT licensed.
The `vulnerable-app/` submodule carries its own MIT license from
upstream — see that repo directly for its terms.
