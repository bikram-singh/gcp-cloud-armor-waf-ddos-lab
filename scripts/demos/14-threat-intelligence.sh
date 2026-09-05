#!/bin/bash
# Demonstrates: rules-threat-intelligence.tf — Google Threat Intelligence
# feeds (Tor exit nodes, known malicious IPs). Requires Cloud Armor
# Enterprise — the rules create fine on Standard tier, they just won't
# enforce until Enterprise is active on the project.
#
# HONEST LIMITATION: there's no simple, repeatable way to make your own
# traffic originate from a Tor exit node or a known-malicious IP on
# demand from this script. This demo is best understood by reading the
# CEL syntax and, if you want to actually see it fire, manually routing a
# single test request through the Tor Browser (which will exit through a
# real Tor exit node) while Enterprise is active — not something this
# script can automate.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "Baseline request (not from Tor / not on a threat-intel list):"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/"
echo "(Expect 200 regardless of Enterprise status — your normal IP isn't"
echo " on either threat-intel feed)"
echo ""
echo "To manually test the Tor-exit-node rule: with Cloud Armor Enterprise"
echo "active, open ${VULNBANK_LB_IP} via the Tor Browser and confirm you"
echo "get denied. This can't be scripted reliably since Tor exit nodes"
echo "rotate and aren't something curl can route through directly."
