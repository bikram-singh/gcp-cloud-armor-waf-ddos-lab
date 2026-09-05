# Security Command Center Integration

## What it does

Cloud Armor automatically integrates with Security Command Center and
exports two findings to its dashboard: Allowed Traffic Spike and
Increasing Deny Ratio. Adaptive Protection also feeds telemetry into
SCC. Findings are only visible for projects with SCC enabled at the
organization level.

## Allowed Traffic Spike

Notifies you of a sudden increase in allowed requests-per-second on a
per-backend-service basis, compared to recent historical volume. Useful
for spotting a potential L7 DDoS attack that is getting through, the
finding identifies which backend service is targeted and the RPS
characteristics that triggered it.

## Increasing Deny Ratio

Notifies you when the ratio of Cloud Armor-denied traffic increases,
based on your own configured rules. This is often a good sign, it means
mitigation is working, but a sudden spike in denies is worth
investigating as a signal of an active attack or scan against your
backend, not just routine background noise.

## How to enable it

1. Confirm Security Command Center is enabled at the organization level,
   see gch-IT folder / org-level settings for this project's org
2. Cloud Armor integration itself is automatic, no separate Cloud Armor
   configuration needed once SCC is enabled at the org level
3. Findings appear in the SCC dashboard automatically going forward

## Relationship to DDoS Attack Visibility

See ddos-attack-visibility.md in this same folder, same underlying
signals, different surface: SCC integration is for centralized security
posture management across an organization, DDoS Attack Visibility is the
Cloud Armor-native per-policy dashboard view.
