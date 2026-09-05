# DDoS Attack Visibility

## What it does

A dashboard and telemetry feed showing DDoS attack volume and type
against your protected load balancers, distinct from Adaptive Protection
itself. Adaptive Protection detects and suggests mitigation rules; DDoS
Attack Visibility is the observability layer showing you what happened.
Requires an active Cloud Armor Enterprise subscription.

## Why this gets its own doc, split from adaptive-protection.md

These are frequently bundled together conceptually, but they are
separate capabilities. Attack Visibility is demoable via console
screenshots without needing to trigger a real attack, since it also
surfaces baseline traffic telemetry, not just attack-time data, whereas
Adaptive Protection's suggested-rule behavior genuinely only appears
during a suspected attack.

## How to view it (console)

1. Go to Network Security > Cloud Armor in the GCP console
2. Select DDoS Attack Visibility (or the equivalent telemetry section
   under a specific security policy)
3. Requires an active Cloud Armor Enterprise subscription on the project

## Relationship to Security Command Center

The same underlying signals also surface as SCC findings, Allowed
Traffic Spike and Increasing Deny Ratio, see scc-integration.md in this
same folder. DDoS Attack Visibility is the Cloud Armor-native dashboard
view; SCC integration is the same data appearing in your organization's
broader security posture tooling.
