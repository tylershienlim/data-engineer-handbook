-- The homework this week will be using the `players`, `players_scd`, and `player_seasons` tables from week 1

-- - A query that does state change tracking for `players`
--   - A player entering the league should be `New`
--   - A player leaving the league should be `Retired`
--   - A player staying in the league should be `Continued Playing`
--   - A player that comes out of retirement should be `Returned from Retirement`
--   - A player that stays out of the league should be `Stayed Retired`

-- New -> last season empty
-- Retired -> last season not empty, this season empty
-- Continued Playing -> last season not empty, this season not empty
-- Returned from Retirement -> last season empty, this season not empty
-- Stayed Retired -> last season empty, this season empty

WITH last_season AS (
    SELECT * FROM players_scd
    WHERE current_season = 2021
    AND end_season = 2021
),
this_season AS (
    SELECT * FROM players
    WHERE current_season = 2022
)
SELECT
    COALESCE(ts.player_name, ls.player_name) AS player_name,
    COALESCE(ts.scoring_class, ls.scoring_class) AS scoring_class,
    COALESCE(ts.is_active, ls.is_active) AS is_active,
    COALESCE(ts.start_season, ls.start_season) AS start_season,
    COALESCE(ts.end_date, ls.end_date) AS end_date,
    COALESCE(ts.current_season, ls.current_season) AS current_season,
    CASE
        WHEN ls.player_name IS NULL THEN 'New'
        WHEN ls.current_season IS NOT NULL AND ts.current_season IS NULL THEN 'Retired'
        WHEN ls.current_season IS NOT NULL AND ts.current_season IS NOT NULL THEN 'Continued Playing'
        WHEN ls.current_season IS NULL AND ts.current_season IS NOT NULL THEN 'Returned from Retirement'
        ELSE 'Stayed Retired'
    END AS status
FROM
    this_season ts
FULL OUTER JOIN 
    last_season ls
ON ts.player_name = ls.player_name