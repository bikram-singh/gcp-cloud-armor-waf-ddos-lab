-- SQLi rule matches per day, last 30 days
-- Filters on the OWASP CRS SQLi rule ID prefix seen across this
-- project's own confirmed catches (942xxx family, e.g. 942100, 942180,
-- 942190, 942200 -- each a distinct payload shape).
SELECT
  PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS log_date,
  COUNT(*) AS sqli_denies,
  ARRAY_AGG(DISTINCT rule_id IGNORE NULLS) AS rule_ids_seen
FROM
  `cloud_armor_logs.requests_*`,
  UNNEST(jsonPayload.enforcedSecurityPolicy.preconfiguredExprIds) AS rule_id
WHERE
  _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND jsonPayload.enforcedSecurityPolicy.outcome = 'DENY'
  AND rule_id LIKE '%sqli%'
GROUP BY
  log_date
ORDER BY
  log_date;
