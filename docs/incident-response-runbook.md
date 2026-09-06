# Incident Response Runbook -- Cloud Armor

What to actually do when a Cloud Armor alert fires (see
`terraform/modules/monitoring`) or you otherwise suspect an attack in
progress. Written for THIS project's confirmed real infrastructure and
findings -- not generic advice.

## Step 0: Don't assume it's an attack

This project has already confirmed, via real testing, that a Cloud
Armor deny-rate spike can mean either of two very different things:

- **A genuine attack** -- someone actually probing or attacking the app.
- **A misconfigured rule catching legitimate traffic** -- confirmed real
  in this project: WAF sensitivity 2 once blocked EVERY new user
  registration outright (see `terraform/policies/rules-preconfigured-waf.tf`'s
  documented finding). A spike in denies from that incident would have
  looked identical to an attack in monitoring, while actually being a
  self-inflicted outage.

**Always check which rule fired and against what traffic before
deciding which situation you're in.** Steps 1-2 below do this.

## Step 1: Identify what's actually being denied

```bash
gcloud logging read 'resource.type="http_load_balancer" AND jsonPayload.enforcedSecurityPolicy.outcome="DENY"' \
  --project=<project-id> --limit=20 --format=json
```

Look at, across the returned entries:
- `enforcedSecurityPolicy.priority` and `preconfiguredExprIds` -- which
  rule, which specific signature
- `remoteIp` / `securityPolicyRequestData.remoteIpInfo` -- one IP/ASN
  repeatedly, or many different ones (many different sources hitting
  the same rule looks more like a real attack; one or two IPs hitting
  rate limits looks more like either a real single attacker or a
  legitimate client with a bug)
- `httpRequest.requestUrl` -- one endpoint, or spread across many

If BigQuery export is set up (`terraform/modules/log-export`), the
`docs/dashboard-queries/top-blocked-ips.sql` and
`denies-by-rule-priority.sql` queries answer these same questions over
a longer window, faster.

## Step 2: Decide which situation you're in

**Looks like a real attack** (many different source IPs, hitting real
attack-shaped payloads, e.g. actual SQLi/XSS strings, not just
ordinary user input) -- go to Step 3a.

**Looks like a false positive** (denies on plain, ordinary-looking
input, or denies on a specific field that legitimate users always
submit, e.g. this project's registration incident) -- go to Step 3b.

## Step 3a: Genuine attack -- tighten defenses live

Options, roughly least-to-most aggressive:

1. **Lower an existing rate-limit threshold** temporarily (e.g. from
   5 req/60s to 2 req/60s on the specific endpoint under attack) --
   edit the relevant `rules-rate-limit*.tf` file, `terraform apply`.
2. **Add a targeted IP/ASN deny** for the specific attacking
   source(s), following the pattern in `rules-ip-based.tf`.
3. **Raise WAF sensitivity** on the specific rule family being
   bypassed (SQLi/XSS) -- but see this project's own confirmed finding
   before doing this broadly: sensitivity 2 has a real, confirmed
   false-positive risk. Prefer a scoped `waf_exclusions`-based fix (see
   `rules-waf-tuning.tf`) over a blanket sensitivity bump, and be aware
   an exclusion on a common field name affects EVERY endpoint using
   that field name, not just the one under attack -- confirmed real in
   this project (a `username` exclusion fixed one endpoint's false
   positive while silently disabling SQLi protection on a different
   endpoint sharing the same field name).
4. Apply via the normal `terraform apply` flow if there's time, or
   directly via `gcloud compute security-policies rules ...` for a
   true emergency -- but if you do the latter, backport the exact same
   change into the `.tf` file afterward so Terraform state doesn't
   drift from reality (a manual `gcloud` change and a stale `.tf` file
   will fight each other on the next apply).

## Step 3b: False positive -- restore service, then fix properly

1. **Immediate relief**: revert the specific rule change that caused
   it (e.g. `git revert` the commit that raised sensitivity, or the
   commit that added the problematic exclusion), `terraform apply`.
2. **Confirm the fix**: re-run
   `scripts/security-regression-tests.sh` against the live environment
   -- if the false positive was severe enough to alert on, it's severe
   enough to have a regression check backfilled into that suite so it
   can never silently recur.
3. **Root-cause properly, not just revert-and-forget**: if the rule
   was catching something real (e.g. genuinely broader SQLi coverage),
   consider the scoped-exclusion approach from `rules-waf-tuning.tf`
   instead of simply giving up the added coverage -- but test the
   exclusion's blast radius across EVERY endpoint sharing the excluded
   field name before shipping it, per the confirmed finding in Step
   3a.4 above.

## Step 4: Confirm the policy-change alert isn't unexpected

Any fix in Step 3a/3b will itself trigger this project's
"Cloud Armor: security policy changed" alert (see
`terraform/modules/monitoring`) -- expected, since it fires on every
policy mutation. Just confirm the change matches what you actually
just did (check recent `terraform apply` output / git log), not
something else modifying the policy concurrently.

## Step 5: Write it up

Add a line to this file's own history (or a separate incident log) --
what fired, what the real cause was, what the fix was, and whether a
new regression-test check should be added to
`scripts/security-regression-tests.sh` to catch a recurrence
automatically. This project's own JA4-vs-redirect collision (see
`rules-redirect.tf`'s comment) is a real example of exactly that loop
working: a regression test catching what a manual review had missed.
