locals {
  # Split rules into the two match styles the underlying resource accepts:
  # a plain IP/address-group list (versioned_expr = SRC_IPS_V1) or a full
  # CEL expression. A rule qualifies for the IP bucket if it sets EITHER
  # src_ip_ranges or src_address_groups (or both â€” GCP allows combining them,
  # matched as OR).
  ip_rules = {
    for r in var.rules : tostring(r.priority) => r
    if r.src_ip_ranges != null || r.src_address_groups != null
  }
  cel_rules = {
    for r in var.rules : tostring(r.priority) => r
    if r.src_ip_ranges == null && r.src_address_groups == null
  }
}

# ---------------------------------------------------------------------------
# Global backend security policy
# ---------------------------------------------------------------------------
resource "google_compute_security_policy" "global" {
  count       = var.regional ? 0 : 1
  project     = var.project_id
  name        = var.policy_name
  description = var.description
  type        = "CLOUD_ARMOR"

  advanced_options_config {
    json_parsing             = var.json_parsing
    log_level                = var.log_level
    user_ip_request_headers  = var.user_ip_request_headers
  }

  dynamic "adaptive_protection_config" {
    for_each = var.adaptive_protection_enabled ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable = true
      }
    }
  }
}

resource "google_compute_security_policy_rule" "global_ip" {
  for_each        = var.regional ? {} : local.ip_rules
  project         = var.project_id
  security_policy = google_compute_security_policy.global[0].name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action
  preview         = each.value.preview

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges      = each.value.src_ip_ranges
    }
  }

  dynamic "rate_limit_options" {
    for_each = each.value.rate_limit_options != null ? [each.value.rate_limit_options] : []
    content {
      conform_action = rate_limit_options.value.conform_action
      exceed_action  = rate_limit_options.value.exceed_action
      enforce_on_key = rate_limit_options.value.enforce_on_key
      rate_limit_threshold {
        count        = rate_limit_options.value.rate_limit_threshold_count
        interval_sec = rate_limit_options.value.rate_limit_threshold_interval_sec
      }
      dynamic "ban_threshold" {
        for_each = rate_limit_options.value.ban_threshold_count != null ? [1] : []
        content {
          count        = rate_limit_options.value.ban_threshold_count
          interval_sec = rate_limit_options.value.ban_threshold_interval_sec
        }
      }
      ban_duration_sec = rate_limit_options.value.ban_duration_sec
    }
  }

  dynamic "redirect_options" {
    for_each = each.value.redirect_type != null ? [1] : []
    content {
      type   = each.value.redirect_type
      target = each.value.redirect_target
    }
  }

  dynamic "header_action" {
    for_each = each.value.header_action != null ? [1] : []
    content {
      dynamic "request_headers_to_adds" {
        for_each = each.value.header_action
        content {
          header_name  = request_headers_to_adds.key
          header_value = request_headers_to_adds.value
        }
      }
    }
  }
}

resource "google_compute_security_policy_rule" "global_cel" {
  for_each        = var.regional ? {} : local.cel_rules
  project         = var.project_id
  security_policy = google_compute_security_policy.global[0].name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action
  preview         = each.value.preview

  match {
    expr {
      expression = each.value.expression
    }
  }

  dynamic "rate_limit_options" {
    for_each = each.value.rate_limit_options != null ? [each.value.rate_limit_options] : []
    content {
      conform_action = rate_limit_options.value.conform_action
      exceed_action  = rate_limit_options.value.exceed_action
      enforce_on_key = rate_limit_options.value.enforce_on_key
      rate_limit_threshold {
        count        = rate_limit_options.value.rate_limit_threshold_count
        interval_sec = rate_limit_options.value.rate_limit_threshold_interval_sec
      }
      dynamic "ban_threshold" {
        for_each = rate_limit_options.value.ban_threshold_count != null ? [1] : []
        content {
          count        = rate_limit_options.value.ban_threshold_count
          interval_sec = rate_limit_options.value.ban_threshold_interval_sec
        }
      }
      ban_duration_sec = rate_limit_options.value.ban_duration_sec
    }
  }

  dynamic "redirect_options" {
    for_each = each.value.redirect_type != null ? [1] : []
    content {
      type   = each.value.redirect_type
      target = each.value.redirect_target
    }
  }

  # WAF field exclusions â€” fixes false positives by excluding a named
  # header/cookie/query-param's VALUE from inspection (the name is still
  # inspected). This is a long-established Cloud Armor feature, schema
  # should be stable â€” unlike the JA3/JA4 enforce_on_key values elsewhere
  # in this module, no verification caveat needed here.
  dynamic "preconfigured_waf_config" {
    for_each = (each.value.waf_exclusions != null && length(each.value.waf_exclusions) > 0) ? [1] : []
    content {
      dynamic "exclusion" {
        for_each = each.value.waf_exclusions
        content {
          target_rule_set = exclusion.value.target_rule_set

          dynamic "request_header" {
            for_each = coalesce(exclusion.value.request_headers, [])
            content {
              operator = "EQUALS"
              value    = request_header.value
            }
          }
          dynamic "request_query_param" {
            for_each = coalesce(exclusion.value.request_query_params, [])
            content {
              operator = "EQUALS"
              value    = request_query_param.value
            }
          }
          dynamic "request_cookie" {
            for_each = coalesce(exclusion.value.request_cookies, [])
            content {
              operator = "EQUALS"
              value    = request_cookie.value
            }
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Regional backend security policy (mirrors the global resources above)
# ---------------------------------------------------------------------------
resource "google_compute_region_security_policy" "regional" {
  count       = var.regional ? 1 : 0
  project     = var.project_id
  region      = var.region
  name        = var.policy_name
  description = var.description
  type        = "CLOUD_ARMOR"
}

resource "google_compute_region_security_policy_rule" "regional_ip" {
  for_each        = var.regional ? local.ip_rules : {}
  project         = var.project_id
  region          = var.region
  security_policy = google_compute_region_security_policy.regional[0].name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action
  preview         = each.value.preview

  match {
    config {
      src_ip_ranges      = each.value.src_ip_ranges
    }
  }
}

# NOTE: waf_exclusions is not yet wired into the regional_cel resource below
# (this lab only uses waf_exclusions on the global policy). Add a matching
# `dynamic "preconfigured_waf_config"` block here, copied from global_cel
# above, if you need field exclusions on a regional policy.

resource "google_compute_region_security_policy_rule" "regional_cel" {
  for_each        = var.regional ? local.cel_rules : {}
  project         = var.project_id
  region          = var.region
  security_policy = google_compute_region_security_policy.regional[0].name
  priority        = each.value.priority
  description     = each.value.description
  action          = each.value.action
  preview         = each.value.preview

  match {
    expr {
      expression = each.value.expression
    }
  }
}
