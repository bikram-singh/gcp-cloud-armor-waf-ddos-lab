# Redirect actions -- mirrors the original lab's reCAPTCHA + external 302
# demo. Both rules trigger on a custom header (not path/content) so they
# do not collide with the rate-limit rules already targeting /login and
# /transfer -- see that file's own comment for why.
#
# PRIORITY: reCAPTCHA sits at 3500 (below path-based rules at 3000s, above
# rate-limit at 4000s) -- moved here after a real test showed it was
# originally unreachable at priority 5000, since the /login rate-limit
# rule at 4000 always won first for the same traffic.
#
# CONFIRMED FINDING (stronger than the original caveat): GOOGLE_RECAPTCHA
# redirect rules require an actual reCAPTCHA Enterprise key configured on
# the project/backend to be ENFORCED AT ALL -- not just to render a real
# challenge. Tested directly: the EXTERNAL_302 rule below uses the
# identical header-matching CEL pattern and fires correctly (confirmed via
# a clean 302 + Location header). The GOOGLE_RECAPTCHA rule, using the
# same pattern, never fired even after being moved to a higher-precedence
# priority -- every test request instead fell through to the next rule
# that matched (the /login rate-limit at 4000). This means an
# unconfigured GOOGLE_RECAPTCHA rule appears to go effectively INERT
# (silently skipped), not "fires but the challenge itself does not
# render." Not independently re-verifiable without an actual reCAPTCHA
# Enterprise key configured, which is a separate paid product from Cloud
# Armor Enterprise -- see docs/enterprise-features/bot-management-tokens.md.
locals {
  redirect_rules = [
    {
      priority      = 3500
      action        = "redirect"
      description   = "Challenge suspicious traffic to /login with reCAPTCHA Enterprise (CONFIRMED inert without an actual reCAPTCHA Enterprise key configured -- see comment above)"
      expression    = "request.path == '/login' && request.headers['x-lab-suspicious'] == 'true'"
      redirect_type = "GOOGLE_RECAPTCHA"
    },
    {
      priority        = 5001
      action          = "redirect"
      description     = "External 302 redirect demo -- sends flagged traffic to a static notice page (CONFIRMED working via real test: clean 302 + Location header)"
      expression      = "request.headers['x-lab-redirect-demo'] == 'true'"
      redirect_type   = "EXTERNAL_302"
      redirect_target = "https://cloud.google.com/armor"
    },
  ]
}
