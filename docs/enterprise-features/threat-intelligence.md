# Google Threat Intelligence

## What it does

Lets you allow or block traffic based on curated threat-intelligence
categories, such as Tor exit nodes, known malicious IPs, and public cloud
IP ranges. Configured via the evaluateThreatIntelligence(feed_name)
match expression. Requires Cloud Armor Enterprise.

## Where this lives in the repo

terraform/policies/rules-threat-intelligence.tf defines two example
rules: blocking Tor exit nodes and blocking known malicious IPs. Both
rules create fine on Standard tier, they simply never match anything
until Enterprise is active on the project.

## Why this lab does not fully demo it live

There is no simple, repeatable way to make your own curl traffic
originate from a Tor exit node or a known-malicious IP on demand. See
scripts/demos/14-threat-intelligence.sh for the honest limitation and
the manual Tor Browser test you can run once Enterprise is active.

## Available feed categories (non-exhaustive, check current GCP docs)

- iplist-tor-exit-nodes
- iplist-known-malicious-ips
- iplist-public-clouds (various sub-categories per cloud provider)

## How to enable it (console or gcloud)

Requires an active Cloud Armor Enterprise subscription on the project.
Once active, rules referencing evaluateThreatIntelligence() in this
repo start enforcing without any additional Terraform changes needed,
the rule was already created, it was just inert.
