#!/bin/bash
# Demonstrates: rules-address-groups.tf + modules/address-groups.
#
# The trusted_ips address group (environments/lab/main.tf) ships with a
# placeholder IP (106.219.121.230/32, left over from the original lab
# notes). Requires an active Cloud Armor Enterprise subscription to
# actually enforce — the group and rule both create fine on Standard tier,
# they just won't do anything until Enterprise is on.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

MY_IP=$(curl -s ifconfig.me)
echo "Your current public IP: ${MY_IP}"
echo ""
echo "To test this for real:"
echo "  1. Edit terraform/environments/lab/main.tf's trusted_ips module"
echo "  2. Replace 106.219.121.230/32 with ${MY_IP}/32"
echo "  3. Confirm Cloud Armor Enterprise is active on the project"
echo "  4. terraform apply, then re-run this script"
echo ""

echo "Hitting vuln-bank LB (address group won't match you until step 2 above):"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/"
