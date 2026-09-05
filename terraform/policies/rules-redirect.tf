# Redirect actions — mirrors the original lab's reCAPTCHA + external 302
# demo. GOOGLE_RECAPTCHA requires reCAPTCHA Enterprise configured on the
# project (a reCAPTCHA Enterprise key + integration on the backend service)
# — the rule itself creates fine without it, but won't actually challenge
# traffic until that's set up. See docs/enterprise-features/bot-management-tokens.md.
locals {
  redirect_rules = [
    {
      priority      = 5000
      action        = "redirect"
      description   = "Challenge suspicious traffic to /login with reCAPTCHA Enterprise"
      expression    = "request.path == '/login' && request.headers['x-lab-suspicious'] == 'true'"
      redirect_type = "GOOGLE_RECAPTCHA"
    },
    {
      priority        = 5001
      action          = "redirect"
      description     = "External 302 redirect demo — sends flagged traffic to a static notice page"
      expression      = "request.headers['x-lab-redirect-demo'] == 'true'"
      redirect_type   = "EXTERNAL_302"
      redirect_target = "https://cloud.google.com/armor"
    },
  ]
}
