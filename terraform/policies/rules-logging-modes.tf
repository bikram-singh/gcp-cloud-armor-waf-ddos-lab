# Logging verbosity (NORMAL vs VERBOSE) — a correction to the original
# project plan worth calling out explicitly: this is a POLICY-WIDE setting
# (advanced_options_config.log_level on the security policy resource
# itself), not something configured per individual rule. The original
# scoping table described this as "on one existing rule," which doesn't
# match the actual GCP resource schema — flagging that here rather than
# quietly building something that doesn't match how the API actually
# works.
#
# VERBOSE adds full request/match detail to Cloud Logging for every rule in
# the policy — this is genuinely how you'd find the real field name needed
# in rules-waf-tuning.tf's exclusion (e.g. inspecting logged request
# details during the false-positive incident to identify which query
# param/header actually carried the offending value).
#
# Wired into environments/lab/main.tf's `baseline_policy` module call as
# `log_level = module.policies.demo_log_level` — flip the value below and
# re-apply to switch modes.
locals {
  demo_log_level = "VERBOSE" # set to "NORMAL" to switch back
}
