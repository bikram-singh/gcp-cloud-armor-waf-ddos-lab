# User IP request header -- POLICY-WIDE setting (advanced_options_config.
# user_ip_request_headers), not a per-rule match condition.
#
# CONFIRMED, via two rounds of real testing against this live deployment
# (not just documentation or assumption):
#
# DOES NOT AFFECT: origin.ip, origin.asn, origin.region_code in CEL, or
# plain src_ip_ranges IP-match rules. Proven twice -- once with a plain
# IP-match deny rule, once with an explicit CEL origin.ip == rule -- both
# spoofing X-Forwarded-For to match the denied value. Neither rule fired.
# Real Cloud Armor log output confirmed why: the spoofed value IS parsed
# and recorded (securityPolicyRequestData.userIpInfo), but remoteIpInfo --
# which those match types actually bind to -- still reflected the real
# connection's ASN/region the whole time.
#
# DOES AFFECT: rate-limit enforce_on_key = "XFF_IP" (a distinct value from
# plain "IP"). Confirmed via scripts/demos/xff-ip-test.sh: 4 requests with
# the same spoofed X-Forwarded-For value correctly hit a 3-req/60s
# threshold (429 on request 4), then ONE request with a DIFFERENT spoofed
# value from the same real connection got a completely fresh bucket
# (200) -- proving the rate-limit bucket was genuinely keyed on the
# spoofed header, not the real connection IP.
#
# PRACTICAL IMPLICATION: this setting is real and useful specifically for
# rate-limit keying behind a trusted upstream proxy/CDN that sets this
# header -- but it does NOT make your other IP-based access-control rules
# (allow/deny lists, geo-blocking, ASN-blocking) trust the header. Those
# still need the real connection IP to match, regardless of this setting.
#
# This lab's LBs sit directly in front of the VMs with no other proxy/CDN
# ahead of them, so there is no legitimate upstream to trust here --
# included purely for documenting the confirmed behavior.
locals {
  demo_user_ip_headers = ["X-Forwarded-For"]
}
