from chispa.dataframe_comparer import *

from ..jobs.analytical_query_job import do_analytical_transformation
from collections import namedtuple

Players = namedtuple("players",  "player_name seasons current_season")
Analytics = namedtuple("analytics",  "player_name ratio_most_recent_to_first")


def test_analytical_query(spark):
    input_data = [
        Players("Michael Jordan", [1000, 2100, 1980], 1998),
        Players("Scottie Pippen", [900, 1100, 1404], 1998)
    ]

    source_df = spark.createDataFrame(input_data)
    actual_df = do_analytical_transformation(spark, source_df)

    expected_values = [
        Analytics("Michael Jordan", 1.98),
        Analytics("Scottie Pippen", 1.56), 
    ]
    
    expected_df = spark.createDataFrame(expected_values)
    assert_df_equality(actual_df, expected_df)

