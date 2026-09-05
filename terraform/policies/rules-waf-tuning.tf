# WAF rule tuning — closes the loop on the original lab's unresolved
# moment: a legitimate request (e.g. an apostrophe in a transaction
# description or biller name, "O'Brien's payment") trips the sqli-stable
# preconfigured rule as a false positive.
#
# IMPORTANT — this rule shares priority 1000 with the SQLi rule already
# defined in rules-preconfigured-waf.tf. It is the SAME rule, with a
# waf_exclusions block added. It is deliberately NOT included in
# environments/lab/main.tf's default concat() — including both would be
# two Terraform resources at one priority, which GCP rejects.
#
# To run the live false-positive demo:
#   1. Apply with rules-preconfigured-waf.tf as-is, trigger the false
#      positive against vuln-bank (an apostrophe in a transaction field).
#   2. In environments/lab/main.tf, swap
#      `module.policies.preconfigured_waf_rules` for
#      `module.policies.waf_tuning_rules` in the concat() list.
#   3. Re-apply, re-run the same request — now allowed through.
#
# The field name below ("description") is a placeholder — inspect actual
# VERBOSE-mode logs (see rules-logging-modes.tf) to find vuln-bank's real
# parameter name before relying on this in a real demo.
locals {
  waf_tuning_rules = [
    {
      priority     = 1000 # same priority as the SQLi rule in rules-preconfigured-waf.tf — intentional
      action       = "deny(403)"
      description  = "Block SQL injection, EXCLUDING the transaction-description field's value from inspection"
      expression   = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
      waf_rule_set = "sqli-v33-stable"
      waf_exclusions = [
        {
          target_rule_set      = "sqli-v33-stable"
          request_query_params = ["description"] # placeholder — verify real field name via VERBOSE logs
        },
      ]
    },
    {
      priority    = 1001 # unchanged — same XSS rule as rules-preconfigured-waf.tf
      action      = "deny(403)"
      description = "Block XSS — targets vuln-bank feedback/profile field XSS"
      expression  = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
    },
  ]
}
