# Multi-environment structure

```
terraform/environments/
├── lab/        # ACTIVELY DEPLOYED -- the sandbox this whole project's
│               # testing happened in. Carries historical test/
│               # investigation scaffolding (xff_ip_test_rules,
│               # preview_test_rules) alongside the real shipped config.
├── staging/    # NOT YET APPLIED -- a clean reference environment:
│               # same modules, only the confirmed-safe shipped rule
│               # set, plus monitoring/alerting and BigQuery log export
│               # wired in from the start (see terraform/modules/
│               # monitoring and terraform/modules/log-export).
└── prod/       # NOT YET CREATED -- would be an exact copy of
                # staging/'s structure: different backend.tf workspace
                # name, different domain_base/subdomains, likely its own
                # separate GCP project for real isolation.
```

## Why staging and prod aren't actually deployed here

This is a single-operator lab/demo project, not a real multi-tenant
production app -- standing up two more full copies of this
infrastructure would roughly double or triple real GCP cost for no
actual second set of users to serve. The STRUCTURE and the promotion
workflow below are the real deliverable; apply staging/prod when there
is an actual reason to (testing a risky WAF change before a real
production rollout, for instance).

## The promotion workflow this structure supports

1. Make a change in `terraform/policies/*.tf` or a module -- same files
   regardless of which environment you're about to apply to.
2. `cd terraform/environments/staging && terraform plan` -- review
   against a real (if lower-traffic) environment first.
3. Run `scripts/security-regression-tests.sh` against staging's actual
   domains (override `VULNBANK_LB_HOST`/`NGINX_LB_HOST` env vars) to
   confirm nothing regressed -- the same suite that already caught a
   real bug in this project, now usable pre-production.
4. Only once staging looks correct, apply the same change to
   `terraform/environments/prod`.

## Creating prod when you actually need it

```bash
cp -r terraform/environments/staging terraform/environments/prod
```
Then edit `prod/backend.tf` (new workspace name,
e.g. `gcp-cloud-armor-waf-ddos-prod`), and `prod/terraform.tfvars`
(real prod project ID, prod domain, prod alert email -- likely a
distribution list, not one person, for a real production incident
path).
