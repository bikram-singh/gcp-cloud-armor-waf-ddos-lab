#!/bin/bash
# Demonstrates: rules-rate-limit-ja4.tf — rate limiting keyed on TLS JA4
# fingerprint instead of source IP.
#
# HONEST LIMITATION: plain curl can't change its own TLS fingerprint, so a
# single curl loop can't fully prove "same IP, different fingerprint = not
# rate-limited together" — that needs a second HTTP client with a
# different TLS stack (a browser, or a tool like curl-impersonate) hitting
# the same endpoint from the same machine/IP while curl is being limited.
# This script shows the IP-based side (repeated requests from curl get
# throttled); pair it manually with a browser tab to see the fingerprint
# distinction in action.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== JA4 rate-limit demo: /transfer, 7 rapid requests from curl (limit is 5/min) ==="
for i in $(seq 1 7); do
  CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${VULNBANK_LB_IP}/transfer")
  echo "curl request ${i}: HTTP ${CODE}"
done

echo ""
echo "To see the fingerprint-vs-IP distinction: while curl above is being"
echo "throttled, open https://${VULNBANK_LB_IP}/transfer in a real browser"
echo "from the SAME machine/IP. If Cloud Armor is keying on JA4 correctly,"
echo "the browser's differently-shaped TLS handshake means it is NOT sharing"
echo "curl's rate-limit bucket, and should still succeed."
