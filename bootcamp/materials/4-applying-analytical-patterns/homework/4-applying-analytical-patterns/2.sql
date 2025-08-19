-- The homework this week will be using the `players`, `players_scd`, and `player_seasons` tables from week 1
-- - A query that uses `GROUPING SETS` to do efficient aggregations of `game_details` data
--   - Aggregate this dataset along the following dimensions
--     - player and team
--       - Answer questions like who scored the most points playing for one team?
--     - player and season
--       - Answer questions like who scored the most points in one season?
--     - team
--       - Answer questions like which team has won the most games?

-- Aggregated player and team statistics using GROUPING SETS
WITH team_points AS (
    -- Calculate total points per game for each team (home + away)
    SELECT
        game_id,
        home_team_id AS team_id,
        pts_home AS points
    FROM games
    UNION ALL
    SELECT
        game_id,
        visitor_team_id AS team_id,
        pts_away AS points
    FROM games
),
game_stats AS (
    SELECT
        gd.player_name,
        gd.team_id,
        gd.team_abbreviation,
        g.season,
        gd.pts AS player_points,
        tp.points AS team_points,
        CASE
            WHEN gd.team_id = g.home_team_id AND g.home_team_wins = 1 THEN 1
            WHEN gd.team_id = g.visitor_team_id AND g.home_team_wins = 0 THEN 1
            ELSE 0
        END AS win
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
    JOIN team_points tp ON tp.game_id = g.game_id AND tp.team_id = gd.team_id
)
SELECT
    -- Handle NULLs from GROUPING SETS
    COALESCE(player_name, '(overall)')       AS player_name,
    COALESCE(team_abbreviation, '(overall)') AS team_abbreviation,
    CASE WHEN GROUPING(season) = 0 THEN season END AS season,

    -- Aggregations
    SUM(player_points) AS total_points_player,
    SUM(team_points) AS total_points_team,
    SUM(win) AS total_wins,

    -- Label to identify the grouping set
    CASE
        WHEN GROUPING(player_name) = 0 AND GROUPING(team_abbreviation) = 0 THEN 'player_team'
        WHEN GROUPING(player_name) = 0 AND GROUPING(season) = 0           THEN 'player_season'
        WHEN GROUPING(team_abbreviation) = 0                                THEN 'team'
    END AS aggregation_level

FROM game_stats
GROUP BY GROUPING SETS (
    (player_name, team_abbreviation),  -- player + team
    (player_name, season),              -- player + season
    (team_abbreviation)                 -- team only
);

