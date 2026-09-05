# TEMP TEST: preview mode -- CONFIRMED via real log evidence. A request
# matching this rule's condition produces a SEPARATE "previewSecurityPolicy"
# log field showing what WOULD have happened (configuredAction: DENY,
# outcome: DENY, preview: true, priority: 6000), while the actual
# "enforcedSecurityPolicy" field shows the real outcome from the next
# matching rule instead (in testing, priority 9000's baseline allow). This
# is the exact log field to check when validating a new rule in preview
# before turning enforcement on for real -- previewSecurityPolicy, not
# enforcedSecurityPolicy.
locals {
  preview_test_rules = [
    {
      priority    = 6000
      action      = "deny(403)"
      description = "TEMP TEST: preview mode -- CONFIRMED via real log evidence, see comment above"
      expression  = "request.headers['x-lab-preview-test'] == 'true'"
      preview     = true
    },
  ]
}
