#!/bin/bash
# Demonstrates: rules-redirect.tf — GOOGLE_RECAPTCHA and EXTERNAL_302.
# Both rules trigger on a custom header (not path/content) so they don't
# collide with the rate-limit rules already targeting /login and /transfer
# — see that file's own comment for why.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== External 302 redirect demo ==="
curl -sk -D - -o /dev/null "https://${VULNBANK_LB_IP}/" \
  -H "x-lab-redirect-demo: true" | grep -i "^HTTP\|^location"
echo "Expect HTTP 302 with a Location header pointing at cloud.google.com/armor."

echo ""
echo "=== reCAPTCHA Enterprise challenge demo ==="
echo "(Requires reCAPTCHA Enterprise configured on the project + backend"
echo " service — see docs/enterprise-features/bot-management-tokens.md."
echo " Without that configured, this rule creates fine but won't actually"
echo " challenge anything.)"
curl -sk -X POST "https://${VULNBANK_LB_IP}/login" \
  -H "x-lab-suspicious: true" \
  -d "username=test&password=test" \
  -o /dev/null -w "HTTP %{http_code}\n"
echo "With reCAPTCHA Enterprise configured, expect a challenge response"
echo "instead of a normal login attempt reaching the app."
