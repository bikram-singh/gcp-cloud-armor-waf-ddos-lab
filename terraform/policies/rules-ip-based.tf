# IP-based access control + ASN blocking -- mirrors the original lab's
# "allow from Cloud Shell, not local machine" / "allow from local machine,
# not Cloud Shell" demo, plus an ASN example.
#
# Replace the example IPs below with your own before applying -- these are
# placeholders. Find your local machine's IP with curl ifconfig.me, and
# your current Cloud Shell IP by running curl ifconfig.me from within
# Cloud Shell (it changes between sessions, unlike a fixed office IP).
locals {
  ip_based_rules = [
    {
      priority      = 2000
      action        = "deny(403)"
      description   = "Deny a specific known-bad IP (swap for a real one when demoing)"
      src_ip_ranges = ["203.0.113.1/32"] # TEST-NET-3, RFC 5737 -- placeholder
    },
    {
      priority    = 2001
      action      = "deny(403)"
      description = "Deny by ASN -- example blocks a placeholder ASN, swap for a real one to demo"
      expression  = "origin.asn == 64512" # 64512 is a private-use ASN, placeholder only
    },
  ]
}
