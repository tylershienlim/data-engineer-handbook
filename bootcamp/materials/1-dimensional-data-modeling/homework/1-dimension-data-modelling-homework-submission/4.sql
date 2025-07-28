-- 4. **Backfill query for `actors_history_scd`:** Write a "backfill" query that can populate the entire `actors_history_scd` table in a single query.

WITH streak_started AS (
	SELECT
		actor,
		current_year,
		quality_class,
		LAG(quality_class, 1) OVER (PARTITION BY actor ORDER BY current_year) <> quality_class
		OR
		LAG(quality_class, 1) OVER (PARTITION BY actor ORDER BY current_year) IS NULL
		AS quality_did_changed,
		is_active,
		LAG(is_active, 1) OVER (PARTITION BY actor ORDER BY current_year) <> is_active
		OR
		LAG(is_active, 1) OVER (PARTITION BY actor ORDER BY current_year) IS NULL
		AS is_active_did_changed		
	FROM
		actors
),
streak_identified AS (
	SELECT
		actor,
		quality_class,
		SUM(CASE WHEN quality_did_changed THEN 1 ELSE 0 END) OVER (PARTITION BY actor ORDER BY current_year) as quality_streak_identifier,
		is_active,
		SUM(CASE WHEN is_active_did_changed THEN 1 ELSE 0 END) OVER (PARTITION BY actor ORDER BY current_year) as is_active_streak_identifier,
		current_year
	FROM
		streak_started
),
agg AS (
	SELECT
		actor,
		quality_class,
		quality_streak_identifier,
		is_active,
		is_active_streak_identifier,
		current_year,
		MIN(current_year) AS start_date,
		MAX(current_year) AS end_date
	FROM
		streak_identified
	GROUP BY 1,2,3,4,5,6
)
INSERT INTO actors_history_scd
SELECT
	actor,
	quality_class,
	is_active,
	start_date,
	end_date,
	current_year
FROM agg;