#!/bin/bash
# Demonstrates: rules-rate-limit-ja3.tf — same JA3 vs IP distinction as
# 06-ja4-rate-limit.sh, applied to /login instead of /transfer. Same
# honest limitation applies: pair with a real browser to see the
# fingerprint-vs-IP difference; curl alone can't demonstrate both sides.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== JA3 rate-limit demo: /login, 12 rapid requests from curl (limit is 10/min) ==="
for i in $(seq 1 12); do
  CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${VULNBANK_LB_IP}/login")
  echo "curl request ${i}: HTTP ${CODE}"
done

echo ""
echo "To see the fingerprint-vs-IP distinction: while curl above is being"
echo "throttled, open https://${VULNBANK_LB_IP}/login in a real browser from"
echo "the SAME machine/IP — its different JA3 fingerprint should mean it's"
echo "not sharing curl's rate-limit bucket."
