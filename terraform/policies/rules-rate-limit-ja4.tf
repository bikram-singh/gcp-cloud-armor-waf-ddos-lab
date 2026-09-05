# Same pattern as rules-rate-limit-ja3.tf, using JA4 instead (GA Oct 2024).
#
# PERMANENTLY separated from /transfer, by design -- not a workaround.
# Originally targeted /transfer, same path as the IP-based rate_based_ban
# rule in rules-rate-limit.tf. Real testing confirmed this made the JA4
# rule unreachable: two rate-limit rules sharing one path will always have
# exactly one that actually matters, whichever sits at the lower priority
# number, since Cloud Armor stops at the first match. Reordering priorities
# would only move the collision onto the OTHER rule instead of resolving
# it -- this is a structural property of how Cloud Armor evaluates rules,
# not something priority-shuffling fixes. Demoing two different rate-limit
# key strategies (IP vs TLS fingerprint) therefore needs two different
# paths, permanently, not just for isolated testing.
#
# CONFIRMED via isolated real test (scripts/demos/06-ja4-rate-limit.sh):
# 4 curl requests hit this rule's 3-req/60s threshold (429 on request 4),
# then a real browser -- same real IP, same real connection, same 60s
# window -- loaded the page normally. This is the one rate-limit-adjacent
# capability in this project's negative-testing round that worked exactly
# as originally documented, no correction needed (contrast with
# user_ip_request_headers and logging-modes, both of which needed real
# corrections after testing).
locals {
  rate_limit_ja4_rules = [
    {
      priority    = 4025
      action      = "throttle"
      description = "Throttle root path by JA4 TLS fingerprint -- CONFIRMED via isolated test that this genuinely keys on fingerprint, not real connection IP (see comment above)"
      expression  = "request.path == '/'"
      rate_limit_options = {
        conform_action                    = "allow"
        exceed_action                     = "deny(429)"
        enforce_on_key                    = "TLS_JA4_FINGERPRINT"
        rate_limit_threshold_count        = 5
        rate_limit_threshold_interval_sec = 60
      }
    },
  ]
}
