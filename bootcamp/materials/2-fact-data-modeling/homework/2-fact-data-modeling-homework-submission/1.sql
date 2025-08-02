-- A query to deduplicate `game_details` from Day 1 so there's no duplicates

with dedup as (
	select
		*,
		row_number() over (partition by game_id, team_id, player_id order by game_id) as rn
	from
		game_details
)
select
	game_id,
	team_id,
	player_id,
	player_name,
	start_position,
	comment,
	min,
	fgm,
	fga,
	fg3m,
	fg3a,
	ftm,
	fta,
	oreb,
	dreb,
	reb,
	ast,
	stl,
	blk,
	"TO",
	pf,
	pts,
	plus_minus
from dedup
where rn = 1;