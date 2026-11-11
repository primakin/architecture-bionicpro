CREATE TABLE user_telemetry (
    telemetry_id    BIGSERIAL       PRIMARY KEY,
    user_id         BIGSERIAL       NOT NULL,
    device_id       BIGSERIAL       NOT NULL,
    event_time      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    payload         JSONB           NOT NULL DEFAULT '{}'::jsonb  -- произвольные доп. данные
);



INSERT INTO user_telemetry
    (user_id, device_id, event_time, payload)
VALUES
    (1, 111, NOW() - INTERVAL '10 days',                        '{"x": "11", "y": "11", "battery_level": "90", "success": true}'),
    (1, 111, NOW() - INTERVAL '10 days' + INTERVAL '5 minutes', '{"x": "22", "y": "22", "battery_level": "90", "success": true}'),
    (2, 222, NOW() - INTERVAL '7 days',                         '{"x": "33", "y": "33", "battery_level": "89", "success": true}'),
    (2, 222, NOW() - INTERVAL '7 days' + INTERVAL '2 minutes',  '{"x": "44", "y": "44", "battery_level": "89", "success": true}'),
    (3, 333, NOW() - INTERVAL '3 days',                         '{"x": "55", "y": "55", "battery_level": "88", "success": true}'),
    (3, 333, NOW() - INTERVAL '3 days' + INTERVAL '1 minute',   '{"x": "66", "y": "66", "battery_level": "88", "success": true}'),
    (3, 333, NOW() - INTERVAL '3 days' + INTERVAL '30 minutes', '{"x": "77", "y": "77", "battery_level": "88", "success": true}'),
    (4, 444, NOW() - INTERVAL '40 days',                        '{"x": "88", "y": "88", "battery_level": "91", "success": true}'),
    (5, 555, NOW() - INTERVAL '12 days',                        '{"x": "99", "y": "99", "battery_level": "92", "success": true}');