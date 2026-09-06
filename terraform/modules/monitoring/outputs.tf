output "notification_channel_id" {
  value = google_monitoring_notification_channel.email.id
}

output "deny_rate_alert_id" {
  value = google_monitoring_alert_policy.deny_rate_spike.name
}

output "policy_change_alert_id" {
  value = google_monitoring_alert_policy.policy_changed.name
}
