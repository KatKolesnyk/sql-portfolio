-- BUSINESS TASK:
-- Identify the top 10 countries by two key growth metrics — new account
-- registrations and total emails sent — to help the marketing team
-- prioritize regional campaigns and email infrastructure investment.
--
-- A country qualifies for the final result if it ranks in the TOP 10 by
-- EITHER metric, since strong account growth and strong sending volume can
-- point to different (and equally valuable) business opportunities.

WITH email_metrics AS ( -- email-related metrics per account segment
  SELECT
    DATE_ADD(s.date, INTERVAL es.sent_date DAY) AS date,
    sp.country,
    a.send_interval,
    a.is_verified,
    a.is_unsubscribed,
    COUNT(DISTINCT es.id_message) AS sent_msg,
    COUNT(DISTINCT eo.id_message) AS open_msg,
    COUNT(DISTINCT ev.id_message) AS visit_msg,
    0 AS account_cnt
  FROM `data-analytics-mate.DA.email_sent` es
  LEFT JOIN `data-analytics-mate.DA.email_open`  eo  ON es.id_message = eo.id_message
  LEFT JOIN `data-analytics-mate.DA.email_visit` ev  ON es.id_message = ev.id_message
  JOIN `data-analytics-mate.DA.account`          a   ON es.id_account = a.id
  JOIN `data-analytics-mate.DA.account_session`  acs ON es.id_account = acs.account_id
  JOIN `data-analytics-mate.DA.session`          s   ON acs.ga_session_id = s.ga_session_id
  JOIN `data-analytics-mate.DA.session_params`   sp  ON s.ga_session_id = sp.ga_session_id
  GROUP BY 1, 2, 3, 4, 5
),

account_metrics AS ( -- new account registration counts per segment
  SELECT
    s.date,
    sp.country,
    a.send_interval,
    a.is_verified,
    a.is_unsubscribed,
    0 AS sent_msg,
    0 AS open_msg,
    0 AS visit_msg,
    COUNT(DISTINCT a.id) AS account_cnt
  FROM `data-analytics-mate.DA.account` a
  LEFT JOIN `data-analytics-mate.DA.account_session` acs ON a.id = acs.account_id
  JOIN `data-analytics-mate.DA.session`              s   ON acs.ga_session_id = s.ga_session_id
  JOIN `data-analytics-mate.DA.session_params`       sp  ON s.ga_session_id = sp.ga_session_id
  GROUP BY 1, 2, 3, 4, 5
),

combined AS ( -- merge email activity and account creation into one grain
  SELECT
    date,
    country,
    send_interval,
    is_verified,
    is_unsubscribed,
    SUM(account_cnt) AS account_cnt,
    SUM(sent_msg)    AS sent_msg,
    SUM(open_msg)    AS open_msg,
    SUM(visit_msg)   AS visit_msg
  FROM (
    SELECT * FROM email_metrics
    UNION ALL
    SELECT * FROM account_metrics
  )
  GROUP BY 1, 2, 3, 4, 5
),

ranked AS ( -- calculate country-level totals for accounts and sent emails
  SELECT
    *,
    SUM(account_cnt) OVER (PARTITION BY country) AS total_country_account_cnt,
    SUM(sent_msg)    OVER (PARTITION BY country) AS total_country_sent_cnt
  FROM combined
),

ranked_final AS ( -- rank countries by each total using window functions
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt,
    DENSE_RANK() OVER (ORDER BY total_country_sent_cnt    DESC) AS rank_total_country_sent_cnt
  FROM ranked
)

SELECT * -- keep only countries that rank in the top 10 by either metric
FROM ranked_final
WHERE
  rank_total_country_account_cnt <= 10
  OR rank_total_country_sent_cnt <= 10;
