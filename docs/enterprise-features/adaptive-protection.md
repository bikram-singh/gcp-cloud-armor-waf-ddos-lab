# Adaptive Protection

Console-only in this repo — not something this lab's Terraform builds or
a curl script can demonstrate live. Documented here instead.

## What it does

Adaptive Protection analyzes traffic patterns to your backend services,
detects suspected L7 DDoS attacks, and generates suggested WAF rules to
mitigate them. It is enabled per security policy, but requires an active
Cloud Armor Enterprise subscription on the project.

## Why this lab does not demo it live

Triggering a real L7 DDoS attack against your own project, on purpose,
just to see Adaptive Protection react, is expensive, noisy, and not
something a reproducible article demo should encourage. This is a
console-configuration and screenshot topic, not a Terraform one.

## How to enable it (console)

1. Go to Network Security > Cloud Armor policies in the GCP console
2. Select lab-baseline-policy (or whichever policy you are protecting)
3. Under Adaptive Protection, toggle it on
4. Requires an active Cloud Armor Enterprise subscription on the project

## What you would see if an attack occurred

- An alert in Cloud Logging / Security Command Center noting a suspected
  L7 DDoS pattern
- A suggested WAF rule Cloud Armor generates automatically, which you can
  review and choose to deploy
- Telemetry feeding into the DDoS Attack Visibility dashboard, see
  ddos-attack-visibility.md in this same folder

## Terraform note

The backend-policies module (terraform/modules/cloud-armor/backend-policies)
already supports enabling this via its adaptive_protection_enabled
variable, wired to a layer_7_ddos_defense_config block. Setting it to
true does not require Enterprise to apply cleanly in Terraform, but the
feature itself will not do anything without an active subscription.
