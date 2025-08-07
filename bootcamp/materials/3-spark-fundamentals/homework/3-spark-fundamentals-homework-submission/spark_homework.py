from pyspark.sql.functions import broadcast, split, lit
from pyspark.sql import functions as F
from pyspark.sql import SparkSession

# Initialize Spark Session
spark = SparkSession.builder \
    .appName("Spark Homework") \
    .getOrCreate()

# Disabled automatic broadcast join with `spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")`
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")

# Load datasets
match_details = spark.read.option("header", "true").option("delimiter", ",").csv("/home/iceberg/data/match_details.csv")
matches = spark.read.option("header", "true").option("delimiter", ",").csv("/home/iceberg/data/matches.csv")
medals_matches_players = spark.read.option("header", "true").option("delimiter", ",").csv("/home/iceberg/data/medals_matches_players.csv")
medals = spark.read.option("header", "true").option("delimiter", ",").csv("/home/iceberg/data/medals.csv")
maps = spark.read.option("header", "true").option("delimiter", ",").csv("/home/iceberg/data/maps.csv")

# Explicitly broadcast JOINs `medals` and `maps`
broadcast_medals = medals_matches_players.join(broadcast(medals), on="medal_id", how="left")
broadcast_maps = matches.join(broadcast(maps), on="mapid", how="left")

# Bucket join `match_details`, `matches`, and `medal_matches_players` on `match_id` with `16` buckets
match_details_bucketed = match_details.write.bucketBy(16, "match_id") \
    .format("parquet") \
    .mode("overwrite") \
    .saveAsTable("homework.match_details")

matches_bucketed = matches.write.bucketBy(16, "match_id")\
    .format("parquet")\
    .mode("overwrite")\
    .saveAsTable("homework.matches")

medals_matches_players_bucketed = medals_matches_players.write.bucketBy(16, "match_id")\
    .format("parquet")\
    .mode("overwrite")\
    .saveAsTable("homework.medals_matches_players")

match_details_bucketed = spark.table("homework.match_details")
matches_bucketed = spark.table("homework.matches")
medals_matches_players_bucketed = spark.table("homework.medals_matches_players")

joined = spark.sql("""
    SELECT 
        md.match_id,
        md.player_gamertag,
        md.previous_spartan_rank,
        md.spartan_rank,
        md.previous_total_xp,
        md.total_xp,
        md.previous_csr_tier,
        md.previous_csr_designation,
        md.previous_csr,
        md.previous_csr_percent_to_next_tier,
        md.previous_csr_rank,
        md.current_csr_tier,
        md.current_csr_designation,
        md.current_csr,
        md.current_csr_percent_to_next_tier,
        md.current_csr_rank,
        md.player_rank_on_team,
        md.player_finished,
        md.player_average_life,
        md.player_total_kills,
        md.player_total_headshots,
        md.player_total_weapon_damage,
        md.player_total_shots_landed,
        md.player_total_melee_kills,
        md.player_total_melee_damage,
        md.player_total_assassinations,
        md.player_total_ground_pound_kills,
        md.player_total_shoulder_bash_kills,
        md.player_total_grenade_damage,
        md.player_total_power_weapon_damage,
        md.player_total_power_weapon_grabs,
        md.player_total_deaths,
        md.player_total_assists,
        md.player_total_grenade_kills,
        md.did_win,
        md.team_id,
        
        m.is_team_game,
        m.playlist_id,
        m.game_variant_id,
        m.is_match_over,
        m.completion_date,
        m.match_duration,
        m.game_mode,
        m.map_variant_id,
        
        mmp.medal_id,
        mmp.count

        
    FROM match_details md
    JOIN matches m
    ON md.match_id = m.match_id
    JOIN medals_matches_players mmp
    ON m.match_id = mmp.match_id
""")

joined.write.mode("overwrite").saveAsTable("homework.bucket_join") # Write the joined data to a table

#  Aggregate the joined data frame to figure out questions like:
#     - Which player averages the most kills per game?
avg_most_kills = joined.groupBy("player_gamertag")\
                        .agg(F.avg("player_total_kills").alias("avg_kills"))\
                        .orderBy(F.desc("avg_kills"))

avg_most_kills.show(1)

#     - Which playlist gets played the most?
most_played_playlist = joined.groupBy("playlist_id")\
                            .agg(F.count("*").alias("playlist_count"))\
                            .orderBy(F.desc("playlist_count"))

most_played_playlist.show(1)             

#     - Which map gets played the most?
most_played_map = joined.filter(F.col("map_variant_id").isNotNull()) \
                        .groupBy("map_variant_id") \
                        .agg(F.count("*").alias("map_played_count")) \
                        .orderBy(F.desc("map_played_count"))

most_played_map.show(1)       

#     - Which map do players get the most Killing Spree medals on?
killing_spree_id = medals.filter(F.col("name") == "Killing Spree").select("medal_id").first()["medal_id"] # Find the medal_id for "Killing Spree"

highest_medals_map = joined.filter(F.col("medal_id") == killing_spree_id)\
                            .groupBy("map_variant_id")\
                            .agg(F.count("medal_id").alias("medals_map_count"))\
                            .orderBy(F.desc("medals_map_count"))

highest_medals_map.show(1)

# With the aggregated data set
#  Try different `.sortWithinPartitions` to see which has the smallest data size (hint: playlists and maps are both very low cardinality)

sorted_by_playlist = joined.sortWithinPartitions("playlist_id")

sorted_by_map = joined.sortWithinPartitions("map_variant_id")

sorted_by_match = joined.sortWithinPartitions("match_id")

print("Size sorted by playlist_id:", sorted_by_playlist.rdd.map(lambda x: len(str(x))).sum())
print("Size sorted by map_variant_id:", sorted_by_map.rdd.map(lambda x: len(str(x))).sum())
print("Size sorted by match_id:", sorted_by_match.rdd.map(lambda x: len(str(x))).sum())
