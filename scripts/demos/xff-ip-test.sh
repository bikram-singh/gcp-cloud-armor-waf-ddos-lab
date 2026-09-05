#!/bin/bash
# Confirms (or disproves) whether enforce_on_key = "XFF_IP" genuinely keys
# rate-limit buckets on the spoofed X-Forwarded-For value, not the real
# connection IP. Uses rules-xff-ip-test.tf's temporary rule (3 req/60s,
# keyed on XFF_IP, targeting "/").
#
# Test logic: send 4 requests with the SAME spoofed XFF value (expect the
# 4th to be throttled, confirming the rule works at all), then send ONE
# request with a DIFFERENT spoofed XFF value from the same real
# connection. If XFF_IP keying is real, that request gets its own fresh
# bucket and succeeds (200). If the setting doesn't actually affect
# rate-limit keying (same conclusion as the earlier origin.ip/origin.asn
# finding), it would still be throttled, because the real connection IP
# already exceeded its own shared threshold.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== Phase 1: 4 requests, same spoofed XFF (198.51.100.1) ==="
for i in 1 2 3 4; do
  CODE=$(curl -sk -H "X-Forwarded-For: 198.51.100.1" -o /dev/null -w "%{http_code}" "https://${VULNBANK_LB_IP}/")
  echo "Request ${i} (XFF=198.51.100.1): HTTP ${CODE}"
done
echo "Expect request 4 to be 429 -- confirms the rule fires at all."

echo ""
echo "=== Phase 2: ONE request, DIFFERENT spoofed XFF (198.51.100.2) ==="
CODE=$(curl -sk -H "X-Forwarded-For: 198.51.100.2" -o /dev/null -w "%{http_code}" "https://${VULNBANK_LB_IP}/")
echo "Request (XFF=198.51.100.2): HTTP ${CODE}"
echo ""
echo "If this is 200: XFF_IP keying CONFIRMED -- a different spoofed value"
echo "gets an independent bucket, proving user_ip_request_headers genuinely"
echo "feeds rate-limit keying even though it does not affect origin.ip/"
echo "origin.asn or plain IP-match rules (see rules-user-ip-header.tf)."
echo ""
echo "If this is ALSO 429: the setting has no effect here either -- the"
echo "bucket is still keyed on the real connection IP regardless of the"
echo "spoofed header, a further correction to file."
