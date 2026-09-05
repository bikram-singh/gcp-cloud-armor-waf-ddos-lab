# Same pattern as rules-rate-limit-ja3.tf, using JA4 instead (GA Oct 2024 —
# more established than JA3, but still verify the exact enum string against
# the Terraform Registry before applying, same caveat as the JA3 file).
locals {
  rate_limit_ja4_rules = [
    {
      priority    = 4020
      action      = "throttle"
      description = "Throttle by JA4 fingerprint on /transfer"
      expression  = "request.path == '/transfer'"
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
