locals {
  baseline_rules = [
    {
      priority      = 2147483647
      action        = "deny(403)"
      description   = "Default deny-all (catch-all, lowest priority)"
      src_ip_ranges = ["*"]
    },
    {
      priority      = 9000
      action        = "allow"
      description   = "Baseline allow -- explicit default-allow posture for normal traffic; specific denies (path/IP/geo/WAF/etc.) all sit at higher-priority (lower-number) rules and take precedence over this one"
      src_ip_ranges = ["*"]
    },
  ]
}
