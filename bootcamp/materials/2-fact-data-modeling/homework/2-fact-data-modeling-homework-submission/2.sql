-- - A DDL for an `user_devices_cumulated` table that has:
--   - a `device_activity_datelist` which tracks a users active days by `browser_type`
--   - data type here should look similar to `MAP<STRING, ARRAY[DATE]>`
--     - or you could have `browser_type` as a column with multiple rows for each user (either way works, just be consistent!)

-- reference users_cumulated.sql for the 


CREATE TABLE user_devices_cumulated (
	device_id NUMERIC,
	browser_type TEXT,
	device_activity_date_list DATE[],
	date DATE,
	PRIMARY KEY (device_id, browser_type, date)
);