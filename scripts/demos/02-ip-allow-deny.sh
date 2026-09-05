#!/bin/bash
# Demonstrates: rules-ip-based.tf — IP and ASN deny rules.
#
# The rule file ships with PLACEHOLDER values (203.0.113.1/32 is an RFC
# 5737 documentation range; ASN 64512 is a private-use ASN) — neither will
# ever match your real traffic. This script shows you your own current
# public IP so you can swap the placeholder for it, re-apply, and see a
# real deny take effect.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

MY_IP=$(curl -s ifconfig.me)
echo "Your current public IP: ${MY_IP}"
echo ""
echo "To actually test a deny against yourself:"
echo "  1. Edit terraform/policies/rules-ip-based.tf"
echo "  2. Replace 203.0.113.1/32 with ${MY_IP}/32"
echo "  3. terraform apply"
echo "  4. Re-run this script"
echo ""

echo "Hitting vuln-bank LB with current rules (placeholder IP won't match you):"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/"
