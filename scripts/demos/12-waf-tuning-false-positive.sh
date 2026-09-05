#!/bin/bash
# Demonstrates: the false-positive story rules-waf-tuning.tf exists to fix.
# A legitimate transaction description containing an apostrophe trips the
# SQLi signature — then gets fixed via a field exclusion, without
# disabling SQLi protection everywhere else.
#
# Run this TWICE: once before swapping the rule (expect 403, the false
# positive), once after (expect 200 or whatever a legitimate non-SQLi
# request actually returns from this endpoint).
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== Before the fix: legitimate description with an apostrophe ==="
curl -sk -X POST "https://${VULNBANK_LB_IP}/transfer" \
  -d "description=O'Brien's payment&amount=50" \
  -o /dev/null -w "HTTP %{http_code}\n"
echo "Expect 403 — a FALSE POSITIVE. The apostrophe pattern resembles SQLi"
echo "syntax closely enough to trip sqli-v33-stable, even though this is"
echo "an entirely legitimate request."
echo ""
echo "=== To apply the fix ==="
echo "  1. In terraform/environments/lab/main.tf, in the concat() list,"
echo "     swap module.policies.preconfigured_waf_rules for"
echo "     module.policies.waf_tuning_rules"
echo "  2. terraform apply"
echo "  3. Re-run this script"
echo ""
echo "After the fix, the same request should succeed (the 'description'"
echo "query param's VALUE is now excluded from sqli-v33-stable inspection,"
echo "while the rule still blocks SQLi everywhere else)."
