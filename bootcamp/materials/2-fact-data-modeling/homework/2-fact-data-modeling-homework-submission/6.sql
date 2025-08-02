-- The incremental query to generate `host_activity_datelist`

WITH yesterday AS (
	SELECT * FROM hosts_cumulated
	WHERE date = '2023-01-05'
),
today AS (
	SELECT
		host,
		COUNT(1),
		DATE(event_time) AS date
	FROM
		events
	WHERE
		DATE(event_time) = '2023-01-06'
	GROUP BY 1, 3
)
INSERT INTO hosts_cumulated
SELECT
	COALESCE(y.host, t.host),
	COALESCE(y.host_activity_datelist, ARRAY[]::DATE[])
	|| CASE
			WHEN t.host IS NOT NULL
			THEN
				ARRAY[t.date]
			ELSE
				ARRAY[]::DATE[]
		END AS host_activity_date_list,
	COALESCE(y.date + INTERVAL '1 Day', t.date) AS date
FROM
	yesterday y
FULL OUTER JOIN
	today t
ON	y.host = t.host;