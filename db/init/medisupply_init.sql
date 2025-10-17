-- Inicialización de la base de datos de medisupply
-- Crea la tabla users_medisupply si no existe e inserta un usuario semilla
CREATE TABLE IF NOT EXISTS users_medisupply (
    id varchar(36) PRIMARY KEY,
    name varchar(100) NOT NULL,
    tax_id varchar(50),
    email varchar(100) NOT NULL UNIQUE,
    address varchar(200),
    phone varchar(20),
    institution_type varchar(20),
    logo_filename varchar(255),
    logo_url text,
    specialty varchar(20),
    applicant_name varchar(80),
    applicant_email varchar(100),
    latitude REAL,
    longitude REAL,
    enabled boolean NOT NULL DEFAULT FALSE,
    created_at timestamptz NOT NULL DEFAULT timezone('UTC', now()),
    updated_at timestamptz NOT NULL DEFAULT timezone('UTC', now())
);

-- Inserción del usuario semilla (no falla si ya existe)
INSERT INTO users_medisupply (
    id,
    name,
    email,
    enabled,
    created_at,
    updated_at
) VALUES (
    '8f1b7d3f-4e3b-4f5e-9b2a-7d2a6b9f1c05',
    'medisupply05',
    'medisupply05@gmail.com',
    TRUE,
    (NOW() AT TIME ZONE 'UTC'),
    (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT (id) DO NOTHING;
