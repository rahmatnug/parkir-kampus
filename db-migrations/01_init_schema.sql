-- Mengaktifkan UUID generator bawaan PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Membuat Tipe Data Enum untuk Role yang ketat (RBAC)
CREATE TYPE user_role AS ENUM ('mahasiswa', 'staf', 'dosen', 'admin');

-- Tabel Roles
CREATE TABLE roles (
    id_role   SMALLSERIAL PRIMARY KEY,
    nama_role VARCHAR(30) UNIQUE NOT NULL,
    prioritas SMALLINT NOT NULL
);

-- Tabel Pengguna
CREATE TABLE users (
    id_user       BIGSERIAL PRIMARY KEY,
    id_role       SMALLINT REFERENCES roles(id_role) ON DELETE SET NULL,
    nama          VARCHAR(100) NOT NULL,
    nim           VARCHAR(20),
    email         VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    status        VARCHAR(20) DEFAULT 'active',
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Master Zona Parkir
CREATE TABLE zona_parkirs (
    id_zona    BIGSERIAL PRIMARY KEY,
    nama_zona  VARCHAR(50) NOT NULL,
    deskripsi  TEXT,
    kapasitas  INTEGER NOT NULL,
    status     VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Slot Parkir
CREATE TABLE slot_parkirs (
    id_slot    BIGSERIAL PRIMARY KEY,
    id_zona    BIGINT REFERENCES zona_parkirs(id_zona) ON DELETE CASCADE,
    nomor_slot VARCHAR(20) NOT NULL,
    status     VARCHAR(20) DEFAULT 'available'
);

-- Tabel Kendaraan — ON DELETE CASCADE: hapus user → hapus kendaraan-nya
CREATE TABLE kendaraans (
    id_kendaraan    BIGSERIAL PRIMARY KEY,
    id_user         BIGINT REFERENCES users(id_user) ON DELETE CASCADE,
    nomor_polisi    VARCHAR(15) UNIQUE NOT NULL,
    jenis_kendaraan VARCHAR(20) CHECK (jenis_kendaraan IN ('motor', 'mobil')),
    warna           VARCHAR(30),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Transaksi Parkir — ON DELETE CASCADE: hapus user → hapus riwayat parkir-nya
CREATE TABLE transaksis (
    id_transaksi BIGSERIAL PRIMARY KEY,
    id_user      BIGINT REFERENCES users(id_user) ON DELETE CASCADE,
    id_kendaraan BIGINT REFERENCES kendaraans(id_kendaraan) ON DELETE CASCADE,
    id_slot      BIGINT REFERENCES slot_parkirs(id_slot) ON DELETE SET NULL,
    waktu_masuk  TIMESTAMP NOT NULL,
    waktu_keluar TIMESTAMP,
    status       VARCHAR(20) DEFAULT 'parkir'
);

-- Tabel Waiting List — ON DELETE CASCADE: hapus user → hapus antrian-nya
CREATE TABLE waiting_lists (
    id_waiting       BIGSERIAL PRIMARY KEY,
    id_user          BIGINT REFERENCES users(id_user) ON DELETE CASCADE,
    id_zona          SMALLINT REFERENCES zona_parkirs(id_zona) ON DELETE CASCADE,
    waktu_permohonan TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    posisi_antrian   INTEGER NOT NULL
);

-- Tabel Penalti — ON DELETE CASCADE: hapus user → hapus penalti-nya
CREATE TABLE penaltis (
    id_penalti        BIGSERIAL PRIMARY KEY,
    id_user           BIGINT REFERENCES users(id_user) ON DELETE CASCADE,
    jenis_pelanggaran VARCHAR(100),
    poin_penalti      INTEGER,
    tanggal           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Blacklist — ON DELETE CASCADE: hapus user → hapus record blacklist-nya
CREATE TABLE blacklists (
    id_blacklist    BIGSERIAL PRIMARY KEY,
    id_user         BIGINT REFERENCES users(id_user) ON DELETE CASCADE,
    alasan          TEXT,
    tanggal_mulai   TIMESTAMP NOT NULL,
    tanggal_selesai TIMESTAMP,
    status          VARCHAR(20) DEFAULT 'active'
);
