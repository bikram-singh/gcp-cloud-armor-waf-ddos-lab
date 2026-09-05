# Serverless NEG Backends

## What this covers

Cloud Armor security policies attach to backend services the same way
regardless of what is behind them. This lab uses VM-based unmanaged
instance groups throughout, but Cloud Armor equally protects backend
services fronting Cloud Run, App Engine, or Cloud Functions, via a
Serverless Network Endpoint Group (NEG) instead of an instance group.

## Why this is a documented gap, not a built module

This lab's whole architecture (compute, instance-groups, https-lb
modules) is VM-and-instance-group shaped. Claiming full Cloud Armor
capability coverage without at least noting serverless backends would be
a real gap, since a meaningful share of real-world Cloud Armor
deployments protect Cloud Run services, not VMs.

## How this would differ in Terraform

Instead of terraform/modules/instance-groups, you would use a
google_compute_region_network_endpoint_group resource with
network_endpoint_type set to SERVERLESS, pointing at a Cloud Run service
name (or App Engine / Cloud Functions equivalent) instead of a list of
VM instances. The backend service and Cloud Armor attachment
(terraform/modules/cloud-armor/backend-policies) work identically, the
security_policy argument does not care what kind of NEG or instance
group sits behind the backend service.

## Relationship to this lab's existing modules

If you wanted to add this as a third demo path alongside nginx and
vuln-bank, you would add a new module,
terraform/modules/load-balancer/serverless-neg-lb or similar, reusing the
same https-lb module's URL map, proxy, and forwarding rule pattern, just
swapping the backend attachment. Not built here, noted as a legitimate
extension point.
