#!/bin/bash
# Demonstrates: rules-baseline.tf -- priority ordering.
# A deny-all sits at priority 2147483647 (the catch-all, evaluated last if
# nothing else matches). A permanent baseline allow sits at priority 9000
# (evaluated before the catch-all deny, but after every real rule --
# WAF/rate-limit/path-based/etc. all sit at lower priority numbers like
# 1000-5001 and take precedence). Expect: the request succeeds, because
# priority 9000's allow wins before the deny-all catch-all is reached, but
# any SPECIFIC deny rule elsewhere in the policy still fires first since
# it sits at a lower (higher-precedence) priority number.
#
# NOTE: an earlier version of this rule set used priority 10 for a
# temporary allow-all, which had a real bug -- it beat EVERY other rule in
# the policy, including WAF/rate-limit/path-based denies, since 10 is lower
# than all of them. That's been fixed; the baseline allow now lives at
# priority 9000, specifically so it stays below every real rule's priority
# and only serves as the default-allow fallback, not an override.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "Hitting nginx LB -- expect 200 (baseline allow at priority 9000 beats deny-all at priority 2147483647, but sits below every real rule)"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${NGINX_LB_IP}/"

echo ""
echo "To see the deny-all actually take effect: comment out the priority-9000"
echo "allow rule in terraform/policies/rules-baseline.tf, re-apply, and"
echo "re-run this script -- expect 403 instead."
