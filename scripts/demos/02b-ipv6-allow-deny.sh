#!/bin/bash
# Demonstrates: rules-ip-based-ipv6.tf — same allow/deny pattern, IPv6.
#
# The rule uses 2001:db8::/32, an RFC 3849 documentation range — will
# never match real traffic. This script shows your current public IPv6
# (if your network has one — many home/mobile connections are IPv4-only,
# in which case this will fail and that's expected, not a bug).
#
# FIXED (was a gap): the vulnbank LB now provisions a real IPv6 forwarding
# rule (https-lb module's enable_ipv6 = true, environments/lab/main.tf).
# This tests against VULNBANK_LB_IPV6, a genuinely separate address from
# VULNBANK_LB_IP — both point at the same backend service and Cloud Armor
# policy, just via different frontend addresses.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "Your current public IPv6 (if any):"
curl -s -6 ifconfig.me || echo "(no IPv6 connectivity detected — this demo needs an IPv6-capable network to test against your own address)"

echo ""
echo "Hitting vuln-bank LB's dedicated IPv6 address:"
curl -sk -6 -o /dev/null -w "HTTP %{http_code}\n" "https://[${VULNBANK_LB_IPV6}]/" || echo "(IPv6 request failed — check your network's IPv6 connectivity)"
