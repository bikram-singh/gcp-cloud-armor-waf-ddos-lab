# WAF rule tuning -- swap-in test rules, NOT included in the default
# concat() (shares priority 1000 with the real SQLi rule).
#
# TWO REAL TESTS RUN AGAINST THIS LAB, BOTH CONFIRMED:
#
# TEST 1 (sensitivity only, see rules-preconfigured-waf.tf's own comment):
# reverting sensitivity 1 -> 2 globally fixed the registration false
# positive, but was rejected as the shipped default since it broke
# ordinary user registration entirely.
#
# TEST 2 (this file): kept sensitivity 2, added json_parsing = STANDARD
# (policy-wide) + a field exclusion on "username" instead of a global
# sensitivity revert. CONFIRMED this fixed registration (a fresh
# "testuser2" signup succeeded). But ALSO CONFIRMED, via a second real
# test, a serious side effect: the SAME exclusion silently disabled SQLi
# detection on /login's username field too -- a genuine tautology payload
# ("admin' OR '1'='1' --") that sensitivity 2 is specifically supposed to
# catch got a clean 200, with the login rate-limit rule (priority 4000)
# as the only rule that fired at all. Confirmed via log: no SQLi rule
# matched, request reached the real backend.
#
# WHY THIS HAPPENED: the exclusion targets the FIELD NAME "username"
# policy-wide, not a specific endpoint. /register and /login both have a
# field named "username" -- excluding one silently excludes the other too.
# This is a genuinely important, non-obvious risk: a field exclusion is
# only as safe as how UNIQUE that field name is across your entire app.
# Common field names (username, email, password) are dangerous to exclude
# precisely because they're common -- an attacker who finds one excluded
# endpoint can potentially reuse the same field name elsewhere to bypass
# protection that was never meant to be weakened there.
#
# CONCLUSION: sensitivity 1 remains the safer, correctly-chosen shipped
# default (see rules-preconfigured-waf.tf). Field exclusions are a real
# tool, but only safe for genuinely unique field names -- not common ones
# reused across multiple endpoints with different security postures. This
# repo does not ship the exclusion approach for that reason, despite it
# "working" for the one endpoint it was built to fix.
locals {
  waf_tuning_rules = [
    {
      priority     = 1000
      action       = "deny(403)"
      description  = "TESTED (see comment above): sensitivity 2 + json_parsing STANDARD + username exclusion fixes /register but breaks SQLi protection on /login (shared field name). NOT the shipped configuration -- see rules-preconfigured-waf.tf."
      expression   = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 2})"
      waf_rule_set = "sqli-v33-stable"
      waf_exclusions = [
        {
          target_rule_set      = "sqli-v33-stable"
          request_query_params = ["username"]
        },
      ]
    },
    {
      priority    = 1001
      action      = "deny(403)"
      description = "Unchanged XSS rule -- same as rules-preconfigured-waf.tf"
      expression  = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
    },
  ]
}
