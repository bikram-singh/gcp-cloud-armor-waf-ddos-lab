#!/bin/bash
# Demonstrates: rules-user-ip-header.tf — Cloud Armor trusting a header
# (X-Forwarded-For) as the client's true origin IP instead of the
# immediate connecting IP.
#
# This IS testable end-to-end, unlike the JA3/JA4/geo scripts: since
# user_ip_request_headers = ["X-Forwarded-For"] is set policy-wide, Cloud
# Armor will evaluate IP-based rules against whatever IP YOU put in that
# header — not your real connecting IP. Sending a header value that
# matches the placeholder deny rule in rules-ip-based.tf should get you
# denied, even though your actual IP doesn't match it.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== Baseline: normal request, no spoofed header ==="
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/"
echo "(Expect 200 — your real IP isn't in any deny rule)"

echo ""
echo "=== Spoofed X-Forwarded-For matching the placeholder deny rule ==="
echo "(203.0.113.1 is the placeholder IP denied in rules-ip-based.tf)"
curl -sk -H "X-Forwarded-For: 203.0.113.1" -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/"
echo "If user_ip_request_headers is correctly trusting this header, expect"
echo "403 here — proving Cloud Armor evaluated the HEADER value, not your"
echo "real connecting IP."
echo ""
echo "CAVEAT: this only proves the mechanism works when a request carries"
echo "the header at all. In this lab's actual architecture (LB sits"
echo "directly in front of the VMs, no other proxy/CDN ahead of it), any"
echo "client can set this header directly — which is exactly why this"
echo "setting should only be trusted when you KNOW all traffic passes"
echo "through a specific upstream proxy that sets it, and that upstream is"
echo "the only thing allowed to reach this LB directly."
