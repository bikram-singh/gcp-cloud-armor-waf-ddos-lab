# Preconfigured WAF rules (OWASP CRS) -- targets vuln-bank's known
# SQLi-in-login and XSS-in-feedback vulnerabilities (see
# vulnerable-app/NOTES.md and scripts/demos/09-vulnbank-sqli-xss.sh).
#
# SENSITIVITY DECISION (locked in after real testing): kept at 1, not
# raised to 2, despite sensitivity 2 catching one additional SQLi payload
# shape (a tautology "OR '1'='1'" pattern that sensitivity 1 missed --
# see rules-waf-tuning.tf's earlier test). The reason: sensitivity 2 was
# tested live against this deployment and confirmed to BLOCK ORDINARY
# USER REGISTRATION ENTIRELY -- not an edge case, a complete false
# positive on the app's core /register flow, using plain values with no
# special characters or SQL-like content at all (username "testuser1",
# email "testuser1@example.com", password "SimplePass123"). Reverting to
# sensitivity 1 immediately fixed it; the same registration succeeded.
#
# This is the real, evidence-backed reason this project settled on
# sensitivity 1 as the shipped default: broader SQLi coverage at
# sensitivity 2 is real, but the false-positive cost measured here was
# severe enough (blocking all new signups) to outweigh it for a
# general-purpose deployment. A production app might reasonably choose
# differently with proper exclusion tuning in place first (see
# rules-waf-tuning.tf) rather than accepting broad sensitivity 2 as-is.
#
# CVE canary rules also apply automatically as part of the managed
# ruleset -- no rule needed here, no action required to keep them current.
locals {
  preconfigured_waf_rules = [
    {
      priority    = 1000
      action      = "deny(403)"
      description = "Block SQL injection -- targets vuln-bank /login and biller-query SQLi. Sensitivity 1, kept deliberately conservative -- see comment above for the real registration-breaking false positive found at sensitivity 2."
      expression  = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
    },
    {
      priority    = 1001
      action      = "deny(403)"
      description = "Block XSS -- targets vuln-bank's documented stored-XSS bio vulnerability. CONFIRMED working via a real payload test (<script>alert(document.cookie)</script> against /update_bio, blocked by owasp-crs-v030301-id941180-xss)."
      expression  = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
    },
  ]
}
