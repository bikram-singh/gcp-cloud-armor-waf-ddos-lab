# GKE Ingress via BackendConfig

## What this covers

For services running on GKE and exposed via a GKE Ingress (which
provisions a Google Cloud external Application Load Balancer under the
hood), Cloud Armor attaches via a BackendConfig custom resource
referenced from the Kubernetes Service, rather than directly in
Terraform against a google_compute_backend_service.

## Why this is a documented gap, not a built module

Same reasoning as serverless-neg.md, this lab is VM-and-instance-group
shaped throughout. GKE-fronted services are a common real-world Cloud
Armor use case worth acknowledging even though this repo does not
provision a GKE cluster.

## How this works conceptually

1. Create the Cloud Armor security policy as usual, in Terraform, same
   module as everywhere else in this repo,
   terraform/modules/cloud-armor/backend-policies
2. In the GKE cluster, define a BackendConfig resource referencing that
   policy by name, under spec.securityPolicy.name
3. Annotate the Kubernetes Service with
   cloud.google.com/backend-config referencing that BackendConfig
4. GKE Ingress provisions the underlying backend service and wires the
   security policy in automatically, you do not directly manage the
   google_compute_backend_service resource yourself the way this lab's
   https-lb module does

## Relationship to this lab's existing modules

The Cloud Armor policy definition and rules
(terraform/policies/rules-star.tf, terraform/modules/cloud-armor)
transfer directly, the same module already used for the nginx and
vuln-bank backend services would work unchanged for a GKE-fronted
backend, only the attachment mechanism differs, BackendConfig plus
Kubernetes annotations instead of a direct
google_compute_backend_service.security_policy argument.
