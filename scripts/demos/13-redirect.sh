#!/bin/bash
# Demonstrates: rules-redirect.tf -- GOOGLE_RECAPTCHA and EXTERNAL_302.
#
# EXTERNAL_302 now targets its own dedicated path (/redirect-test), not
# root -- retargeted after regression testing caught a real collision
# with JA4's root-path rate-limit rule. See rules-redirect.tf's comment
# for the full story.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh
echo "=== External 302 redirect demo ==="
curl -sk -D - -o /dev/null "https://${VULNBANK_LB_IP}/redirect-test" \
  -H "x-lab-redirect-demo: true" | grep -i "^HTTP\|^location"
echo "Expect HTTP 302 with a Location header pointing at cloud.google.com/armor."
echo ""
echo "=== reCAPTCHA Enterprise challenge demo ==="
echo "(Requires reCAPTCHA Enterprise configured on the project + backend"
echo " service -- CONFIRMED inert without it, see docs/enterprise-features/bot-management-tokens.md.)"
curl -sk -X POST "https://${VULNBANK_LB_IP}/login" \
  -H "x-lab-suspicious: true" \
  -d "username=test&password=test" \
  -o /dev/null -w "HTTP %{http_code}\n"
echo "With reCAPTCHA Enterprise configured, expect a challenge response"
echo "instead of a normal login attempt reaching the app."
