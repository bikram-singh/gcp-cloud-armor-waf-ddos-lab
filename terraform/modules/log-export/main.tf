variable "project_id" {
  type = string
}

variable "location" {
  description = "BigQuery dataset location. Match your GCP region for lowest latency/cost, though logs export fine across regions."
  type        = string
  default     = "US"
}

variable "log_retention_ms" {
  description = "How long BigQuery keeps exported log rows before auto-deleting, in milliseconds. Cost control -- unlimited retention on a table that receives every LB request adds up. Default here is 30 days (2592000000 ms) -- generous for this lab's low traffic volume; size a real production app's retention against actual query needs and cost. Expressed directly in milliseconds (not computed from a days value) to avoid a confirmed real Terraform/provider bug where runtime arithmetic on this specific field produces a value the API rejects as non-whole-number."
  type        = number
  default     = 1728000000 # 20 days -- confirmed this provider version (6.50.0) rejects values above roughly 2^31 (int32 max, ~24.8 days worth of ms) for this specific field, even though BigQuery's real API supports int64. 30 days (2592000000) reliably failed with "must be a whole number" regardless of how the value was computed or literal-vs-expression -- a genuine provider-schema limitation, not a formatting issue.
}

resource "google_bigquery_dataset" "cloud_armor_logs" {
  project                     = var.project_id
  dataset_id                  = "cloud_armor_logs"
  location                    = var.location
  default_table_expiration_ms = var.log_retention_ms
  description                 = "Load balancer + Cloud Armor request logs, exported for analysis beyond ad-hoc gcloud logging read queries. See docs/dashboard-queries/ for example queries (top blocked IPs, SQLi attempts over time, etc.) and docs/architecture.md for how to point Looker Studio at this dataset."
}

resource "google_logging_project_sink" "cloud_armor_to_bigquery" {
  project     = var.project_id
  name        = "cloud-armor-logs-to-bigquery"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.cloud_armor_logs.dataset_id}"
  filter      = "resource.type=\"http_load_balancer\""

  # Log Router writes as its own service identity, not the caller --
  # this must be granted BigQuery Data Editor on the dataset below, or
  # the sink silently drops everything with no error at export time.
  unique_writer_identity = true
}

resource "google_bigquery_dataset_iam_member" "sink_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.cloud_armor_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.cloud_armor_to_bigquery.writer_identity
}

output "dataset_id" {
  value = google_bigquery_dataset.cloud_armor_logs.dataset_id
}

output "sink_writer_identity" {
  value = google_logging_project_sink.cloud_armor_to_bigquery.writer_identity
}

