# Rate limit by JA3 TLS fingerprint instead of source IP — catches clients
# that rotate IPs but reuse the same TLS client (e.g. a scripted attack
# tool), which pure IP-based rate limiting misses entirely.
#
# NOTE: `enforce_on_key = "TLS_JA3_FINGERPRINT"` is my best read of the
# current provider enum for this GA-Sept-2025 feature — verify against
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_security_policy_rule
# before applying; this is recent enough that the exact enum string is
# worth a quick check rather than trusting from memory.
locals {
  rate_limit_ja3_rules = [
    {
      priority    = 4010
      action      = "throttle"
      description = "Throttle by JA3 fingerprint on /login — catches IP-rotating scripted clients"
      expression  = "request.path == '/login'"
      rate_limit_options = {
        conform_action                    = "allow"
        exceed_action                     = "deny(429)"
        enforce_on_key                    = "TLS_JA3_FINGERPRINT"
        rate_limit_threshold_count        = 10
        rate_limit_threshold_interval_sec = 60
      }
    },
  ]
}
