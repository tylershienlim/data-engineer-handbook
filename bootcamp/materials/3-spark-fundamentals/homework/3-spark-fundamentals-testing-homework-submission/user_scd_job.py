from pyspark.sql import SparkSession

original_query = """
WITH yesterday AS (
    SELECT * FROM users_cumulated
    WHERE date = DATE('2023-03-30')
),
    today AS (
          SELECT user_id,
                 DATE_TRUNC('day', event_time) AS today_date,
                 COUNT(1) AS num_events FROM events
            WHERE DATE_TRUNC('day', event_time) = DATE('2023-03-31')
            AND user_id IS NOT NULL
         GROUP BY user_id,  DATE_TRUNC('day', event_time)
    )
SELECT
       COALESCE(t.user_id, y.user_id),
       COALESCE(y.dates_active,
           ARRAY[]::DATE[])
            || CASE WHEN
                t.user_id IS NOT NULL
                THEN ARRAY[t.today_date]
                ELSE ARRAY[]::DATE[]
                END AS date_list,
       COALESCE(t.today_date, y.date + Interval '1 day') as date
FROm yesterday y
    FULL OUTER JOIN
    today t ON t.user_id = y.user_id;
"""

query = """
WITH yesterday AS (
    SELECT *
    FROM users_cumulated
    WHERE date = DATE('2023-03-30')
),
today AS (
    SELECT 
        user_id,
        CAST(DATE_TRUNC('day', event_time) AS DATE) AS today_date,
        COUNT(1) AS num_events
    FROM events
    WHERE CAST(DATE_TRUNC('day', event_time) AS DATE) = DATE('2023-03-31')
      AND user_id IS NOT NULL
    GROUP BY user_id, CAST(DATE_TRUNC('day', event_time) AS DATE)
)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    CASE
        WHEN y.dates_active IS NOT NULL AND t.user_id IS NOT NULL THEN concat(y.dates_active, array(t.today_date))
        WHEN y.dates_active IS NOT NULL THEN y.dates_active
        WHEN t.user_id IS NOT NULL THEN array(t.today_date)
        ELSE array()
    END AS date_list,
    COALESCE(t.today_date, DATE_ADD(y.date, 1)) AS date
FROM yesterday y
FULL OUTER JOIN today t
    ON t.user_id = y.user_id

"""


def do_user_scd_transformation(spark, ytd_dataframe, today_dataframe):
    ytd_dataframe.createOrReplaceTempView("users_cumulated")
    today_dataframe.createOrReplaceTempView("events")
    return spark.sql(query)



def main():
    spark = SparkSession.builder \
      .master("local") \
      .appName("users_scd") \
      .getOrCreate()
    output_df = do_user_scd_transformation(spark, spark.table("users_ytd"), spark.table("users_today"))
    output_df.write.mode("overwrite").insertInto("users_scd")