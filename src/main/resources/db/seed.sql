-- ======================================================================
-- FlashTicket Database Seed Script
-- Seeds initial event shows and role-based users (Admin, Organizer, User)
-- ======================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Ensure tables exist (aligned with Hibernate entities)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'ROLE_USER',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS event_shows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    venue VARCHAR(255),
    show_time TIMESTAMP WITH TIME ZONE NOT NULL,
    total_seats INT NOT NULL,
    available_seats INT NOT NULL,
    price NUMERIC(10, 2) DEFAULT 50.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure orders table has seat_codes column if already created
DO $$ 
BEGIN 
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'orders') THEN
        ALTER TABLE orders ADD COLUMN IF NOT EXISTS seat_codes VARCHAR(255);
    END IF;
END $$;


-- 2. Seed Default Shows
INSERT INTO event_shows (id, title, venue, show_time, total_seats, available_seats, price, created_at, updated_at)
VALUES (
    'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
    'Coldplay: Music of the Spheres — Live in Mumbai',
    'DY Patil Stadium, Navi Mumbai',
    NOW() + INTERVAL '7 days',
    100,
    100,
    75.00,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO event_shows (id, title, venue, show_time, total_seats, available_seats, price, created_at, updated_at)
VALUES (
    'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
    'Midnight Sessions: Electronic Flash Festival',
    'Grand Arena, Mumbai',
    NOW() + INTERVAL '14 days',
    250,
    250,
    50.00,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 3. Seed Users by Role (BCrypt hashed using pgcrypto gen_salt('bf', 10))

-- [Role: ROLE_ADMIN] System Administrator
INSERT INTO users (id, email, password, full_name, role, created_at, updated_at)
VALUES (
    'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f',
    'admin@flashticket.com',
    crypt('admin123', gen_salt('bf', 10)),
    'System Administrator',
    'ROLE_ADMIN',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET 
    role = 'ROLE_ADMIN',
    password = crypt('admin123', gen_salt('bf', 10));

-- [Role: ROLE_ORGANIZER] Event Organizer
INSERT INTO users (id, email, password, full_name, role, created_at, updated_at)
VALUES (
    'd4e5f6a7-b89c-0d1e-2f3a-4b5c6d7e8f9a',
    'organizer@flashticket.com',
    crypt('organizer123', gen_salt('bf', 10)),
    'Event Organizer',
    'ROLE_ORGANIZER',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET 
    role = 'ROLE_ORGANIZER',
    password = crypt('organizer123', gen_salt('bf', 10));

-- [Role: ROLE_ORGANIZER] Promoter Account
INSERT INTO users (id, email, password, full_name, role, created_at, updated_at)
VALUES (
    'a7b89c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d',
    'promoter@flashticket.com',
    crypt('promoter123', gen_salt('bf', 10)),
    'Live Nation Promoter',
    'ROLE_ORGANIZER',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET 
    role = 'ROLE_ORGANIZER',
    password = crypt('promoter123', gen_salt('bf', 10));

-- [Role: ROLE_USER] Standard Customer
INSERT INTO users (id, email, password, full_name, role, created_at, updated_at)
VALUES (
    'e5f6a7b8-9c0d-1e2f-3a4b-5c6d7e8f9a0b',
    'user@flashticket.com',
    crypt('user123', gen_salt('bf', 10)),
    'Demo Customer',
    'ROLE_USER',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET 
    role = 'ROLE_USER',
    password = crypt('user123', gen_salt('bf', 10));

-- [Role: ROLE_USER] Regular Buyer
INSERT INTO users (id, email, password, full_name, role, created_at, updated_at)
VALUES (
    'f6a7b89c-0d1e-2f3a-4b5c-6d7e8f9a0b1c',
    'alice@flashticket.com',
    crypt('password123', gen_salt('bf', 10)),
    'Alice Johnson',
    'ROLE_USER',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET 
    role = 'ROLE_USER',
    password = crypt('password123', gen_salt('bf', 10));

