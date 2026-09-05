# Internal Service Security Policies for Service Mesh

## What this covers

Cloud Armor supports internal service security policies enforcing
global server-side rate limiting per client for service mesh traffic,
internal east-west traffic between services inside a mesh, not the
north-south internet-facing traffic this entire lab is built around.
Went to Preview mid-2025.

## Why this is an appendix, not a demo

This is a genuinely different architecture from everything else in this
repo. Every rule file in terraform/policies/ and every module in
terraform/modules/ assumes a client on the internet talking to a Google
Cloud external Application Load Balancer. Service mesh rate limiting
assumes Istio, Anthos Service Mesh, or Cloud Service Mesh already
running, with services talking to each other internally, an entirely
separate GCP networking setup this lab does not provision and is
intentionally out of scope for an LB-centric lab.

## What it is, at a glance

- Enforces rate limits per calling client identity inside a mesh, rather
  than per source IP, since internal mesh traffic does not have the
  concept of a public source IP the way internet traffic does
- Global, meaning consistent enforcement across all mesh instances,
  rather than each instance tracking its own local counter
- Preview status as of mid-2025, check current GCP release notes before
  relying on this for anything beyond experimentation

## Where to look if you want to explore this separately

This is a good candidate for a distinct project, a service-mesh-focused
Cloud Armor lab, rather than folding into this one. The rule syntax and
mesh prerequisites differ enough from everything else here that forcing
it into this repo's existing module structure would not represent it
accurately.
