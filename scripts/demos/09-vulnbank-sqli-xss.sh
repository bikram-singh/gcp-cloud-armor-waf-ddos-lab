#!/bin/bash
# Demonstrates: rules-preconfigured-waf.tf — SQLi on /login, XSS on a
# vuln-bank form field, both blocked by the OWASP preconfigured rules.
#
# The SQLi payload/field below matches vuln-bank's own documented
# vulnerability ("SQL Injection in login" — see its README's testing
# guide). The XSS target is a generic best-guess at a likely field
# (profile/feedback-style input) — vuln-bank's README confirms XSS exists
# but doesn't name the exact field in its docs; check the app's actual
# HTML templates (vulnerable-app/templates/) to confirm before relying on
# this in a real demo, and adjust the field name below if needed.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "=== SQLi demo: classic OR-based payload against /login ==="
echo "Without Cloud Armor, this payload can bypass login by making the"
echo "SQL query's WHERE clause always evaluate true."
curl -sk -X POST "https://${VULNBANK_LB_IP}/login" \
  -d "username=admin' OR '1'='1' --&password=anything" \
  -o /dev/null -w "HTTP %{http_code}\n"
echo "Expect 403 — blocked by rules-preconfigured-waf.tf's sqli-v33-stable rule."

echo ""
echo "=== XSS demo: script payload against a profile/feedback-style field ==="
echo "(Adjust the field/endpoint below once you've confirmed the real one"
echo " from vulnerable-app/templates/ — this is a representative example.)"
curl -sk -X POST "https://${VULNBANK_LB_IP}/profile" \
  -d "bio=<script>alert(document.cookie)</script>" \
  -o /dev/null -w "HTTP %{http_code}\n"
echo "Expect 403 — blocked by rules-preconfigured-waf.tf's xss-v33-stable rule."
