-- BUSINESS TASK:
-- Break down revenue, account verification, and session activity by
-- continent — including a device-level revenue split (mobile vs desktop)
-- and each continent's share of total revenue — to help identify which
-- regions drive the most value and how engaged their user base is.

WITH continent_revenue AS ( -- revenue by continent, split by device, plus % of total revenue
  SELECT
    sp.continent,
    SUM(p.price) AS revenue,
    SUM(CASE WHEN sp.device = 'mobile'  THEN p.price END) AS revenue_from_mobile,
    SUM(CASE WHEN sp.device = 'desktop' THEN p.price END) AS revenue_from_desktop,
    SUM(p.price) / SUM(SUM(p.price)) OVER () * 100 AS revenue_from_total_percent
  FROM `data-analytics-mate.DA.order` o
  JOIN `data-analytics-mate.DA.product` p
    ON o.item_id = p.item_id
  JOIN `data-analytics-mate.DA.session_params` sp
    ON o.ga_session_id = sp.ga_session_id
  GROUP BY sp.continent
),

account_ver AS ( -- account and verified account counts by continent
  SELECT
    sp.continent,
    COUNT(DISTINCT ac.id) AS account_cnt,
    COUNT(DISTINCT CASE WHEN ac.is_verified = 1 THEN ac.id END) AS verified_account_cnt
  FROM `data-analytics-mate.DA.account` ac
  JOIN `data-analytics-mate.DA.account_session` acs
    ON ac.id = acs.account_id
  JOIN `data-analytics-mate.DA.session_params` sp
    ON acs.ga_session_id = sp.ga_session_id
  GROUP BY sp.continent
),

session_continent AS ( -- total session count by continent (base for the final join)
  SELECT
    sp.continent,
    COUNT(*) AS session_cnt
  FROM `data-analytics-mate.DA.session_params` sp
  GROUP BY sp.continent
)

SELECT
  session_continent.continent,
  continent_revenue.revenue,
  continent_revenue.revenue_from_mobile,
  continent_revenue.revenue_from_desktop,
  continent_revenue.revenue_from_total_percent,
  account_ver.account_cnt,
  account_ver.verified_account_cnt,
  session_continent.session_cnt
FROM session_continent
LEFT JOIN continent_revenue
  ON session_continent.continent = continent_revenue.continent
LEFT JOIN account_ver
  ON session_continent.continent = account_ver.continent
ORDER BY revenue DESC;
