#!/bin/bash
# Demonstrates: rules-baseline.tf — priority ordering.
# A deny-all sits at priority 2147483647 (lowest priority number wins first,
# but this is the CATCH-ALL max value, evaluated last if nothing else
# matches). An allow-all sits at priority 10 (evaluated first). Expect: the
# request succeeds, because priority 10's allow wins before the deny-all
# catch-all is ever reached.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "Hitting nginx LB — expect 200 (allow-all at priority 10 beats deny-all at priority 2147483647)"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${NGINX_LB_IP}/"

echo ""
echo "To see the deny-all actually take effect: comment out the priority-10"
echo "allow rule in terraform/policies/rules-baseline.tf, re-apply, and"
echo "re-run this script — expect 403 instead."
