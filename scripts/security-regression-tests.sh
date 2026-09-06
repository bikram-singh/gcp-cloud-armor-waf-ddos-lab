#!/bin/bash
# Automated security regression tests -- confirms core Cloud Armor
# protections still behave as expected. Designed to run in CI on a
# schedule (or manually), so a future rule change, priority reorder, or
# accidental revert gets caught automatically instead of relying on
# someone remembering to re-run the manual demo scripts.
#
# Every check here mirrors a real, manually-confirmed finding from this
# project's negative-testing round -- see docs/cicd-setup.md and the
# individual rules-*.tf files for the full evidence behind each one.
#
# NOT covered here (documented limitations, not oversights):
#   - IP-based deny: rules-ip-based.tf uses a placeholder IP
#     (203.0.113.1/32); a real CI runner's IP varies and isn't the
#     placeholder, so this can't be meaningfully asserted here.
#   - Geo-blocking: requires a genuinely US-origin request (confirmed
#     manually via a temporary us-central1 VM); not practical to
#     automate cheaply in a scheduled job.
#   - JA3/JA4 fingerprint keying: confirmed manually via a real
#     browser-vs-curl comparison; a CI runner only ever presents one
#     TLS fingerprint (curl's), so the "different client, independent
#     bucket" distinction can't be exercised here.
#   - Regional / Edge policies: these were TEMPORARY test stacks,
#     already torn down after confirming the finding; not part of the
#     permanently shipped infrastructure this script checks.
#
# Exit code: 0 if all checks pass, 1 if any check fails or errors.

set -uo pipefail

VULNBANK="${VULNBANK_LB_HOST:-vulnbank-lab.gcpcloudhub.in}"
NGINX="${NGINX_LB_HOST:-nginx-lab.gcpcloudhub.in}"

PASS=0
FAIL=0

check() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  if [ "$actual" == "$expected" ]; then
    echo "PASS: ${description} (expected ${expected}, got ${actual})"
    PASS=$((PASS + 1))
  else
    echo "FAIL: ${description} (expected ${expected}, got ${actual})"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== 1. Baseline: normal traffic still allowed ==="
CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${VULNBANK}/")
check "baseline GET / on vulnbank" "200" "$CODE"

CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${NGINX}/")
check "baseline GET / on nginx" "200" "$CODE"

echo ""
echo "=== 2. Path-based rule (nginx) ==="
CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${NGINX}/goodpath/")
check "GET /goodpath/ still allowed" "200" "$CODE"

CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${NGINX}/badpath/")
check "GET /badpath/ still denied" "403" "$CODE"

echo ""
echo "=== 3. SQLi protection (WAF sensitivity 1, confirmed shipped default) ==="
CODE=$(curl -sk -X POST "https://${VULNBANK}/login" \
  -d "username=admin' UNION SELECT 1,2,3--&password=x" \
  -o /dev/null -w "%{http_code}")
check "UNION-based SQLi on /login still blocked" "403" "$CODE"

echo ""
echo "=== 4. XSS protection (register form, unauthenticated) ==="
CODE=$(curl -sk -X POST "https://${VULNBANK}/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"<script>alert(1)</script>","email":"test@example.com","password":"x"}' \
  -o /dev/null -w "%{http_code}")
check "XSS payload on /register still blocked" "403" "$CODE"

echo ""
echo "=== 5. Rate limiting: /login throttle (10 req/min, confirmed threshold) ==="
LAST_CODE=200
for i in $(seq 1 11); do
  LAST_CODE=$(curl -sk -X POST "https://${VULNBANK}/login" \
    -d "username=ratelimittest&password=x" \
    -o /dev/null -w "%{http_code}")
done
check "11th rapid /login request still throttled" "429" "$LAST_CODE"

echo ""
echo "=== 6. Redirect: external 302 (custom header trigger, dedicated path) ==="
LOCATION=$(curl -sk -D - -o /dev/null "https://${VULNBANK}/redirect-test" \
  -H "x-lab-redirect-demo: true" | grep -i "^location" | tr -d '\r')
if [[ "$LOCATION" == *"cloud.google.com/armor"* ]]; then
  echo "PASS: external 302 redirect still fires (${LOCATION})"
  PASS=$((PASS + 1))
else
  echo "FAIL: external 302 redirect did not fire as expected (got: '${LOCATION}')"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=================================================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "=================================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
