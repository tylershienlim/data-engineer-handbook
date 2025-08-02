-- A cumulative query to generate `device_activity_datelist` from `events`

-- reference user_cumulated_population.sql for the logic

WITH yesterday AS (
	SELECT * FROM user_devices_cumulated
	WHERE date = DATE('2023-01-1')
),
today AS (
	SELECT
		e.device_id,
		d.browser_type,
		DATE(e.event_time) AS date,
		COUNT(1)
	FROM
		events e
	LEFT JOIN 
		devices d
	ON e.device_id = d.device_id
	WHERE DATE(e.event_time) = DATE('2023-01-02')
	AND e.device_id IS NOT NULL
	GROUP BY e.device_id, d.browser_type, DATE(e.event_time)
)
INSERT INTO user_devices_cumulated
SELECT
	COALESCE(y.device_id, t.device_id),
	COALESCE(y.browser_type, t.browser_type),
	COALESCE(y.device_activity_date_list,ARRAY[]::DATE[])
	|| CASE
			WHEN t.device_id IS NOT NULL
			THEN ARRAY[t.date]
			ELSE ARRAY[]::DATE[]
		END AS device_activity_date_list,
	COALESCE(y.date + Interval '1 day', t.date) AS date
FROM
	yesterday y
FULL OUTER JOIN
	today t
ON t.device_id = y.device_id;