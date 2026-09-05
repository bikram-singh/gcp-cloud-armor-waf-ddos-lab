# Rate limiting — targets vuln-bank's /login and /transfer endpoints,
# which the app itself implements with NO rate limiting (confirmed in its
# own vulnerability list) — a genuinely real-world case for Cloud Armor to
# cover, not a contrived nginx page hit.
#
# Mirrors the original lab's two rate-limit demos:
#   - Throttle: >10 requests/min on /login -> 429
#   - Rate-based ban: 5 requests/min on /transfer -> banned for 5 minutes
locals {
  rate_limit_rules = [
    {
      priority    = 4000
      action      = "throttle"
      description = "Throttle /login — >10 req/min gets 429"
      expression  = "request.path == '/login'"
      rate_limit_options = {
        conform_action                    = "allow"
        exceed_action                     = "deny(429)"
        enforce_on_key                    = "IP"
        rate_limit_threshold_count        = 10
        rate_limit_threshold_interval_sec = 60
      }
    },
    {
      priority    = 4001
      action      = "rate_based_ban"
      description = "Ban /transfer abusers — 5 req/min triggers a 5-minute ban"
      expression  = "request.path == '/transfer'"
      rate_limit_options = {
        conform_action                    = "allow"
        exceed_action                     = "deny(403)"
        enforce_on_key                    = "IP"
        rate_limit_threshold_count        = 5
        rate_limit_threshold_interval_sec = 60
        ban_threshold_count               = 5
        ban_threshold_interval_sec        = 60
        ban_duration_sec                  = 300
      }
    },
  ]
}
