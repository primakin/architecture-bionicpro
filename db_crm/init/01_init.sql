CREATE TABLE crm_users (
    user_id         BIGSERIAL       PRIMARY KEY,
    username        VARCHAR(255)    NOT NULL UNIQUE,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    full_name       VARCHAR(255)    NOT NULL,
    phone           VARCHAR(32),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);



INSERT INTO crm_users
    (user_id, username, email, full_name, phone, created_at, updated_at)
VALUES
    (1, 'prothetic1', 'prothetic.one@example.com',   'Prothetic One',   '+7-900-111-22-33', NOW() - INTERVAL '90 days', NOW() - INTERVAL '5 days'),
    (2, 'prothetic2', 'prothetic.two@example.com',   'Prothetic Two',   '+7-900-222-33-44', NOW() - INTERVAL '60 days', NOW() - INTERVAL '2 days'),
    (3, 'prothetic3', 'prothetic.three@example.com', 'Prothetic Three', '+7-900-333-44-55', NOW() - INTERVAL '45 days', NOW() - INTERVAL '1 day');
