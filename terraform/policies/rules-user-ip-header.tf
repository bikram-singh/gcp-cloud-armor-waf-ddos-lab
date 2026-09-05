# User IP request header -- POLICY-WIDE setting (advanced_options_config.
# user_ip_request_headers), not a per-rule match condition.
#
# CORRECTED after real testing during this project's negative-testing
# phase: this does NOT make origin.ip, origin.asn, origin.region_code, or
# plain src_ip_ranges IP-match rules evaluate against the spoofed header
# value. A live test (spoofing X-Forwarded-For to match a deny rule, both
# the plain IP-match version AND a CEL origin.ip version) confirmed via
# actual Cloud Armor logs that the header value is parsed and recorded
# separately (securityPolicyRequestData.userIpInfo), while
# remoteIpInfo -- which those match types actually bind to -- still
# reflects the real connection IP's ASN/region. Neither deny rule fired.
#
# The most plausible actual consumer, based on this evidence and Cloud
# Armor's own rate-limit schema, is enforce_on_key = "XFF_IP" (a distinct
# value from plain "IP") on rate-limit rules -- not yet exercised in this
# repo's rules-rate-limit*.tf files. See scripts/demos/10-user-ip-header.sh
# for the corrected demo and a suggested follow-up test.
#
# This lab's LBs sit directly in front of the VMs with no other proxy/CDN
# ahead of them, so even the confirmed userIpInfo recording has no real
# use case here -- it is included for syntax/behavior documentation only.
locals {
  demo_user_ip_headers = ["X-Forwarded-For"]
}
