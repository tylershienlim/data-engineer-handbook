-- The homework this week will be using the `players`, `players_scd`, and `player_seasons` tables from week 1

-- - A query that uses window functions on `game_details` to find out the following things:
--   - What is the most games a team has won in a 90 game stretch? 
--   - How many games in a row did LeBron James score over 10 points a game?


WITH team_games AS (
    SELECT 
        g.game_id,
        g.home_team_id AS team_id,
        CASE WHEN g.home_team_wins = 1 THEN 1 ELSE 0 END AS win
    FROM games g
    UNION ALL
    SELECT 
        g.game_id,
        g.visitor_team_id AS team_id,
        CASE WHEN g.home_team_wins = 0 THEN 1 ELSE 0 END AS win
    FROM games g
),
team_names AS (
    SELECT DISTINCT 
        team_id,
        team_abbreviation
    FROM game_details
)
SELECT
    tg.team_id,
    tn.team_abbreviation,
    SUM(tg.win) OVER (
        PARTITION BY tg.team_id 
        ORDER BY tg.game_id
        ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
    ) AS wins_in_last_90_games
FROM team_games tg
LEFT JOIN team_names tn
    ON tg.team_id = tn.team_id
ORDER BY wins_in_last_90_games DESC
LIMIT 1;


WITH lebron AS (
    SELECT 
        gd.game_id,
        gd.player_name,
        gd.pts,
        CASE WHEN gd.pts > 10 THEN 1 ELSE 0 END AS over_10
    FROM game_details gd
    WHERE gd.player_name = 'LeBron James'
),
streaks AS (
    SELECT 
        game_id,
        over_10,
        SUM(CASE WHEN over_10 = 0 THEN 1 ELSE 0 END) 
            OVER (ORDER BY game_id ROWS UNBOUNDED PRECEDING) AS streak_group
    FROM lebron
)
SELECT 
    MAX(streak_length) AS longest_streak_over_10
FROM (
    SELECT streak_group, COUNT(*) AS streak_length
    FROM streaks
    WHERE over_10 = 1
    GROUP BY streak_group
) t;
