from pyspark.sql import SparkSession
 

original_query = """
SELECT player_name,
        (seasons[cardinality(seasons)]::season_stats).pts/
         CASE WHEN (seasons[1]::season_stats).pts = 0 THEN 1
             ELSE  (seasons[1]::season_stats).pts END
            AS ratio_most_recent_to_first
 FROM players
 WHERE current_season = 1998;
"""


query = """
SELECT player_name,
       element_at(seasons, size(seasons)) / 
       CASE WHEN element_at(seasons, 1) = 0 THEN 1
            ELSE element_at(seasons, 1) END AS ratio_most_recent_to_first
FROM players
WHERE current_season = 1998
"""


def do_analytical_transformation(spark, dataframe):
    dataframe.createOrReplaceTempView("players")
    return spark.sql(query)



def main():
    spark = SparkSession.builder \
      .master("local") \
      .appName("analytical_query") \
      .getOrCreate()
    output_df = do_analytical_transformation(spark, spark.table("players"))
    output_df.write.mode("overwrite").insertInto("analytics")