# Alerting for Cloud Armor -- closes the loop from "logs exist" to
# "someone gets paged". Two alert policies:
#   1. Deny-rate spike: a burst of DENY outcomes in a short window,
#      which could mean an attack in progress, OR could mean a
#      legitimate WAF/rate-limit rule is misfiring against real traffic
#      (see this project's own confirmed registration false-positive --
#      that incident SHOULD have paged someone in a real deployment, and
#      didn't, because no alerting existed yet).
#   2. Unexpected policy changes: fires on ANY Cloud Armor security
#      policy modification via the Admin Activity audit log, so a rule
#      change (intentional or not) is always visible, not just
#      discovered later by noticing different behavior.

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Cloud Armor Lab Alerts"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

# --- Alert 1: Deny-rate spike ------------------------------------------

resource "google_logging_metric" "cloud_armor_denies" {
  project = var.project_id
  name    = "cloud_armor_deny_count"
  filter  = <<-EOT
    resource.type="http_load_balancer"
    jsonPayload.enforcedSecurityPolicy.outcome="DENY"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "deny_rate_spike" {
  project      = var.project_id
  display_name = "Cloud Armor: deny-rate spike"
  combiner     = "OR"

  conditions {
    display_name = "DENY outcomes exceed threshold in window"

    condition_threshold {
      # CONFIRMED via a direct Monitoring API query against real data:
      # this log-based metric's underlying time series carry resource
      # type "l7_lb_rule" (Cloud Monitoring's naming), NOT "global" and
      # NOT "http_load_balancer" (that's the LOGGING resource type the
      # source log entries have -- Logging and Monitoring use different
      # resource-type naming for the same underlying data, confirmed the
      # hard way after both of those guesses failed with two distinct,
      # genuinely different errors).
      filter          = "resource.type=\"l7_lb_rule\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloud_armor_denies.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.deny_rate_threshold
      duration        = "0s"

      aggregations {
        alignment_period     = "${var.deny_rate_window_seconds}s"
        per_series_aligner   = "ALIGN_RATE"
        # This project has TWO backend services (nginx, vulnbank), each
        # producing its own time series for this metric (distinguished
        # by the backend_name resource label). Without summing across
        # them, the alert would only ever look at ONE backend's slice of
        # traffic at a time depending on which series the API happened
        # to return first -- confirmed the real resource labels via a
        # direct API query (backend_name, url_map_name,
        # forwarding_rule_name, target_proxy_name, project_id all
        # present). REDUCE_SUM + empty group_by_fields combines all of
        # them into one total.
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields       = []
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "Cloud Armor denied more than ${var.deny_rate_threshold} requests (summed across all backend services) in the last ${var.deny_rate_window_seconds} seconds. This could mean a genuine attack in progress, OR a WAF/rate-limit rule misfiring against legitimate traffic (this project has confirmed real instances of both). See docs/incident-response-runbook.md for the triage steps -- do not assume it's an attack without checking which rule fired and against what traffic first."
    mime_type = "text/markdown"
  }
}

# --- Alert 2: Unexpected Cloud Armor policy changes --------------------

resource "google_logging_metric" "cloud_armor_policy_changes" {
  project = var.project_id
  name    = "cloud_armor_policy_change_count"
  filter  = <<-EOT
    protoPayload.methodName=~"compute.securityPolicies.(patch|insert|delete|removeRule|patchRule|addRule)"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "policy_changed" {
  project      = var.project_id
  display_name = "Cloud Armor: security policy changed"
  combiner     = "OR"

  conditions {
    display_name = "Any Cloud Armor policy mutation"

    condition_threshold {
      filter          = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloud_armor_policy_changes.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "A Cloud Armor security policy was modified (rule added, removed, or changed). This fires on EVERY change, including intentional ones made via terraform apply -- it is a visibility signal, not necessarily an incident. Confirm the change was expected (check recent commits/applies) before treating it as suspicious."
    mime_type = "text/markdown"
  }
}
