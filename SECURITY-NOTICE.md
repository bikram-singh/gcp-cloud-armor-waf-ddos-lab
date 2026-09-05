# ⚠️ Security Notice

This repository deploys a **deliberately vulnerable banking application**
([`Commando-X/vuln-bank`](https://github.com/Commando-X/vuln-bank)) behind
a **public, internet-facing GCP Load Balancer**, for the purpose of
demonstrating Cloud Armor's WAF and DDoS protection capabilities.

## Do not

- Deploy this to a project you use for anything else
- Enter real personal, financial, or account data anywhere in the app
- Leave it running longer than a demo/testing session requires
- Rely on it for anything resembling production use
- Assume it's safe just because Cloud Armor is attached — Cloud Armor
  blocks *some* of the app's intentional vulnerabilities as a
  demonstration; it does not (and isn't meant to) fully secure a
  deliberately broken application

## Do

- Run `terraform destroy` (or the `terraform-destroy.yml` GitHub Actions
  workflow) as soon as you're done with a demo session — see
  [`docs/pricing-cost-awareness.md`](./docs/pricing-cost-awareness.md) for
  what's billing while this is up
- Keep the `vulnerable-app` submodule pinned (see
  [`vulnerable-app/NOTES.md`](./vulnerable-app/NOTES.md)) rather than
  tracking `main`, so you know exactly which vulnerabilities exist in your
  deployment at any given time
- Treat the external IPs this lab creates as temporary and disposable —
  don't bookmark them, don't share them outside of a demo you're actively
  walking someone through

## Upstream's own disclaimer

`vuln-bank` itself states, in its own README:

> This application contains intentional security vulnerabilities for
> educational purposes. DO NOT: Deploy in production, Use with real
> personal data, Run on public networks, Use for malicious purposes,
> Store sensitive information.

This repo's Terraform *does* put it on a public network (that's the point
— it's how Cloud Armor gets tested against real internet traffic), which
is precisely why the constraints above exist: minimize exposure time,
never use real data, and tear down promptly.

## If you find this deployed somewhere you didn't expect

If you're seeing this notice because you stumbled on a live instance of
this lab that isn't yours, please don't attempt to exploit it — the owner
likely just forgot to tear it down after a demo. Reach out via the
repository's GitHub Issues instead.
