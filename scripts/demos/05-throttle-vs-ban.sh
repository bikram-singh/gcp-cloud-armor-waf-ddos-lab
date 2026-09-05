#!/bin/bash
# Demonstrates: rules-rate-limit.tf — throttle on /login (429 after 10
# req/min) vs rate-based ban on /transfer (banned for 5 min after 5 req/min).
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== Throttle demo: /login, 12 rapid requests (limit is 10/min) ==="
for i in $(seq 1 12); do
  CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${VULNBANK_LB_IP}/login")
  echo "Request ${i}: HTTP ${CODE}"
done
echo "Expect the last couple of requests to return 429."

echo ""
echo "=== Rate-based ban demo: /transfer, 7 rapid requests (limit is 5/min, then 5-min ban) ==="
for i in $(seq 1 7); do
  CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${VULNBANK_LB_IP}/transfer")
  echo "Request ${i}: HTTP ${CODE}"
done
echo "Expect requests 6-7 (and anything for the next 5 minutes) to be denied — not just 429, a hard ban."

echo ""
echo "Confirming the ban persists (should still be denied):"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/transfer"
