-- BUSINESS TASK:
-- For each account, calculate what share of that month's total emails
-- were sent to them, along with their first and last email send date
-- within the month — using window functions only (no GROUP BY), to keep
-- row-level granularity while still exposing month-level aggregates.

SELECT DISTINCT
  DATE_TRUNC(DATE_ADD(s.date, INTERVAL es.sent_date DAY), MONTH) AS sent_month,
  es.id_account,
  ROUND(
    COUNT(es.id_message) OVER (
      PARTITION BY DATE_TRUNC(DATE_ADD(s.date, INTERVAL es.sent_date DAY), MONTH), es.id_account
    )
    / COUNT(es.id_message) OVER (
      PARTITION BY DATE_TRUNC(DATE_ADD(s.date, INTERVAL es.sent_date DAY), MONTH)
    ) * 100,
    5
  ) AS sent_msg_percent_from_this_month,
  MIN(DATE_ADD(s.date, INTERVAL es.sent_date DAY)) OVER (
    PARTITION BY DATE_TRUNC(DATE_ADD(s.date, INTERVAL es.sent_date DAY), MONTH), es.id_account
  ) AS first_sent_date,
  MAX(DATE_ADD(s.date, INTERVAL es.sent_date DAY)) OVER (
    PARTITION BY DATE_TRUNC(DATE_ADD(s.date, INTERVAL es.sent_date DAY), MONTH), es.id_account
  ) AS last_sent_date
FROM `data-analytics-mate.DA.email_sent` es
JOIN `data-analytics-mate.DA.account_session` acs
  ON es.id_account = acs.account_id
JOIN `data-analytics-mate.DA.session` s
  ON acs.ga_session_id = s.ga_session_id
ORDER BY sent_month, id_account;
