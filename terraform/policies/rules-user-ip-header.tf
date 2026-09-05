# User IP request header — evaluates the ORIGINAL client IP from a header
# instead of the immediate connecting IP, for when traffic passes through
# another proxy/CDN in front of this LB. Like logging modes, this is a
# POLICY-WIDE setting (advanced_options_config.user_ip_request_headers),
# not a per-rule match condition — it changes how origin.ip and IP-based
# rate-limit keys are computed for every rule in the policy at once.
#
# This lab's LBs sit directly in front of the VMs with no other proxy/CDN
# ahead of them, so this setting has no effect by default (there's no
# second hop to trust a header from) — it's included here to demonstrate
# the syntax and document when you'd actually need it: e.g. if you later
# put a third-party CDN in front of this lab's load balancers.
#
# Wired into environments/lab/main.tf's `baseline_policy` module call as
# `user_ip_request_headers = module.policies.demo_user_ip_headers`.
locals {
  demo_user_ip_headers = ["X-Forwarded-For"]
}
