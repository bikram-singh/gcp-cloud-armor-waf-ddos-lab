locals {
  preconfigured_waf_rules = [
    {
      priority     = 1000
      action       = "deny(403)"
      description  = "Block SQL injection - targets vuln-bank /login and biller-query SQLi"
      expression   = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
    },
    {
      priority     = 1001
      action       = "deny(403)"
      description  = "Block XSS - targets vuln-bank feedback/profile field XSS"
      expression   = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
    },
  ]
}
