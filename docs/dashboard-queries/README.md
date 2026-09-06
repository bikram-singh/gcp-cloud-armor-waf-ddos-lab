# Example BigQuery queries for the exported Cloud Armor logs

These query the `cloud_armor_logs` dataset created by
`terraform/modules/log-export`. Log Router writes date-sharded tables
named `requests_YYYYMMDD` (the table name comes from the log ID --
`http_load_balancer` logs go to `logs/requests`). Each query below uses
a wildcard (`requests_*`) with `_TABLE_SUFFIX` filtering so it works
across however many days of export you have, without listing table
names by hand.

To build a Looker Studio dashboard: create a new report, add a
BigQuery data source pointed at this dataset, and use these queries
(or their underlying tables) as the source for individual charts. Each
.sql file here is one candidate chart.

Run any of these directly first via `bq query --use_legacy_sql=false < file.sql`
to sanity-check the output before wiring it into a dashboard.
