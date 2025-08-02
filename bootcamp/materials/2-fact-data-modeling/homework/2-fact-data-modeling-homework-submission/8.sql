-- - An incremental query that loads `host_activity_reduced`
--   - day-by-day


WITH yesterday AS (
	SELECT * FROM host_activity_reduced
	WHERE date = '2023-01-02'
),
today AS (
	SELECT
		host,
		COUNT(1) AS hit_count,
		COUNT(DISTINCT user_id) AS unique_visitors,
		DATE(event_time) AS today
	FROM
		events
	WHERE DATE(event_time) = '2023-01-03'
	AND user_id IS NOT NULL AND device_id IS NOT NULL
	GROUP BY 1, 4
)
INSERT INTO host_activity_reduced
SELECT
	COALESCE(y.host, t.host) AS host,
	DATE('2023-01-01') AS month,
	COALESCE(y.hit_array, ARRAY[]::BIGINT[])
	|| CASE
		WHEN t.host IS NOT NULL
		THEN ARRAY[t.hit_count]::BIGINT[]
		ELSE ARRAY[]::BIGINT[]
	END AS hit_array,
	COALESCE(y.unique_visitors_array, ARRAY[]::INT[])
	|| CASE
		WHEN t.host IS NOT NULL
		THEN ARRAY[t.unique_visitors]::INT[]
		ELSE ARRAY[]::INT[]
	END AS unique_visitors_array,
	t.today AS date
FROM
	yesterday y
FULL OUTER JOIN
	today t
ON
	y.host = t.host;