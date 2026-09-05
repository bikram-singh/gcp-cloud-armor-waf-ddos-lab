#!/bin/bash
# Demonstrates: rules-user-ip-header.tf -- what user_ip_request_headers
# ACTUALLY does, corrected after real testing during this project's
# negative-testing phase disproved the original assumption.
#
# ORIGINAL (WRONG) ASSUMPTION: spoofing X-Forwarded-For would make plain
# IP-match rules (src_ip_ranges) and CEL origin.ip/origin.asn/
# origin.region_code evaluate against the spoofed value.
#
# WHAT REAL TESTING ACTUALLY SHOWED: it does not. A real Cloud Armor log
# entry, captured live against this exact deployment, showed BOTH of these
# simultaneously for the same request:
#   "remoteIpInfo": { "asn": <real ASN>, "regionCode": "<real region>" }
#   "userIpInfo":   { "ipAddress": "203.0.113.1", "source": "X-Forwarded-For" }
# The spoofed header value IS parsed and recorded (userIpInfo), but
# origin.ip/origin.asn/origin.region_code and plain src_ip_ranges rules
# still bind to the real connection IP (remoteIpInfo). A CEL rule using
# origin.ip == '203.0.113.1' was tested directly against this and did NOT
# fire, confirming this is not a CEL-vs-legacy-match-type distinction --
# the setting genuinely does not affect those evaluation paths.
#
# WHAT IT ACTUALLY APPEARS TO CONTROL: rate-limit's enforce_on_key has a
# distinct value, XFF_IP (separate from plain IP), that most plausibly
# consumes this trusted header value for keying rate-limit buckets. This
# script tests that directly, since it's the one documented consumer of
# user_ip_request_headers that fits the evidence.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== Confirming the header value IS recorded (userIpInfo), even though ==="
echo "=== it does not redirect origin.ip/origin.asn/plain IP-match rules    ==="
curl -sk -H "X-Forwarded-For: 203.0.113.1" -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/"
echo "Check the log entry for this request:"
echo "  gcloud logging read 'resource.type=http_load_balancer AND httpRequest.requestUrl:\"${VULNBANK_LB_IP}/\"' --project=<your-project> --limit=1 --format=json"
echo "Look for securityPolicyRequestData.userIpInfo.ipAddress == 203.0.113.1"
echo "alongside remoteIpInfo showing your REAL connection's ASN/region -- both"
echo "present at once is the actual, confirmed behavior."

echo ""
echo "=== To test the ACTUAL consumer (XFF_IP rate-limit keying) ==="
echo "This requires a rate-limit rule with enforce_on_key = \"XFF_IP\" instead"
echo "of \"IP\" -- not yet built into rules-rate-limit.tf. If you add one,"
echo "test it by sending requests from what LOOKS like the same real IP but"
echo "with DIFFERENT spoofed X-Forwarded-For values each time -- if XFF_IP"
echo "keying works, each spoofed value should get its own independent rate-limit"
echo "bucket, rather than sharing one bucket keyed on your real connection IP."
