#!/bin/bash
# Demonstrates: rules-logging-modes.tf — NORMAL vs VERBOSE Cloud Armor
# logging. This is a POLICY-WIDE setting, not a per-rule one (see that
# file's comments) — curl won't show any difference in HTTP response;
# the difference only shows up in Cloud Logging entries. This script
# triggers a request, then shows you the gcloud command to inspect the
# resulting log entry.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "Triggering a request that will get logged (a deny, so it's easy to spot):"
curl -sk -X POST "https://${VULNBANK_LB_IP}/login" \
  -d "username=admin' OR '1'='1' --&password=x" \
  -o /dev/null -w "HTTP %{http_code}\n"

echo ""
echo "View the resulting log entry (adjust --project if needed):"
echo ""
echo "  gcloud logging read \\"
echo "    'resource.type=\"http_load_balancer\" AND jsonPayload.enforcedSecurityPolicy.outcome=\"DENY\"' \\"
echo "    --project=project-cloud-armor --limit=1 --format=json"
echo ""
echo "With log_level = \"VERBOSE\" (the current setting, see"
echo "terraform/policies/rules-logging-modes.tf), the entry includes full"
echo "match details — which signature fired, request details, etc. Switch"
echo "demo_log_level to \"NORMAL\" in that file, terraform apply, trigger a"
echo "new request, and compare the log entry's verbosity."
