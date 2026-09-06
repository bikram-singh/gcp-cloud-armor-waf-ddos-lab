-- Which rule (by priority) is doing the most blocking, last 7 days.
-- Useful for spotting a rule that's either working hard (legitimately
-- catching a lot of attack traffic) or misfiring (catching legitimate
-- traffic -- cross-reference against docs/architecture.md's known
-- false-positive findings if a rule here has surprisingly high volume).
SELECT
  jsonPayload.enforcedSecurityPolicy.priority AS rule_priority,
  jsonPayload.enforcedSecurityPolicy.configuredAction AS action,
  COUNT(*) AS match_count
FROM
  `cloud_armor_logs.requests_*`
WHERE
  _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
                    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND jsonPayload.enforcedSecurityPolicy.outcome IN ('DENY', 'ACCEPT')
GROUP BY
  rule_priority, action
ORDER BY
  match_count DESC;
