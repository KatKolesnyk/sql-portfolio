-- BUSINESS TASK:
-- Calculate the share of "engaged" sessions (session_engaged = '1') out of
-- all sessions with a non-null session_engaged value, broken down by device
-- type — to understand which devices drive more meaningful user engagement.
--
-- Demonstrates working with nested/repeated fields via UNNEST.

WITH engagement_by_device AS ( -- unnest repeated event params and flag engaged sessions
  SELECT
    sp.device,
    COUNT(CASE WHEN params.value.string_value = '1' THEN 1 END) AS engaged_cnt,
    COUNT(params.value.string_value) AS total_cnt
  FROM `data-analytics-mate.DA.event_params` ep,
    UNNEST(ep.event_params) AS params
  JOIN `data-analytics-mate.DA.session_params` sp
    ON ep.ga_session_id = sp.ga_session_id
  WHERE params.key = 'session_engaged'
    AND params.value.string_value IS NOT NULL
  GROUP BY sp.device
)

SELECT
  device,
  FORMAT('%.2f%%', engaged_cnt / total_cnt * 100) AS engaged_session_share
FROM engagement_by_device
ORDER BY device;
