#!/bin/bash
# Demonstrates: modules/cloud-armor/hierarchical-policies + the example
# rule in rules-hierarchical-org-policy.tf.
#
# UNLIKE every other script in this folder, this one requires a SEPARATE
# terraform apply first — the hierarchical policy module is deliberately
# NOT part of environments/lab's routine apply (it's folder/org-scoped,
# affecting gch-IT and everything under it, including gcphub-dev and
# gcphub-prod — not something that should happen automatically via
# terraform-apply.yml).
#
# To actually run this demo:
#   1. Write a small standalone .tf file instantiating
#      module.hierarchical_policy per the usage example in
#      modules/cloud-armor/hierarchical-policies/README.md
#   2. terraform apply THAT, deliberately, on its own
#   3. Confirm you have roles/compute.orgSecurityPolicyAdmin and
#      roles/compute.orgSecurityResourceAdmin on the gch-IT folder
#   4. Then run this script
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "Hitting vuln-bank LB — this only reflects the hierarchical policy's"
echo "effect if you've completed the manual apply steps above first."
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/"

echo ""
echo "To confirm the hierarchical policy is actually associated and"
echo "enforcing, check effective rules for this project's backend:"
echo "  gcloud compute security-policies list --project=project-cloud-armor"
echo "(A hierarchical policy applies ON TOP OF the project-level"
echo " lab-baseline-policy, not instead of it — both evaluate together.)"
