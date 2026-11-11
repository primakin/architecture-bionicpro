CREATE TABLE crm_users (
    user_id         BIGSERIAL       PRIMARY KEY,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    full_name       VARCHAR(255)    NOT NULL,
    phone           VARCHAR(32),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);



INSERT INTO crm_users
    (email, full_name, phone, created_at, updated_at)
VALUES
    ('ivan.petrov@example.com',    'Иван Петров',     '+7-900-111-22-33', NOW() - INTERVAL '90 days', NOW() - INTERVAL '5 days'),
    ('anna.smirnova@example.com',  'Анна Смирнова',   '+7-900-222-33-44', NOW() - INTERVAL '60 days', NOW() - INTERVAL '2 days'),
    ('sergey.kozl@example.com',    'Сергей Козлов',   '+7-900-333-44-55', NOW() - INTERVAL '45 days', NOW() - INTERVAL '1 day'),
    ('olga.ivanova@example.com',   'Ольга Иванова',   '+7-900-444-55-66', NOW() - INTERVAL '120 days', NOW() - INTERVAL '30 days'),
    ('dmitry.volkov@example.com',  'Дмитрий Волков',  NULL,               NOW() - INTERVAL '200 days', NOW() - INTERVAL '10 days');
