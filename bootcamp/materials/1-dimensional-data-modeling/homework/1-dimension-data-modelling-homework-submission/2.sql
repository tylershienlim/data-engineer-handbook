-- 2. **Cumulative table generation query:** Write a query that populates the `actors` table one year at a time.

WITH last_year AS (
	SELECT * FROM actors WHERE current_year = 1969
),
this_year_raw AS (
	SELECT * FROM actor_films WHERE year = 1970
),
this_year AS (
	SELECT
		actor,
		actorid,
		ARRAY_AGG(
			ROW(film, votes, rating, filmid)::films
		) AS new_films,
		AVG(rating) AS avg_rating,
		MAX(year) AS year
	FROM this_year_raw
	GROUP BY actor, actorid
)
INSERT INTO actors
SELECT
	COALESCE(ly.actor, ty.actor) AS actor,
	COALESCE(ly.actorid, ty.actorid) AS actorid,
	COALESCE(ly.films, ARRAY[]::films[]) || COALESCE(ty.new_films, ARRAY[]::films[]) AS films,
	CASE
		WHEN ty.avg_rating IS NOT NULL THEN (
			CASE
				WHEN ty.avg_rating > 8 THEN 'star'
				WHEN ty.avg_rating > 7 THEN 'good'
				WHEN ty.avg_rating > 6 THEN 'average'
				ELSE 'bad'
			END
		)::quality_class
		ELSE ly.quality_class
	END AS quality_class,
	ty.year IS NOT NULL AS is_active,
	1970 AS current_year
FROM
	last_year ly
FULL OUTER JOIN
	this_year ty
ON ly.actor = ty.actor;