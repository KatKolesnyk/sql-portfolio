-- BUSINESS TASK:
-- Track daily cumulative revenue against cumulative revenue targets
-- (predict) to monitor what percentage of the forecast has been fulfilled
-- over time. The revenue calculation is stored as a reusable view;
-- the predict data is combined with it via UNION ALL in the main query.

-- STEP 1: create a view that stores the daily revenue calculation
CREATE VIEW `data-analytics-mate.Students.v_kolesnyk_view_task` AS
SELECT
  date,
  NULL AS predict,
  SUM(p.price) AS revenue
FROM `data-analytics-mate.DA.product` p
JOIN `data-analytics-mate.DA.order` o
  ON p.item_id = o.item_id
JOIN `data-analytics-mate.DA.session` s
  ON o.ga_session_id = s.ga_session_id
GROUP BY 1;

-- STEP 2: combine the view with the revenue_predict table and calculate
-- cumulative fulfillment percentage using window functions
WITH combined AS (
  SELECT date, predict, revenue
  FROM `data-analytics-mate.Students.v_kolesnyk_view_task`

  UNION ALL

  SELECT
    date,
    predict,
    NULL AS revenue
  FROM `data-analytics-mate.DA.revenue_predict`
)

SELECT DISTINCT
  date,
  SUM(revenue) OVER (ORDER BY date) AS running_revenue,
  SUM(predict) OVER (ORDER BY date) AS running_predict,
  ROUND(
    SUM(revenue) OVER (ORDER BY date) / SUM(predict) OVER (ORDER BY date) * 100,
    2
  ) AS fulfillment_percent
FROM combined
ORDER BY date;
