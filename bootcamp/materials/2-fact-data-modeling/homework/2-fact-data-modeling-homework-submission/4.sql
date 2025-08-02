-- A `datelist_int` generation query. Convert the `device_activity_datelist` column into a `datelist_int` column 

-- reference analyze_datelist.sql for the logic

WITH first AS (
	SELECT
		u.device_activity_date_list @> ARRAY [g.selected_dates::DATE] AS is_active,
	   (DATE('2023-01-11') - g.selected_dates::DATE) AS days_since,
		u.device_id,
		u.browser_type
	FROM
		user_devices_cumulated u
	CROSS JOIN 
		(SELECT DATE(GENERATE_SERIES('2023-01-01', '2023-01-11', INTERVAL '1 day')) AS selected_dates ) AS g
	WHERE date = DATE('2023-01-10')
),
converted AS (
	SELECT
		device_id,
		browser_type,
		SUM(CASE
                -- 32 bit chosen for days of month
				WHEN is_active THEN POW(2, 32 - days_since) -- Each day that is active or inactive is represented as a bit in the integer
				ELSE 0 
            END)::bigint::bit(32) AS datelist_int
	FROM
		first
	GROUP BY 1, 2
)
SELECT * FROM converted;