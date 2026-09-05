locals {
  baseline_rules = [
    {
      priority      = 2147483647
      action        = "deny(403)"
      description   = "Default deny-all (catch-all, lowest priority)"
      src_ip_ranges = ["*"]
    },
    {
      priority      = 10
      action        = "allow"
      description   = "Allow all - demonstrates priority ordering over default deny"
      src_ip_ranges = ["*"]
    },
  ]
}
