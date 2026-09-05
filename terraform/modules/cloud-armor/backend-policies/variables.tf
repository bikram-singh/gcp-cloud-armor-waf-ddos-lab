variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "policy_name" {
  description = "Name of the Cloud Armor backend security policy"
  type        = string
}

variable "description" {
  description = "Description of the security policy"
  type        = string
  default     = "Managed by Terraform - gcp-cloud-armor-waf-ddos-lab"
}

variable "regional" {
  description = "If true, creates a regional backend security policy instead of global"
  type        = bool
  default     = false
}

variable "region" {
  description = "Region for the policy when regional = true"
  type        = string
  default     = null
}

variable "adaptive_protection_enabled" {
  description = "Enable Adaptive Protection (L7 DDoS). Requires an active Cloud Armor Enterprise subscription in the project."
  type        = bool
  default     = false
}

variable "json_parsing" {
  description = "Whether Cloud Armor parses JSON request bodies for WAF inspection. One of DISABLED, STANDARD."
  type        = string
  default     = "DISABLED"
}

variable "log_level" {
  description = "Logging verbosity for this policy. One of NORMAL, VERBOSE. Policy-wide, not per-rule — see rules-logging-modes.tf for the demo reasoning."
  type        = string
  default     = "NORMAL"
}

variable "user_ip_request_headers" {
  description = "Policy-wide: header name(s) Cloud Armor trusts as the client's true origin IP when traffic arrives via another proxy/CDN in front of this LB (e.g. [\"X-Forwarded-For\"]). Affects IP-based match/rate-limit evaluation for every rule in this policy. Leave null/empty to use the immediate connecting IP (the default)."
  type        = list(string)
  default     = null
}

# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------
# One object per Cloud Armor rule. Only the fields relevant to a given rule's
# match type need to be set; everything else can be left null/default.
variable "rules" {
  description = "List of Cloud Armor security policy rules to attach to this policy"
  type = list(object({
    priority    = number
    action      = string # allow | deny(403|404|502) | throttle | rate_based_ban | redirect
    description = optional(string, "")
    preview     = optional(bool, false)

    # --- Match condition: exactly one of the following patterns ---
    # 1. Simple IP allow/deny (versioned expr) — src_ip_ranges and/or
    #    src_address_groups (requires Cloud Armor Enterprise to enforce;
    #    the rule creates fine on Standard tier, see modules/address-groups)
    src_ip_ranges      = optional(list(string))
    src_address_groups = optional(list(string))

    # 2. Custom CEL expression (path-based, geo, ASN, header, JA3/JA4, etc.)
    expression = optional(string)

    # 3. Preconfigured WAF rule (sqli-stable, xss-stable, etc.) — pass the
    #    full evaluatePreconfiguredWaf(...) CEL expression via `expression`
    #    above; this block only carries the tuning metadata for documentation.
    waf_rule_set    = optional(string) # e.g. "sqli-v33-stable"
    waf_sensitivity = optional(number) # 0-4, OWASP paranoia level

    # WAF field exclusions — value of the named header/cookie/query-param is
    # skipped during inspection (the field NAME is still inspected). Fixes
    # false positives without disabling the whole signature. Applied via
    # operator EQUALS against the given field name(s).
    waf_exclusions = optional(list(object({
      target_rule_set       = string # must match the waf_rule_set this exclusion applies to
      request_headers       = optional(list(string))
      request_query_params  = optional(list(string))
      request_cookies       = optional(list(string))
    })))

    # --- Rate limiting (action = throttle | rate_based_ban) ---
    rate_limit_options = optional(object({
      conform_action                     = string # allow
      exceed_action                      = string # deny(429) | redirect
      enforce_on_key                     = string # IP | HTTP_HEADER | ALL | XFF_IP | HTTP_COOKIE | SNI (JA3/JA4 use HTTP_HEADER on the fingerprint header today; verify current enum in the provider docs)
      enforce_on_key_name                = optional(string)
      rate_limit_threshold_count         = number
      rate_limit_threshold_interval_sec  = number
      ban_threshold_count                = optional(number)
      ban_threshold_interval_sec         = optional(number)
      ban_duration_sec                   = optional(number)
    }))

    # --- Redirect (action = redirect) ---
    redirect_type   = optional(string) # GOOGLE_RECAPTCHA | EXTERNAL_302
    redirect_target = optional(string) # required for EXTERNAL_302

    # --- Header action: inject a header on match (used for the "user IP
    #     request header" demo, e.g. tagging matched requests) ---
    header_action = optional(map(string))
  }))
  default = []
}
