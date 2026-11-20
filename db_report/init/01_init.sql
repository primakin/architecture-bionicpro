CREATE DATABASE IF NOT EXISTS report_db;

CREATE TABLE IF NOT EXISTS report_db.user_events
(
    `telemetry_id` UInt64,
    `user_id`      UInt64,
    `username`     String,
    `email`        String,
    `full_name`    String,
    `phone`        String,
    `device_id`    UInt64,
    `event_time`   DateTime64(6, 'UTC'),
    `payload`      JSON
)

ENGINE = ReplacingMergeTree()
ORDER BY (telemetry_id);