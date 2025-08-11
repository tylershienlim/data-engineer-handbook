from chispa.dataframe_comparer import *

from ..jobs.user_scd_job import do_user_scd_transformation
from collections import namedtuple
from datetime import date, datetime

UsersCumulated = namedtuple("users_cumulated",  "user_id dates_active date")
Events = namedtuple("events",  "user_id event_time")
UsersScd = namedtuple("user_scd",  "user_id date_list date")


def test_user_scd(spark):
    user_cumulated_input_data = [
        UsersCumulated(1, [date(2023, 3, 28), date(2023, 3, 29), date(2023, 3, 30)], date(2023, 3, 30)),
        UsersCumulated(2, [date(2023, 3, 30)], date(2023, 3, 30))
    ]
    
    event_input_data = [
        Events(1, datetime(2023, 3, 31, 9, 0, 0)),
        # Events(1, date(2023, 3, 31)),
        Events(2, datetime(2023, 3, 31, 15, 0, 0))
        # Events(2, date(2023, 3, 31))
    ]

    source_df_ytd = spark.createDataFrame(user_cumulated_input_data)
    source_df_today = spark.createDataFrame(event_input_data)
    actual_df = do_user_scd_transformation(spark, source_df_ytd, source_df_today)

    expected_values = [
        UsersScd(1, [date(2023, 3, 28), date(2023, 3, 29), date(2023, 3, 30), date(2023, 3, 31)], date(2023, 3, 31)),
        UsersScd(2, [date(2023, 3, 30), date(2023, 3, 31)], date(2023, 3, 31))
    ]
    
    expected_df = spark.createDataFrame(expected_values)
    assert_df_equality(actual_df, expected_df)

