# Monitoring/alerting (terraform/modules/monitoring) and BigQuery log
# export (terraform/modules/log-export) -- wired into the live lab
# environment too, not just documented as a staging-only template.
#
# Set notification_email in your terraform.tfvars (gitignored) before
# applying, or this will fail with a missing-required-variable error --
# deliberately no default, since an alert nobody receives is worse than
# no alert (false confidence).

module "monitoring" {
  source             = "../../modules/monitoring"
  project_id         = var.project_id
  notification_email = var.notification_email
}

module "log_export" {
  source     = "../../modules/log-export"
  project_id = var.project_id
}
