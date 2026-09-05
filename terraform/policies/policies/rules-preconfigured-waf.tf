# Preconfigured WAF rules (OWASP CRS) — targets vuln-bank's known
# SQLi-in-login and XSS-in-feedback vulnerabilities (see
# vulnerable-app/NOTES.md and scripts/demos/09-vulnbank-sqli-xss.sh).
#
# Sensitivity 1 = highest-confidence signatures only (least false-positive
# prone). Raise to 2-4 for more aggressive coverage at the cost of more
# false positives — see rules-waf-tuning.tf for how to recover from one.
#
# NOTE — CVE canary rules: Cloud Armor also ships rapid-response
# "cve-canary" signatures for specific active CVEs (e.g. the RCE signature
# shipped for CVE-2025-55182 in Dec 2025). These apply automatically as
# part of the managed ruleset — no rule needed here to enable them, and no
# action required to keep them current.
locals {
  preconfigured_waf_rules = [
    {
      priority    = 1000
      action      = "deny(403)"
      description = "Block SQL injection — targets vuln-bank /login and biller-query SQLi"
      expression  = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
    },
    {
      priority    = 1001
      action      = "deny(403)"
      description = "Block XSS — targets vuln-bank feedback/profile field XSS"
      expression  = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
    },
  ]
}
