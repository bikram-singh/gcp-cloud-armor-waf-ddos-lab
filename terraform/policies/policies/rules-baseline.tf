# Baseline: default deny-all + allow-all, demonstrating Cloud Armor's
# priority ordering (lower number = evaluated first; the LOWEST matching
# priority wins, not the highest). This mirrors the exact demo from the
# original lab notes: a deny-all at max priority (2147483647, evaluated
# last as a catch-all) plus an allow-all at priority 10 (evaluated first),
# so traffic is allowed despite the deny-all rule existing underneath it.
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
      description   = "Allow all — demonstrates priority ordering over default deny"
      src_ip_ranges = ["*"]
    },
  ]
}
