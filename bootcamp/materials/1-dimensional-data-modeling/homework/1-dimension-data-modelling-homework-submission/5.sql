-- 5. **Incremental query for `actors_history_scd`:** Write an "incremental" query that combines the previous year's SCD data with new incoming data from the `actors` table.

WITH last_year_scd AS (
	SELECT * FROM actors_history_scd
	WHERE current_year = 1970
	AND end_date = 1970
),
historical_scd AS (
	SELECT * FROM actors_history_scd
	WHERE current_year = 1970
	AND end_date < 1970
),
this_year AS (
	SELECT * FROM actors
	WHERE current_year = 1971
),
unchanged AS (
	SELECT
		ty.actor,
		ty.quality_class,
		ty.is_active,
		ly.start_date,
		ty.current_year AS end_date,
		ty.current_year
	FROM
		this_year ty
	JOIN
		last_year_scd ly
	ON	ly.actor = ty.actor
	WHERE ty.quality_class = ly.quality_class AND ty.is_active = ly.is_active
),
changed AS (
	SELECT
		ty.actor,
		UNNEST(ARRAY[
			ROW(
				ly.quality_class,
				ly.is_active,
				ly.start_date,
				ly.end_date
			)::scd_type,
			ROW(
				ty.quality_class,
				ty.is_active,
				ty.current_year,
				ty.current_year
			)::scd_type
		]) AS records,
		ty.current_year
	FROM
		this_year ty
	LEFT JOIN
		last_year_scd ly
	ON ly.actor = ty.actor
	WHERE (ly.quality_class <> ty.quality_class)
	OR
	(ly.is_active <> ty.is_active)
),
unnested_changed AS (
	SELECT
		actor,
		(records::scd_type).quality_class,
		(records::scd_type).is_active,
		(records::scd_type).start_date,
		(records::scd_type).end_date,
		current_year
	FROM
		changed
),
new_records AS (
	SELECT
		ty.actor,
		ty.quality_class,
		ty.is_active,
		ty.current_year,
		ty.current_year,
		ty.current_year
	FROM
		this_year ty
	LEFT JOIN
		last_year_scd ly
	ON
		ly.actor = ty.actor
	WHERE ly.actor IS NULL
)
SELECT *, 1971 AS current_year FROM (
	SELECT * FROM historical_scd

	UNION ALL

	SELECT * FROM unchanged

	UNION ALL

	SELECT * FROM unnested_changed

	UNION ALL

	SELECT * FROM new_records
)a ;