# Same allow/deny pattern as rules-ip-based.tf, IPv6 CIDR variant. Cloud
# Armor matches IPv4 and IPv6 client IPs identically via src_ip_ranges —
# no separate rule type needed, just IPv6 CIDR notation instead of IPv4.
locals {
  ipv6_rules = [
    {
      priority      = 2010
      action        = "deny(403)"
      description   = "Deny an IPv6 range — placeholder documentation range (RFC 3849)"
      src_ip_ranges = ["2001:db8::/32"]
    },
  ]
}
