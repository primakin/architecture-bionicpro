CREATE TABLE user_telemetry (
    telemetry_id    BIGSERIAL       PRIMARY KEY,
    user_id         BIGSERIAL       NOT NULL,
    device_id       BIGSERIAL       NOT NULL,
    event_time      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    payload         JSONB           NOT NULL DEFAULT '{}'::jsonb
);



INSERT INTO user_telemetry
    (user_id, device_id, event_time, payload)
VALUES
    (1, 111, NOW() - INTERVAL '10 days',                         '{"comment": "some old telemetry, 1"}'),
    (2, 222, NOW() - INTERVAL '10 days',                         '{"comment": "some old telemetry, 2"}'),
    (3, 333, NOW() - INTERVAL '10 days',                         '{"comment": "some old telemetry, 3"}'),
    (1, 111, NOW() - INTERVAL '10 hours',                        '{"x": "11", "y": "11", "battery_level": "90"}'),
    (1, 111, NOW() - INTERVAL '10 hours' + INTERVAL '2 seconds', '{"x": "12", "y": "22", "battery_level": "90"}'),
    (1, 111, NOW() - INTERVAL '10 hours' + INTERVAL '4 seconds', '{"x": "13", "y": "33", "battery_level": "89"}'),
    (2, 222, NOW() - INTERVAL '7 hours',                         '{"x": "33", "y": "33", "battery_level": "92"}'),
    (2, 222, NOW() - INTERVAL '7 hours' + INTERVAL '2 seconds',  '{"x": "34", "y": "44", "battery_level": "92"}'),
    (2, 222, NOW() - INTERVAL '7 hours' + INTERVAL '3 seconds',  '{"x": "35", "y": "55", "battery_level": "91"}'),
    (2, 222, NOW() - INTERVAL '7 hours' + INTERVAL '4 seconds',  '{"x": "36", "y": "66", "battery_level": "91"}'),    
    (3, 333, NOW() - INTERVAL '3 hours',                         '{"x": "55", "y": "55", "battery_level": "88"}'),
    (3, 333, NOW() - INTERVAL '3 hours' + INTERVAL '6 seconds',  '{"x": "66", "y": "66", "battery_level": "88"}'),
    (3, 333, NOW() - INTERVAL '3 hours' + INTERVAL '7 seconds',  '{"x": "77", "y": "77", "battery_level": "88"}'),
    (3, 444, NOW() - INTERVAL '20 hours',                        '{"x": "88", "y": "88", "battery_level": "91"}'),
    (3, 555, NOW() - INTERVAL '10 hours',                        '{"x": "99", "y": "99", "battery_level": "92"}');