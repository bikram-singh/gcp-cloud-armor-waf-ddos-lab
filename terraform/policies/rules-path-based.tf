# Path-based custom CEL rules — mirrors the original lab's /goodpath,
# /badpath demo against the nginx backend. `request.path` is a CEL field
# Cloud Armor populates from the incoming HTTP request.
locals {
  path_based_rules = [
    {
      priority    = 3000
      action      = "deny(403)"
      description = "Deny anything under /badpath/"
      expression  = "request.path.matches('/badpath/.*')"
    },
    {
      priority    = 3001
      action      = "allow"
      description = "Explicitly allow /goodpath/ (redundant with default allow, kept for the demo's before/after contrast)"
      expression  = "request.path.matches('/goodpath/.*')"
    },
  ]
}
