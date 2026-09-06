# Same pattern as rules-rate-limit-ja4.tf, using JA3 instead (GA Sept
# 2025). Permanently targets its own dedicated path (/register), same
# reasoning as the JA4 fix -- two rate-limit rules sharing one path always
# have exactly one that matters.
#
# CONFIRMED via isolated real test: 6 curl requests hit this rule's
# 5-req/60s threshold (429 on request 6), then a real browser -- same
# real IP, same real connection, same 60s window -- loaded /register
# normally. JA3 keying works identically to JA4, both confirmed in this
# project via the same browser-vs-curl test methodology.
locals {
  rate_limit_ja3_rules = [
    {
      priority    = 4015
      action      = "throttle"
      description = "Throttle /register by JA3 TLS fingerprint -- CONFIRMED via isolated browser-vs-curl test, same result as JA4"
      expression  = "request.path == '/register'"
      rate_limit_options = {
        conform_action                    = "allow"
        exceed_action                     = "deny(429)"
        enforce_on_key                    = "TLS_JA3_FINGERPRINT"
        rate_limit_threshold_count        = 5
        rate_limit_threshold_interval_sec = 60
      }
    },
  ]
}
