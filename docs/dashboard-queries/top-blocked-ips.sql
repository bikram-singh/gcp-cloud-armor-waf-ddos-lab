-- Top blocked IPs in the last 7 days
-- NOTE: Log Router's BigQuery export materializes jsonPayload/httpRequest
-- as nested RECORD/STRUCT columns (not raw JSON strings) when the log
-- entries have a consistent schema, which LoadBalancerLogEntry does --
-- so nested fields are accessed directly (dot notation), no JSON_EXTRACT
-- needed. Verify actual column names via `bq show --schema` once your
-- own sink has written its first table, since exact nesting can vary
-- slightly by log entry type.
SELECT
  httpRequest.remoteIp AS remote_ip,
  COUNT(*) AS deny_count,
  ANY_VALUE(jsonPayload.securityPolicyRequestData.remoteIpInfo.regionCode) AS region,
  ANY_VALUE(jsonPayload.enforcedSecurityPolicy.name) AS policy_name
FROM
  `cloud_armor_logs.requests_*`
WHERE
  _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
                    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND jsonPayload.enforcedSecurityPolicy.outcome = 'DENY'
GROUP BY
  remote_ip
ORDER BY
  deny_count DESC
LIMIT 25;
