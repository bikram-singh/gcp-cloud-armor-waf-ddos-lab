# Redirect actions -- mirrors the original lab's reCAPTCHA + external 302
# demo.
#
# PRIORITY 3500 (reCAPTCHA): below path-based rules, above rate-limit --
# moved here after a real test showed it was originally unreachable at
# priority 5000, since the /login rate-limit rule at 4000 always won
# first for the same traffic. See docs/enterprise-features/bot-management-tokens.md
# for the confirmed finding that this rule is inert without an actual
# reCAPTCHA Enterprise key regardless of priority.
#
# EXTERNAL_302: RETARGETED from unconditional root "/" to its own
# dedicated path (/redirect-test), after the automated security
# regression suite (scripts/security-regression-tests.sh) caught a real,
# previously-unnoticed regression: retargeting the JA4 rate-limit rule to
# "/" (rules-rate-limit-ja4.tf) created a NEW collision -- JA4's
# unconditional root-path match, at priority 4025, sat below this rule's
# original priority 5001, silently absorbing all root traffic (THROTTLE/
# ACCEPT) before the redirect rule was ever evaluated. Confirmed via a
# real log entry: enforcedSecurityPolicy.priority showed 4025 (JA4), not
# 5001 (redirect), for a request that should have redirected.
#
# This is the fourth confirmed instance of the same recurring bug class
# in this project: two rules matching overlapping/unconditional traffic
# on the same path always have exactly one that matters, whichever sits
# at the lower priority number -- and fixing one collision can silently
# create another if the "fixed" rule's new match condition overlaps with
# something else. The durable fix, applied consistently now: give each
# rate-limit/redirect/challenge rule needing broad matching its OWN
# dedicated path, never root or another rule's already-claimed path.
locals {
  redirect_rules = [
    {
      priority      = 3500
      action        = "redirect"
      description   = "Challenge suspicious traffic to /login with reCAPTCHA Enterprise (CONFIRMED inert without an actual reCAPTCHA Enterprise key configured)"
      expression    = "request.path == '/login' && request.headers['x-lab-suspicious'] == 'true'"
      redirect_type = "GOOGLE_RECAPTCHA"
    },
    {
      priority        = 5001
      action          = "redirect"
      description     = "External 302 redirect demo -- dedicated path (/redirect-test), fixed after regression testing caught a collision with JA4's root-path rate-limit rule"
      expression      = "request.path == '/redirect-test' && request.headers['x-lab-redirect-demo'] == 'true'"
      redirect_type   = "EXTERNAL_302"
      redirect_target = "https://cloud.google.com/armor"
    },
  ]
}
