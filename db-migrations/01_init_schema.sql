-- Mengaktifkan UUID generator bawaan PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Membuat Tipe Data Enum untuk Role yang ketat (RBAC)
CREATE TYPE user_role AS ENUM ('mahasiswa', 'staf', 'dosen', 'admin');

-- Tabel Pengguna (Fokus Sprint 1)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Ingat: Harus Hashed (Bcrypt), bukan plain text
    role user_role NOT NULL DEFAULT 'mahasiswa',
    full_name VARCHAR(150) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Master Zona Parkir (Fokus Sprint 1)
CREATE TABLE zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_code VARCHAR(10) UNIQUE NOT NULL, -- Contoh: 'Z-DOSEN', 'Z-MHS-A'
    zone_name VARCHAR(100) NOT NULL,
    total_capacity INT NOT NULL CHECK (total_capacity >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
