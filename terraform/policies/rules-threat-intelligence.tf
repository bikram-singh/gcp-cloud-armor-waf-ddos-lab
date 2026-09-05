# Google Threat Intelligence — allow/block by threat category (Tor exit
# nodes, known malicious IPs, public cloud ranges). Requires Cloud Armor
# Enterprise. The rule creates fine on Standard tier; it just won't
# enforce until Enterprise is active on the project — same pattern as
# address groups elsewhere in this repo.
locals {
  threat_intelligence_rules = [
    {
      priority    = 6000
      action      = "deny(403)"
      description = "Block traffic from Tor exit nodes (Enterprise required to enforce)"
      expression  = "evaluateThreatIntelligence('iplist-tor-exit-nodes')"
    },
    {
      priority    = 6001
      action      = "deny(403)"
      description = "Block traffic from known malicious IPs (Enterprise required to enforce)"
      expression  = "evaluateThreatIntelligence('iplist-known-malicious-ips')"
    },
  ]
}
