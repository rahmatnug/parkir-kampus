--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.0

-- Started on 2026-06-05 10:16:02

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 44 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3951 (class 0 OID 0)
-- Dependencies: 44
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 395 (class 1259 OID 17671)
-- Name: blacklists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.blacklists (
    id_blacklist bigint NOT NULL,
    id_user bigint,
    alasan text,
    tanggal_mulai timestamp without time zone,
    tanggal_selesai timestamp without time zone,
    status character varying(20) DEFAULT 'active'::character varying
);


ALTER TABLE public.blacklists OWNER TO postgres;

--
-- TOC entry 394 (class 1259 OID 17670)
-- Name: blacklists_id_blacklist_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.blacklists_id_blacklist_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.blacklists_id_blacklist_seq OWNER TO postgres;

--
-- TOC entry 3954 (class 0 OID 0)
-- Dependencies: 394
-- Name: blacklists_id_blacklist_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.blacklists_id_blacklist_seq OWNED BY public.blacklists.id_blacklist;


--
-- TOC entry 383 (class 1259 OID 17575)
-- Name: kendaraans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kendaraans (
    id_kendaraan bigint NOT NULL,
    id_user bigint,
    nomor_polisi character varying(15) NOT NULL,
    jenis_kendaraan character varying(20),
    created_at timestamp with time zone,
    deleted_at timestamp with time zone,
    warna character varying(30),
    CONSTRAINT chk_kendaraans_jenis_kendaraan CHECK (((jenis_kendaraan)::text = ANY ((ARRAY['motor'::character varying, 'mobil'::character varying])::text[])))
);


ALTER TABLE public.kendaraans OWNER TO postgres;

--
-- TOC entry 382 (class 1259 OID 17574)
-- Name: kendaraans_id_kendaraan_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.kendaraans_id_kendaraan_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kendaraans_id_kendaraan_seq OWNER TO postgres;

--
-- TOC entry 3957 (class 0 OID 0)
-- Dependencies: 382
-- Name: kendaraans_id_kendaraan_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.kendaraans_id_kendaraan_seq OWNED BY public.kendaraans.id_kendaraan;


--
-- TOC entry 397 (class 1259 OID 25455)
-- Name: laporan_petugases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.laporan_petugases (
    id_laporan bigint NOT NULL,
    id_petugas bigint,
    target_identifier character varying(100) NOT NULL,
    deskripsi_pelanggaran text NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    created_at timestamp with time zone,
    bukti_foto text,
    target_user_id bigint
);


ALTER TABLE public.laporan_petugases OWNER TO postgres;

--
-- TOC entry 396 (class 1259 OID 25454)
-- Name: laporan_petugases_id_laporan_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.laporan_petugases_id_laporan_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.laporan_petugases_id_laporan_seq OWNER TO postgres;

--
-- TOC entry 3960 (class 0 OID 0)
-- Dependencies: 396
-- Name: laporan_petugases_id_laporan_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.laporan_petugases_id_laporan_seq OWNED BY public.laporan_petugases.id_laporan;


--
-- TOC entry 393 (class 1259 OID 17659)
-- Name: penaltis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.penaltis (
    id_penalti bigint NOT NULL,
    id_user bigint,
    jenis_pelanggaran character varying(100),
    poin_penalti integer,
    tanggal timestamp with time zone
);


ALTER TABLE public.penaltis OWNER TO postgres;

--
-- TOC entry 392 (class 1259 OID 17658)
-- Name: penaltis_id_penalti_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.penaltis_id_penalti_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.penaltis_id_penalti_seq OWNER TO postgres;

--
-- TOC entry 3963 (class 0 OID 0)
-- Dependencies: 392
-- Name: penaltis_id_penalti_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.penaltis_id_penalti_seq OWNED BY public.penaltis.id_penalti;


--
-- TOC entry 399 (class 1259 OID 25470)
-- Name: qr_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qr_codes (
    id bigint NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    type character varying(20) DEFAULT 'zone'::character varying,
    created_at timestamp with time zone
);


ALTER TABLE public.qr_codes OWNER TO postgres;

--
-- TOC entry 398 (class 1259 OID 25469)
-- Name: qr_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qr_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.qr_codes_id_seq OWNER TO postgres;

--
-- TOC entry 3966 (class 0 OID 0)
-- Dependencies: 398
-- Name: qr_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qr_codes_id_seq OWNED BY public.qr_codes.id;


--
-- TOC entry 379 (class 1259 OID 17550)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id_role bigint NOT NULL,
    nama_role character varying(30) NOT NULL,
    prioritas smallint NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 378 (class 1259 OID 17549)
-- Name: roles_id_role_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_role_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_role_seq OWNER TO postgres;

--
-- TOC entry 3969 (class 0 OID 0)
-- Dependencies: 378
-- Name: roles_id_role_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_role_seq OWNED BY public.roles.id_role;


--
-- TOC entry 387 (class 1259 OID 17602)
-- Name: slot_parkirs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.slot_parkirs (
    id_slot bigint NOT NULL,
    id_zona bigint,
    nomor_slot character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'available'::character varying,
    x_coord numeric DEFAULT 0,
    y_coord numeric DEFAULT 0
);


ALTER TABLE public.slot_parkirs OWNER TO postgres;

--
-- TOC entry 386 (class 1259 OID 17601)
-- Name: slot_parkirs_id_slot_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.slot_parkirs_id_slot_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.slot_parkirs_id_slot_seq OWNER TO postgres;

--
-- TOC entry 3972 (class 0 OID 0)
-- Dependencies: 386
-- Name: slot_parkirs_id_slot_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.slot_parkirs_id_slot_seq OWNED BY public.slot_parkirs.id_slot;


--
-- TOC entry 389 (class 1259 OID 17619)
-- Name: transaksis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaksis (
    id_transaksi bigint NOT NULL,
    id_user bigint,
    id_kendaraan bigint,
    id_slot bigint,
    waktu_masuk timestamp without time zone NOT NULL,
    waktu_keluar timestamp without time zone,
    status character varying(20) DEFAULT 'parkir'::character varying
);


ALTER TABLE public.transaksis OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 17618)
-- Name: transaksis_id_transaksi_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaksis_id_transaksi_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaksis_id_transaksi_seq OWNER TO postgres;

--
-- TOC entry 3975 (class 0 OID 0)
-- Dependencies: 388
-- Name: transaksis_id_transaksi_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaksis_id_transaksi_seq OWNED BY public.transaksis.id_transaksi;


--
-- TOC entry 381 (class 1259 OID 17559)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id_user bigint NOT NULL,
    id_role bigint,
    nama character varying(100) NOT NULL,
    nim character varying(20),
    email character varying(100) NOT NULL,
    password_hash text NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp with time zone,
    profile_image_url text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 380 (class 1259 OID 17558)
-- Name: users_id_user_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_user_seq OWNER TO postgres;

--
-- TOC entry 3978 (class 0 OID 0)
-- Dependencies: 380
-- Name: users_id_user_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_user_seq OWNED BY public.users.id_user;


--
-- TOC entry 391 (class 1259 OID 17642)
-- Name: waiting_lists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.waiting_lists (
    id_waiting bigint NOT NULL,
    id_user bigint,
    id_zona bigint,
    waktu_permohonan timestamp with time zone,
    posisi_antrian integer NOT NULL
);


ALTER TABLE public.waiting_lists OWNER TO postgres;

--
-- TOC entry 390 (class 1259 OID 17641)
-- Name: waiting_lists_id_waiting_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.waiting_lists_id_waiting_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.waiting_lists_id_waiting_seq OWNER TO postgres;

--
-- TOC entry 3981 (class 0 OID 0)
-- Dependencies: 390
-- Name: waiting_lists_id_waiting_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.waiting_lists_id_waiting_seq OWNED BY public.waiting_lists.id_waiting;


--
-- TOC entry 385 (class 1259 OID 17590)
-- Name: zona_parkirs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zona_parkirs (
    id_zona bigint NOT NULL,
    nama_zona character varying(50) NOT NULL,
    deskripsi text,
    kapasitas integer NOT NULL,
    jenis_kendaraan character varying(20) DEFAULT 'motor'::character varying,
    status character varying(20) DEFAULT 'active'::character varying,
    kapasitas_motor integer DEFAULT 0 NOT NULL,
    kapasitas_mobil integer DEFAULT 0 NOT NULL,
    kuota_motor_dosen bigint DEFAULT 0 NOT NULL,
    kuota_motor_mahasiswa bigint DEFAULT 0 NOT NULL,
    kuota_motor_tamu bigint DEFAULT 0 NOT NULL,
    kuota_mobil_dosen bigint DEFAULT 0 NOT NULL,
    kuota_mobil_mahasiswa bigint DEFAULT 0 NOT NULL,
    kuota_mobil_tamu bigint DEFAULT 0 NOT NULL,
    CONSTRAINT chk_zona_parkirs_jenis_kendaraan CHECK (((jenis_kendaraan)::text = ANY ((ARRAY['motor'::character varying, 'mobil'::character varying])::text[])))
);


ALTER TABLE public.zona_parkirs OWNER TO postgres;

--
-- TOC entry 384 (class 1259 OID 17589)
-- Name: zona_parkirs_id_zona_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zona_parkirs_id_zona_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.zona_parkirs_id_zona_seq OWNER TO postgres;

--
-- TOC entry 3984 (class 0 OID 0)
-- Dependencies: 384
-- Name: zona_parkirs_id_zona_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zona_parkirs_id_zona_seq OWNED BY public.zona_parkirs.id_zona;


--
-- TOC entry 3722 (class 2604 OID 17674)
-- Name: blacklists id_blacklist; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blacklists ALTER COLUMN id_blacklist SET DEFAULT nextval('public.blacklists_id_blacklist_seq'::regclass);


--
-- TOC entry 3702 (class 2604 OID 17578)
-- Name: kendaraans id_kendaraan; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kendaraans ALTER COLUMN id_kendaraan SET DEFAULT nextval('public.kendaraans_id_kendaraan_seq'::regclass);


--
-- TOC entry 3724 (class 2604 OID 25458)
-- Name: laporan_petugases id_laporan; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.laporan_petugases ALTER COLUMN id_laporan SET DEFAULT nextval('public.laporan_petugases_id_laporan_seq'::regclass);


--
-- TOC entry 3721 (class 2604 OID 17662)
-- Name: penaltis id_penalti; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.penaltis ALTER COLUMN id_penalti SET DEFAULT nextval('public.penaltis_id_penalti_seq'::regclass);


--
-- TOC entry 3726 (class 2604 OID 25473)
-- Name: qr_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes ALTER COLUMN id SET DEFAULT nextval('public.qr_codes_id_seq'::regclass);


--
-- TOC entry 3699 (class 2604 OID 17553)
-- Name: roles id_role; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id_role SET DEFAULT nextval('public.roles_id_role_seq'::regclass);


--
-- TOC entry 3714 (class 2604 OID 17605)
-- Name: slot_parkirs id_slot; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slot_parkirs ALTER COLUMN id_slot SET DEFAULT nextval('public.slot_parkirs_id_slot_seq'::regclass);


--
-- TOC entry 3718 (class 2604 OID 17622)
-- Name: transaksis id_transaksi; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaksis ALTER COLUMN id_transaksi SET DEFAULT nextval('public.transaksis_id_transaksi_seq'::regclass);


--
-- TOC entry 3700 (class 2604 OID 17562)
-- Name: users id_user; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id_user SET DEFAULT nextval('public.users_id_user_seq'::regclass);


--
-- TOC entry 3720 (class 2604 OID 17645)
-- Name: waiting_lists id_waiting; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waiting_lists ALTER COLUMN id_waiting SET DEFAULT nextval('public.waiting_lists_id_waiting_seq'::regclass);


--
-- TOC entry 3703 (class 2604 OID 17593)
-- Name: zona_parkirs id_zona; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zona_parkirs ALTER COLUMN id_zona SET DEFAULT nextval('public.zona_parkirs_id_zona_seq'::regclass);


--
-- TOC entry 3941 (class 0 OID 17671)
-- Dependencies: 395
-- Data for Name: blacklists; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.blacklists VALUES (1, 14, 'Otomatis blacklist: akumulasi poin penalti mencapai 100 (batas: 100)', '2026-05-31 19:01:32.035191', NULL, 'active');
INSERT INTO public.blacklists VALUES (2, 1, 'Test', '2026-05-31 20:52:03.987446', NULL, 'active');
INSERT INTO public.blacklists VALUES (3, 1, 'Test', '2026-05-31 20:53:13.730736', NULL, 'active');
INSERT INTO public.blacklists VALUES (4, 8, 'Manual Override by Admin', '2026-06-02 03:01:21.33901', NULL, 'inactive');
INSERT INTO public.blacklists VALUES (7, 31, 'Manual Override by Admin', '2026-06-02 03:22:40.853458', NULL, 'active');
INSERT INTO public.blacklists VALUES (8, 30, 'Manual Override by Admin', '2026-06-02 03:22:48.701669', NULL, 'active');


--
-- TOC entry 3929 (class 0 OID 17575)
-- Dependencies: 383
-- Data for Name: kendaraans; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.kendaraans VALUES (1, 2, 'B 1234 ABC', 'motor', '2026-05-11 14:09:01.995691+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (2, 3, 'D 8888 XYZ', 'mobil', '2026-05-11 14:09:02.163259+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (6, 9, 'B9999TQ', 'motor', '2026-05-31 18:57:23.921192+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (7, 10, 'B1002QX', 'motor', '2026-05-31 18:57:37.543256+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (8, 11, 'B1003QX', 'motor', '2026-05-31 18:57:38.538117+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (9, 12, 'B1005QX', 'motor', '2026-05-31 18:57:39.393622+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (10, 13, 'B1006QX', 'motor', '2026-05-31 18:57:39.724798+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (11, 14, 'B0099WT', 'motor', '2026-05-31 18:58:20.991826+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (12, 15, 'B0099TW', 'motor', '2026-05-31 18:58:21.274742+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (13, 16, 'B1234XYZ', 'mobil', '2026-05-31 20:07:20.792286+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (14, 17, 'L1234XYZ', 'motor', '2026-05-31 20:56:51.932736+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (15, 18, 'Ad  12 Er', 'mobil', '2026-06-01 05:35:29.037937+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (16, 19, 'A 1111 EB', 'motor', '2026-06-01 07:48:06.665444+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (17, 21, 'B 12 G', 'mobil', '2026-06-01 15:21:41.425345+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (19, 23, 'B 11 G', 'mobil', '2026-06-01 15:23:15.531949+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (20, 24, 'Q 11 W', 'motor', '2026-06-01 21:57:25.534445+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (22, 26, 'D 229 I', 'mobil', '2026-06-01 22:03:57.339269+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (23, 27, 'D 2329 I', 'mobil', '2026-06-01 22:04:30.846626+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (24, 28, 'D 1229 I', 'mobil', '2026-06-01 22:05:16.061272+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (25, 29, 'A 12 b', 'motor', '2026-06-02 00:17:31.244461+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (21, 25, 'D 19 I', 'mobil', '2026-06-01 22:03:06.613377+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (5, 8, 'B1234QA', 'motor', '2026-05-31 18:56:09.035405+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (27, 31, 'A 1222 b', 'motor', '2026-06-02 00:18:06.99004+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (26, 30, 'A 122 b', 'motor', '2026-06-02 00:17:51.457487+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (28, 32, 'A 1252 b', 'motor', '2026-06-02 00:18:31.256048+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (3, 4, 'AE 1121 FG', 'mobil', '2026-05-11 14:58:00.920643+00', NULL, NULL);
INSERT INTO public.kendaraans VALUES (31, 35, 'AE 1234 RY', 'motor', '2026-06-02 06:22:57.895163+00', NULL, '');
INSERT INTO public.kendaraans VALUES (32, 36, 'A 1234 E', 'mobil', '2026-06-02 06:26:26.559778+00', NULL, '');
INSERT INTO public.kendaraans VALUES (33, 37, 'AE 1234 AC', 'motor', '2026-06-02 06:27:49.242036+00', NULL, '');
INSERT INTO public.kendaraans VALUES (34, 38, 'AE 4636 FF', 'motor', '2026-06-02 06:46:24.054114+00', NULL, '');
INSERT INTO public.kendaraans VALUES (35, 39, 'q 34 r', 'mobil', '2026-06-02 06:46:59.579193+00', NULL, '');
INSERT INTO public.kendaraans VALUES (29, 33, '', 'motor', '2026-06-02 01:01:37.977668+00', '2026-06-02 06:47:22.749027+00', NULL);
INSERT INTO public.kendaraans VALUES (36, 33, 'AE 1234 CD', 'motor', '2026-06-02 06:47:22.803803+00', NULL, '');
INSERT INTO public.kendaraans VALUES (37, 40, 'a44f', 'mobil', '2026-06-02 06:50:51.056722+00', NULL, '');
INSERT INTO public.kendaraans VALUES (38, 41, 'a34f', 'motor', '2026-06-02 06:53:16.467932+00', NULL, '');
INSERT INTO public.kendaraans VALUES (39, 42, 'A 12 B', 'mobil', '2026-06-04 04:04:52.091418+00', '2026-06-04 04:51:46.510478+00', '');
INSERT INTO public.kendaraans VALUES (40, 42, 'A 12g Blv', 'mobil', '2026-06-04 04:51:46.56716+00', NULL, '');
INSERT INTO public.kendaraans VALUES (41, 43, 'AD 1234 AE', 'motor', '2026-06-04 04:58:53.926228+00', NULL, '');
INSERT INTO public.kendaraans VALUES (42, 44, 'AE 123 AB', 'mobil', '2026-06-04 05:57:09.82859+00', '2026-06-04 06:03:17.312488+00', '');
INSERT INTO public.kendaraans VALUES (43, 44, 'AE 1234 AB', 'motor', '2026-06-04 06:03:17.365621+00', NULL, '');


--
-- TOC entry 3943 (class 0 OID 25455)
-- Dependencies: 397
-- Data for Name: laporan_petugases; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.laporan_petugases VALUES (1, 6, 'A 124 b', '[Parkir Liar / Luar Slot] meh', 'pending', '2026-06-01 23:17:51.133894+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780355870369.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (2, 6, 'AE 1234 H', '[Menghalangi Jalur Evakuasi] MM', 'pending', '2026-06-02 00:16:47.031363+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780359406038.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (3, 6, 'AE 1223 FG', '[Parkir Liar / Luar Slot] mm', 'pending', '2026-06-02 00:32:54.188216+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780360373293.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (4, 6, 'AE 1223 FG', '[Parkir Liar / Luar Slot] mm', 'pending', '2026-06-02 00:32:56.314725+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780360376085.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (5, 6, 'AE 1223 FG', '[Parkir Liar / Luar Slot] mm', 'pending', '2026-06-02 00:32:57.575812+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780360377316.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (6, 6, 'AE 1223 FG', '[Parkir Liar / Luar Slot] mm', 'pending', '2026-06-02 00:32:59.957612+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780360379429.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (7, 6, 'AE 1223 FG', '[Parkir Liar / Luar Slot] mm', 'pending', '2026-06-02 00:33:09.115288+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780360388798.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (8, 6, 'AE 1223 FG', '[Parkir Liar / Luar Slot] mm', 'pending', '2026-06-02 00:33:11.031644+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780360390786.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (9, 6, 'AE 1223 FG', '[Tanpa Stiker / QR Code] te', 'pending', '2026-06-02 01:29:44.066319+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780363783108.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (17, 6, 'AE 1121 FG', '[Menghalangi Jalur Evakuasi] te', 'approved', '2026-06-02 04:02:33.199388+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780372952747.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (18, 6, 'ae 1121 fg', '[Parkir Liar / Luar Slot] 33', 'approved', '2026-06-02 04:39:43.225978+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780375182168.jpg', 4);
INSERT INTO public.laporan_petugases VALUES (19, 6, 'a e 3', '[Menghalangi Jalur Evakuasi] 2', 'rejected', '2026-06-02 04:42:23.994783+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780375343350.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (20, 6, 'Ae 1121 fg', '[Menghalangi Jalur Evakuasi] 2', 'rejected', '2026-06-02 04:42:36.58957+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780375355974.jpg', 4);
INSERT INTO public.laporan_petugases VALUES (16, 6, 'AE 1121 FG', '[Menghalangi Jalur Evakuasi] ge', 'rejected', '2026-06-02 04:00:49.189124+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780372847846.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (15, 6, 'AE 1121 FH', '[Parkir Ganda] 1', 'rejected', '2026-06-02 03:20:56.829942+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780370456242.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (23, 6, 'AE 123 AB', '[Parkir Liar / Luar Slot] PArkir tidak sesuai dengan slot', 'approved', '2026-06-04 06:05:04.047187+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780553101876.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (21, 6, 'ae 1121 fg', '[Parkir Ganda] w', 'rejected', '2026-06-02 04:44:54.314045+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780375493632.jpg', 4);
INSERT INTO public.laporan_petugases VALUES (22, 6, 'ae1121fg', '[Parkir Ganda] w', 'approved', '2026-06-02 05:22:57.919535+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780377775765.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (14, 6, 'AE 1123 FH', '[Parkir Liar / Luar Slot] ae', 'rejected', '2026-06-02 03:09:16.128037+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780369755805.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (13, 6, 'AE 1123 FH', '[Parkir Liar / Luar Slot] ae', 'rejected', '2026-06-02 03:09:11.213919+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780369749585.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (12, 6, 'AE 1123 FH', '[Parkir Ganda] 22', 'rejected', '2026-06-02 02:26:16.980174+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780367175851.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (11, 6, 'AE 1123 FH', '[Parkir Ganda] 22', 'rejected', '2026-06-02 02:26:12.325906+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780367171619.jpg', NULL);
INSERT INTO public.laporan_petugases VALUES (10, 6, 'AE1124FG', '[Parkir Ganda] 111', 'rejected', '2026-06-02 01:59:57.785022+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/reports/6_1780365596707.jpg', NULL);


--
-- TOC entry 3939 (class 0 OID 17659)
-- Dependencies: 393
-- Data for Name: penaltis; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.penaltis VALUES (1, 2, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-05-31 17:06:59.79838+00');
INSERT INTO public.penaltis VALUES (2, 14, 'QA Test - Force blacklist via max penalty', 100, '2026-05-31 19:01:31.93048+00');
INSERT INTO public.penaltis VALUES (4, 18, 'bb', 10, '2026-06-01 07:49:57.33503+00');
INSERT INTO public.penaltis VALUES (5, 18, 'hh', 10, '2026-06-01 15:25:52.215849+00');
INSERT INTO public.penaltis VALUES (6, 8, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 01:15:28.365355+00');
INSERT INTO public.penaltis VALUES (7, 11, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 01:15:28.365355+00');
INSERT INTO public.penaltis VALUES (8, 12, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 01:15:28.365355+00');
INSERT INTO public.penaltis VALUES (9, 13, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 01:15:28.365355+00');
INSERT INTO public.penaltis VALUES (10, 9, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 01:15:28.365355+00');
INSERT INTO public.penaltis VALUES (13, 31, 'Manual Override by Admin', 100, '2026-06-02 03:22:40.74619+00');
INSERT INTO public.penaltis VALUES (14, 30, 'Manual Override by Admin', 100, '2026-06-02 03:22:48.631819+00');
INSERT INTO public.penaltis VALUES (20, 35, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 16:59:00.105578+00');
INSERT INTO public.penaltis VALUES (21, 38, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 16:59:00.105578+00');
INSERT INTO public.penaltis VALUES (22, 40, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 16:59:00.105578+00');
INSERT INTO public.penaltis VALUES (23, 33, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 16:59:00.105578+00');
INSERT INTO public.penaltis VALUES (24, 41, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-02 16:59:00.105578+00');
INSERT INTO public.penaltis VALUES (25, 3, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-03 18:49:19.844154+00');
INSERT INTO public.penaltis VALUES (29, 41, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-04 16:59:00.111694+00');
INSERT INTO public.penaltis VALUES (30, 44, 'Tidak Tap-Out (Ghost Exit)', 10, '2026-06-04 16:59:00.111694+00');


--
-- TOC entry 3945 (class 0 OID 25470)
-- Dependencies: 399
-- Data for Name: qr_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.qr_codes VALUES (1, 'ZONA-A-QR', 'ZONA A', 'zone', '2026-05-31 17:10:23.183779+00');
INSERT INTO public.qr_codes VALUES (2, 'ZONA-B-QR', 'ZONA B', 'zone', '2026-05-31 17:10:23.321884+00');
INSERT INTO public.qr_codes VALUES (3, 'ZONA-C-QR', 'ZONA C', 'zone', '2026-05-31 17:10:23.455848+00');
INSERT INTO public.qr_codes VALUES (4, 'ZONA-D-QR', 'ZONA D', 'zone', '2026-05-31 17:10:23.595175+00');
INSERT INTO public.qr_codes VALUES (5, 'ZONA-E-QR', 'ZONA E', 'zone', '2026-05-31 17:10:23.744266+00');


--
-- TOC entry 3925 (class 0 OID 17550)
-- Dependencies: 379
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.roles VALUES (1, 'admin', 1);
INSERT INTO public.roles VALUES (2, 'dosen', 2);
INSERT INTO public.roles VALUES (3, 'mahasiswa', 3);
INSERT INTO public.roles VALUES (4, 'staff', 2);
INSERT INTO public.roles VALUES (5, 'tamu', 1);
INSERT INTO public.roles VALUES (6, 'petugas', 2);


--
-- TOC entry 3933 (class 0 OID 17602)
-- Dependencies: 387
-- Data for Name: slot_parkirs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.slot_parkirs VALUES (15, 3, 'C-01', 'available', 300, 40);
INSERT INTO public.slot_parkirs VALUES (9, 2, 'B-01', 'available', 160, 40);
INSERT INTO public.slot_parkirs VALUES (19, 4, 'D-01', 'available', 300, 160);
INSERT INTO public.slot_parkirs VALUES (3, 1, 'A-03', 'available', 30, 120);
INSERT INTO public.slot_parkirs VALUES (1, 1, 'A-01', 'available', 30, 40);
INSERT INTO public.slot_parkirs VALUES (2, 1, 'A-02', 'available', 30, 80);
INSERT INTO public.slot_parkirs VALUES (6, 1, 'A-06', 'available', 80, 80);
INSERT INTO public.slot_parkirs VALUES (5, 1, 'A-05', 'available', 80, 40);
INSERT INTO public.slot_parkirs VALUES (4, 1, 'A-04', 'available', 30, 160);
INSERT INTO public.slot_parkirs VALUES (7, 1, 'A-07', 'available', 80, 120);
INSERT INTO public.slot_parkirs VALUES (8, 1, 'A-08', 'available', 80, 160);
INSERT INTO public.slot_parkirs VALUES (16, 3, 'C-02', 'available', 300, 80);
INSERT INTO public.slot_parkirs VALUES (17, 3, 'C-03', 'available', 300, 120);
INSERT INTO public.slot_parkirs VALUES (18, 3, 'C-04', 'available', 300, 160);
INSERT INTO public.slot_parkirs VALUES (10, 2, 'B-02', 'available', 160, 80);
INSERT INTO public.slot_parkirs VALUES (11, 2, 'B-03', 'available', 160, 120);
INSERT INTO public.slot_parkirs VALUES (12, 2, 'B-04', 'available', 160, 160);
INSERT INTO public.slot_parkirs VALUES (13, 2, 'B-05', 'available', 210, 40);
INSERT INTO public.slot_parkirs VALUES (14, 2, 'B-06', 'available', 210, 80);


--
-- TOC entry 3935 (class 0 OID 17619)
-- Dependencies: 389
-- Data for Name: transaksis; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.transaksis VALUES (10, 3, 2, 2, '2026-05-17 09:07:22.515899', '2026-05-17 13:07:22.515899', 'selesai');
INSERT INTO public.transaksis VALUES (11, 4, 3, 1, '2026-05-30 23:00:21.98637', '2026-05-31 06:00:41.994999', 'selesai');
INSERT INTO public.transaksis VALUES (9, 2, 1, 1, '2026-05-17 05:07:22.41321', '2026-05-31 17:06:59.79838', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (13, 10, 7, 10, '2026-05-31 11:57:54.303324', '2026-05-31 19:02:05.053503', 'selesai');
INSERT INTO public.transaksis VALUES (18, 4, 3, 1, '2026-06-01 07:53:18.976201', '2026-06-01 14:53:40.380489', 'selesai');
INSERT INTO public.transaksis VALUES (19, 4, 3, 15, '2026-06-01 07:54:04.044518', '2026-06-01 22:00:25.178806', 'selesai');
INSERT INTO public.transaksis VALUES (20, 4, 3, 15, '2026-06-01 17:20:35.223929', '2026-06-02 00:22:50.113379', 'selesai');
INSERT INTO public.transaksis VALUES (21, 4, 3, 10, '2026-06-01 17:23:24.442801', '2026-06-02 00:23:53.542107', 'selesai');
INSERT INTO public.transaksis VALUES (12, 8, 5, 9, '2026-05-31 11:57:00.746351', '2026-06-02 01:15:28.365355', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (14, 11, 8, 11, '2026-05-31 11:57:54.714578', '2026-06-02 01:15:28.365355', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (15, 12, 9, 12, '2026-05-31 11:57:55.224751', '2026-06-02 01:15:28.365355', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (16, 13, 10, 13, '2026-05-31 11:57:55.604892', '2026-06-02 01:15:28.365355', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (17, 9, 6, 14, '2026-05-31 11:58:03.508129', '2026-06-02 01:15:28.365355', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (22, 4, 3, 9, '2026-06-01 19:23:29.015979', '2026-06-02 02:23:49.367111', 'selesai');
INSERT INTO public.transaksis VALUES (23, 4, 3, 1, '2026-06-01 20:53:39.822156', '2026-06-02 03:54:14.343932', 'selesai');
INSERT INTO public.transaksis VALUES (24, 4, 3, 9, '2026-06-01 20:56:16.26316', '2026-06-02 03:56:31.214271', 'selesai');
INSERT INTO public.transaksis VALUES (25, 4, 3, 15, '2026-06-01 20:57:41.674294', '2026-06-02 03:59:33.38458', 'selesai');
INSERT INTO public.transaksis VALUES (26, 4, 3, 19, '2026-06-01 20:59:45.5864', '2026-06-02 04:37:37.076632', 'selesai');
INSERT INTO public.transaksis VALUES (27, 4, 3, 1, '2026-06-01 22:31:21.911685', '2026-06-02 05:31:34.185751', 'selesai');
INSERT INTO public.transaksis VALUES (28, 4, 3, 9, '2026-06-02 05:45:29.934283', '2026-06-02 05:50:38.677175', 'selesai');
INSERT INTO public.transaksis VALUES (30, 39, 35, 2, '2026-06-02 06:47:16.489728', '2026-06-02 06:47:31.397229', 'selesai');
INSERT INTO public.transaksis VALUES (32, 33, 36, 2, '2026-06-02 06:47:35.01038', '2026-06-02 06:47:46.614607', 'selesai');
INSERT INTO public.transaksis VALUES (34, 41, 38, 4, '2026-06-02 06:54:12.841902', '2026-06-02 06:56:41.15411', 'selesai');
INSERT INTO public.transaksis VALUES (37, 4, 3, 6, '2026-06-02 08:02:51.858552', '2026-06-02 08:03:42.013257', 'selesai');
INSERT INTO public.transaksis VALUES (29, 35, 31, 1, '2026-06-02 06:23:57.20935', '2026-06-02 16:59:00.105578', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (31, 38, 34, 3, '2026-06-02 06:47:20.979821', '2026-06-02 16:59:00.105578', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (33, 40, 37, 2, '2026-06-02 06:51:37.253135', '2026-06-02 16:59:00.105578', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (35, 33, 36, 5, '2026-06-02 06:55:46.232313', '2026-06-02 16:59:00.105578', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (36, 41, 38, 4, '2026-06-02 06:56:57.10995', '2026-06-02 16:59:00.105578', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (38, 3, 2, 1, '2026-06-03 13:01:49.700698', '2026-06-03 18:49:19.844154', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (39, 4, 3, 9, '2026-06-03 14:02:04.072812', '2026-06-03 18:49:19.844154', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (41, 43, 41, 15, '2026-06-04 05:01:18.667088', '2026-06-04 05:19:09.243619', 'selesai');
INSERT INTO public.transaksis VALUES (43, 4, 3, 9, '2026-06-04 05:47:17.142733', '2026-06-04 05:47:24.51009', 'selesai');
INSERT INTO public.transaksis VALUES (44, 44, 42, 2, '2026-06-04 05:58:33.176564', '2026-06-04 06:01:10.637243', 'selesai');
INSERT INTO public.transaksis VALUES (45, 4, 3, 3, '2026-06-04 06:00:07.088689', '2026-06-04 06:07:34.414573', 'selesai');
INSERT INTO public.transaksis VALUES (40, 41, 38, 1, '2026-06-04 04:50:52.223288', '2026-06-04 16:59:00.111694', 'selesai_paksa');
INSERT INTO public.transaksis VALUES (46, 44, 42, 2, '2026-06-04 06:02:20.868758', '2026-06-04 16:59:00.111694', 'selesai_paksa');


--
-- TOC entry 3927 (class 0 OID 17559)
-- Dependencies: 381
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES (7, 5, 'Pengunjung Tamu', '', 'tamu@gmail.com', '$2a$10$7nt/u8rCLSjNny9Q.FGOmO1jKO3GcPmpyWe9k/en5vMb07oLxzo3W', 'active', '2026-05-31 03:43:32.100016+00', '');
INSERT INTO public.users VALUES (9, 5, 'Tamu QA Test', '', 'tamuqa@gmail.com', '$2a$10$/Z6kSPNt2YPcqu.uf3NSZ.4c9rVAX9jAUo0EWQtrdYmMZBxjwAYJ2', 'active', '2026-05-31 18:57:23.884582+00', '');
INSERT INTO public.users VALUES (10, 3, 'User Test 2', '240101002', '240101002@mhs.unesa.ac.id', '$2a$10$t4fLP1J42nx6JN0RChbF5uS6J8v/8BBjwM6RC2VSdVbajj/yfYcP2', 'active', '2026-05-31 18:57:37.37331+00', '');
INSERT INTO public.users VALUES (11, 3, 'User Test 3', '240101003', '240101003@mhs.unesa.ac.id', '$2a$10$KEY3TdlMJxNYfRY1qOayIedhkTVd8kD2BuJhvufMNouMoKlxu1FDS', 'active', '2026-05-31 18:57:38.504241+00', '');
INSERT INTO public.users VALUES (12, 3, 'User Test 5', '240101005', '240101005@mhs.unesa.ac.id', '$2a$10$creDAmlg4rNlt1hzeoCN5O0fLV2W6oyfbQpoFOHoab0sGUucu3gJu', 'active', '2026-05-31 18:57:39.335046+00', '');
INSERT INTO public.users VALUES (13, 3, 'User Test 6', '240101006', '240101006@mhs.unesa.ac.id', '$2a$10$Uizdihy49ZtBVZAQLo03wOTL4riXlHiAS8RPfoT1POmX8Swl3QkZ6', 'active', '2026-05-31 18:57:39.691064+00', '');
INSERT INTO public.users VALUES (15, 5, 'Tamu Waitlist Test', '', 'tamuwaitlist@gmail.com', '$2a$10$g7KOiYc537PFbDVwUKJKaOfT4d4DN80WtQ8eIq9FRl/QpaP7mbgHa', 'active', '2026-05-31 18:58:21.244105+00', '');
INSERT INTO public.users VALUES (14, 3, 'Mhs Waitlist Test', '240101099', '240101099@mhs.unesa.ac.id', '$2a$10$NTxcYf4GFP3VNXCzwTfJ0eoR67WTJfHuqsWeDxzSr6aKHLOp0tfRi', 'active', '2026-05-31 18:58:20.958083+00', '');
INSERT INTO public.users VALUES (16, 3, 'Test User', '123456', 'testuser@mhs.unesa.ac.id', '$argon2id$v=19$m=65536,t=1,p=16$U1spq4d+QlPQED8jSYbr5A$a8TGvXY/UmPTsPquOPxnaUUohAZngZTy9Jghuzu791A', 'active', '2026-05-31 20:07:20.747181+00', '');
INSERT INTO public.users VALUES (28, 5, '909dd32233', '123567897892833', '123456y26337@mhs.unesa.ac.id', '$2a$10$FQbgS/Z9bt5TUbdePibfmeiEihTT5n95VMcphsyO84Npd.Mom0oxW', 'active', '2026-06-01 22:05:16.027885+00', '');
INSERT INTO public.users VALUES (31, 2, 'tes332', '00000200011', '120000@gmail.com', '$2a$10$XJfF7QuB8P9QP.1h1FN04OxeIiGMBICT9de.0gG6t3pQaFVdCfpme', 'blocked', '2026-06-02 00:18:06.937091+00', '');
INSERT INTO public.users VALUES (30, 5, 'tes33', '0000000011', '10000@gmail.com', '$2a$10$YnxQC2/J72rgHl2XYlfYQ.YHyvIMVNgumi5tG33YiIGvoyKwEv3jC', 'blocked', '2026-06-02 00:17:51.427871+00', '');
INSERT INTO public.users VALUES (17, 3, 'Budi Mahasiswa', '240101004', 'budi240101004@mhs.unesa.ac.id', '$2a$10$ggve317iuabw7V.nUovALuTUKXzWiQkkK8bmLzUbT/9nRg7yheSlK', 'active', '2026-05-31 20:56:51.901621+00', '');
INSERT INTO public.users VALUES (32, 3, 'tes331', '000002001011', '120000@mhs.unesa.ac.id', '$2a$10$U2B1azJNYcJ3EFOW7XhJi.rLWBqqeCzSIIHbjlsZi9xRZ5X5K07Jm', 'active', '2026-06-02 00:18:31.225872+00', '');
INSERT INTO public.users VALUES (1, 1, 'Admin Sistem', '', 'admin@parkir.com', '$2a$10$rTHcv2g/Xqk8Zcyq.QhqFOdlV/zlhrr8AH5S0biwokA0FG9JpDrJS', 'active', '2026-05-11 14:08:56.730393+00', NULL);
INSERT INTO public.users VALUES (8, 3, 'Mahasiswa QA Test', '240101004', '240101004@mhs.unesa.ac.id', '$2a$10$6Wmk3oitvhia7XRjJgF09eZnU9SQZzTonxV/2v7hyGb.H.ghBE3r2', 'active', '2026-05-31 18:56:08.961619+00', '');
INSERT INTO public.users VALUES (18, 3, 'Rayhan', '25051204323', '25051204323@mhs.unesa.ac.id', '$2a$10$eNFvcG0p0Jm3zEihahH0Ku.KoScIp6LgHtu7.MhI.7PkiqPeIIpxK', 'active', '2026-06-01 05:35:29.008246+00', NULL);
INSERT INTO public.users VALUES (19, 5, 'tes tamu', '123456', '123@gmail.com', '$2a$10$YxtB.5vCGoDPmRzNLNq9SeFe8y3WxSCV70.8wNDrdWx6Omlcde5YO', 'active', '2026-06-01 07:48:06.611045+00', '');
INSERT INTO public.users VALUES (42, 2, 'tes', '909090', '909090@gmail.com', '$2a$10$MXYIQOpTilcQYuHQS4MO6OqoMVIVRMLC1Ce.6EX16GrxVRSUmgdQ.', 'active', '2026-06-04 04:04:52.053743+00', '');
INSERT INTO public.users VALUES (4, 3, 'rahmat', '25051204306', '25051204306@mhs.unesa.ac.id', '$2a$10$k9hkLdsS/V452ecdU9lyoub/7tzmbqNUQdbImfhGJJWnf0Hxj/G4K', 'active', '2026-05-11 14:58:00.876973+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/avatars/4_1780367084968.png');
INSERT INTO public.users VALUES (6, 6, 'Petugas Lapangan', '', 'petugas@parkir.com', '$2a$10$KU8O.gLGlPsyMVS/qd9JB.Z9HTywUXkZCf/uUDIOLcO6xMlWs8Lya', 'active', '2026-05-31 03:43:31.967585+00', '');
INSERT INTO public.users VALUES (35, 3, 'fajri', '12345678910', '1234578910@mhs.unesa.ac.id', '$2a$10$TeO1bszRwfWtonGwJVLUWeyApVZCi9p697J0bn5IMH.lhM804bdzW', 'active', '2026-06-02 06:22:57.866068+00', '');
INSERT INTO public.users VALUES (23, 4, 'ts staff', '11111', '1234@umesa.ac.id', '$2a$10$fw2wEZmkUX0oLlpNfH.Yku3QTf5xCf7FYJjMRaTFw5YpnIPWRFzku', 'active', '2026-06-01 15:23:15.49548+00', '');
INSERT INTO public.users VALUES (36, 2, 'tes dosan', '11223344', '11223344@gmail.com', '$2a$10$eyYsfWUe/dn2aE7XCmAvJumU5p.1JjDNAnt4YL4KV5.iskWdYYYgG', 'active', '2026-06-02 06:26:26.527114+00', '');
INSERT INTO public.users VALUES (24, 5, 'hmm', '9999999', '99@gmail.com', '$2a$10$6B7FzisPPF1r5iHNcAIGde7w2EbjvYTFap3XZ53wUASNEV..BlDEi', 'active', '2026-06-01 21:57:25.499252+00', '');
INSERT INTO public.users VALUES (25, 2, 'tttt', '12356789', '123456@gmail.com', '$2a$10$4C/N4VroNijN4i1TQDNI3.qjhpjkWWYh9rwNtSl23Uw2iXCsz50Wm', 'active', '2026-06-01 22:03:06.581585+00', '');
INSERT INTO public.users VALUES (37, 2, 'Agus Salim', '085748647612', '085748647612@mhs.unesa.ac.id', '$2a$10$cq8XCXLoip.npKtc8Xv.5u5UxpSZzJQQhE2i.qNzB6RZxzxwqTk7i', 'active', '2026-06-02 06:27:49.22162+00', '');
INSERT INTO public.users VALUES (26, 3, '909dd', '123567897898', '123456y67@gmail.com', '$2a$10$Ek1A.jK9bZ3K43HlLhMbTusLm1BcEFdJBRkkuRO0FgcbkVAmzba8W', 'active', '2026-06-01 22:03:57.30772+00', '');
INSERT INTO public.users VALUES (27, 3, '909dd333', '12356789789833', '123456y6337@mhs.unesa.ac.id', '$2a$10$I9TeY3GKRSGF5PhYaIQYGeCEDcROhpKusTJXoiEp2mT5dTN.4mdse', 'active', '2026-06-01 22:04:30.805555+00', '');
INSERT INTO public.users VALUES (38, 3, 'Rendy Syahputra Riyadi', '25051204307', '25051204307@mhs.unesa.ac.id', '$2a$10$Z1A0hcg9GBzUL0CQYqxTKuRlpGnVgQweuZJa5fdxCjzT.jKPG.C6.', 'active', '2026-06-02 06:46:24.017812+00', '');
INSERT INTO public.users VALUES (29, 4, 'tes', '00000000', '00000@gmail.com', '$2a$10$VLXDWsmKFWmVpogUqe9hZ.seMQlFLCsSKD0FmrCnTGIijv1b7ob2C', 'active', '2026-06-02 00:17:31.152593+00', '');
INSERT INTO public.users VALUES (33, 4, 'Muhammad Kadhimas', '25051204302', '25051204302@mhs.unesa.ac.id', '$2a$10$h0oQ7MYDhCqCZcLz5feLMOfPkgWOQdfyOaYW6nV26l4fc8m2W/qO6', 'active', '2026-06-02 01:01:37.941899+00', '');
INSERT INTO public.users VALUES (3, 2, 'Dr. Hendra', '', 'hendra@univ.ac.id', '$2a$10$7xVUL4vrzOLCmvhrpdG8f.VDUjfVTb5XbPqwMBFLyw0sX1f6HdTjO', 'active', '2026-05-11 14:08:57.037413+00', NULL);
INSERT INTO public.users VALUES (21, 2, 'tes dosen', '11111', '11111@umesa.ac.id', '$2a$10$12RQyTOAzVKRkVcDiBGJFuzrT2HDlVlE9TuLGY2q6/7A9KT4Ij7/y', 'active', '2026-06-01 15:21:41.364951+00', '');
INSERT INTO public.users VALUES (20, 6, 'Bapak Sukamto (Petugas)', '', 'petugas.lapangan@parkirkampus.ac.id', '$2a$10$j7okAMaXHo7Kk.pIujUB8OIQpPM4gygm2vdFzDcDV6mrQI7PwYk.u', 'active', '2026-06-01 12:35:56.982618+00', '');
INSERT INTO public.users VALUES (39, 3, 'Rayhan', '112233', '123123@mhs.unesa.ac.id', '$2a$10$NtaQg5HRem5w23LUDzyngeKfG2wCciAALH2vKd8F0NYoV9hqlXPTO', 'active', '2026-06-02 06:46:59.555251+00', '');
INSERT INTO public.users VALUES (40, 5, 'tamu', '12345678', 'testamu@gmail.com', '$2a$10$6RDDb4Ht0oXBgq7OSICUBu4B2tmphDzMcjrT.e91He0dwHq.d0Zfu', 'active', '2026-06-02 06:50:51.034579+00', '');
INSERT INTO public.users VALUES (41, 5, 'tamu', '191919', '1919@gmail.com', '$2a$10$hQpsvqP.jrh1Ht3z7WoQSuyf3sU1BcnS8t.O67ThdEU3g69q8b3ou', 'active', '2026-06-02 06:53:16.446154+00', '');
INSERT INTO public.users VALUES (2, 3, 'Budi Santoso', '', 'budi@univ.ac.id', '$2a$10$7xVUL4vrzOLCmvhrpdG8f.VDUjfVTb5XbPqwMBFLyw0sX1f6HdTjO', 'active', '2026-05-11 14:08:56.895732+00', NULL);
INSERT INTO public.users VALUES (43, 2, 'tesdosen', '987654321', '987654321@gmail.com', '$2a$10$s.mJ35E92zDj7jJ/1JWLbOk44zKKC.xwbRFhJ/LY8t1muUxYwps8y', 'active', '2026-06-04 04:58:53.904796+00', '');
INSERT INTO public.users VALUES (44, 4, 'staff1', '12345678', 'staff1@gmail.com', '$2a$10$erhFh4T5tC2tU/tqJ1vx/.8F59S5BLPnFgSnyZ2cYNNCb/Socy4Oi', 'active', '2026-06-04 05:57:09.800782+00', 'https://zickrkvvpptchymushfb.supabase.co/storage/v1/object/public/avatars/avatars/44_1780552980832.jpg');


--
-- TOC entry 3937 (class 0 OID 17642)
-- Dependencies: 391
-- Data for Name: waiting_lists; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3931 (class 0 OID 17590)
-- Dependencies: 385
-- Data for Name: zona_parkirs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.zona_parkirs VALUES (3, 'Zone C', 'Parkir Belakang', 30, 'motor', 'active', 30, 10, 0, 0, 0, 0, 0, 0);
INSERT INTO public.zona_parkirs VALUES (6, 'gg', 'j', 50, 'motor', 'active', 10, 10, 0, 0, 0, 0, 0, 0);
INSERT INTO public.zona_parkirs VALUES (4, 'ZONA D', 'Parkir Samping Kiri', 20, 'motor', 'active', 20, 10, 0, 0, 0, 0, 0, 0);
INSERT INTO public.zona_parkirs VALUES (5, 'ZONA E', 'Parkir Samping Kanan', 25, 'motor', 'active', 25, 10, 0, 0, 0, 0, 0, 0);
INSERT INTO public.zona_parkirs VALUES (7, 'hh', 'ee', 50, 'motor', 'active', 0, 0, 0, 0, 0, 0, 0, 0);
INSERT INTO public.zona_parkirs VALUES (8, 'ga', 'g', 50, 'motor', 'active', 0, 0, 0, 0, 0, 0, 0, 0);
INSERT INTO public.zona_parkirs VALUES (1, 'Zone A', 'Parkir Utama Depan', 50, 'motor', 'active', 50, 10, 0, 0, 0, 0, 0, 0);
INSERT INTO public.zona_parkirs VALUES (2, 'Zone B', 'Parkir Gedung B', 40, 'motor', 'active', 40, 10, 0, 0, 0, 0, 0, 0);


--
-- TOC entry 3986 (class 0 OID 0)
-- Dependencies: 394
-- Name: blacklists_id_blacklist_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.blacklists_id_blacklist_seq', 10, true);


--
-- TOC entry 3987 (class 0 OID 0)
-- Dependencies: 382
-- Name: kendaraans_id_kendaraan_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.kendaraans_id_kendaraan_seq', 43, true);


--
-- TOC entry 3988 (class 0 OID 0)
-- Dependencies: 396
-- Name: laporan_petugases_id_laporan_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.laporan_petugases_id_laporan_seq', 23, true);


--
-- TOC entry 3989 (class 0 OID 0)
-- Dependencies: 392
-- Name: penaltis_id_penalti_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.penaltis_id_penalti_seq', 30, true);


--
-- TOC entry 3990 (class 0 OID 0)
-- Dependencies: 398
-- Name: qr_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.qr_codes_id_seq', 5, true);


--
-- TOC entry 3991 (class 0 OID 0)
-- Dependencies: 378
-- Name: roles_id_role_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_role_seq', 1, false);


--
-- TOC entry 3992 (class 0 OID 0)
-- Dependencies: 386
-- Name: slot_parkirs_id_slot_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.slot_parkirs_id_slot_seq', 18, true);


--
-- TOC entry 3993 (class 0 OID 0)
-- Dependencies: 388
-- Name: transaksis_id_transaksi_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transaksis_id_transaksi_seq', 46, true);


--
-- TOC entry 3994 (class 0 OID 0)
-- Dependencies: 380
-- Name: users_id_user_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_user_seq', 44, true);


--
-- TOC entry 3995 (class 0 OID 0)
-- Dependencies: 390
-- Name: waiting_lists_id_waiting_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.waiting_lists_id_waiting_seq', 1, false);


--
-- TOC entry 3996 (class 0 OID 0)
-- Dependencies: 384
-- Name: zona_parkirs_id_zona_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zona_parkirs_id_zona_seq', 8, true);


--
-- TOC entry 3757 (class 2606 OID 17679)
-- Name: blacklists blacklists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blacklists
    ADD CONSTRAINT blacklists_pkey PRIMARY KEY (id_blacklist);


--
-- TOC entry 3739 (class 2606 OID 17581)
-- Name: kendaraans kendaraans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kendaraans
    ADD CONSTRAINT kendaraans_pkey PRIMARY KEY (id_kendaraan);


--
-- TOC entry 3759 (class 2606 OID 25463)
-- Name: laporan_petugases laporan_petugases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.laporan_petugases
    ADD CONSTRAINT laporan_petugases_pkey PRIMARY KEY (id_laporan);


--
-- TOC entry 3755 (class 2606 OID 17664)
-- Name: penaltis penaltis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.penaltis
    ADD CONSTRAINT penaltis_pkey PRIMARY KEY (id_penalti);


--
-- TOC entry 3761 (class 2606 OID 25478)
-- Name: qr_codes qr_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes
    ADD CONSTRAINT qr_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 3731 (class 2606 OID 17555)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_role);


--
-- TOC entry 3746 (class 2606 OID 17612)
-- Name: slot_parkirs slot_parkirs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slot_parkirs
    ADD CONSTRAINT slot_parkirs_pkey PRIMARY KEY (id_slot);


--
-- TOC entry 3751 (class 2606 OID 17625)
-- Name: transaksis transaksis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaksis
    ADD CONSTRAINT transaksis_pkey PRIMARY KEY (id_transaksi);


--
-- TOC entry 3741 (class 2606 OID 17583)
-- Name: kendaraans uni_kendaraans_nomor_polisi; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kendaraans
    ADD CONSTRAINT uni_kendaraans_nomor_polisi UNIQUE (nomor_polisi);


--
-- TOC entry 3763 (class 2606 OID 25480)
-- Name: qr_codes uni_qr_codes_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes
    ADD CONSTRAINT uni_qr_codes_code UNIQUE (code);


--
-- TOC entry 3733 (class 2606 OID 17557)
-- Name: roles uni_roles_nama_role; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT uni_roles_nama_role UNIQUE (nama_role);


--
-- TOC entry 3736 (class 2606 OID 17567)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id_user);


--
-- TOC entry 3753 (class 2606 OID 17647)
-- Name: waiting_lists waiting_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waiting_lists
    ADD CONSTRAINT waiting_lists_pkey PRIMARY KEY (id_waiting);


--
-- TOC entry 3743 (class 2606 OID 17600)
-- Name: zona_parkirs zona_parkirs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zona_parkirs
    ADD CONSTRAINT zona_parkirs_pkey PRIMARY KEY (id_zona);


--
-- TOC entry 3737 (class 1259 OID 25579)
-- Name: idx_kendaraans_deleted_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_kendaraans_deleted_at ON public.kendaraans USING btree (deleted_at);


--
-- TOC entry 3744 (class 1259 OID 17739)
-- Name: idx_slot_parkirs_zona_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_slot_parkirs_zona_status ON public.slot_parkirs USING btree (id_zona, status);


--
-- TOC entry 3747 (class 1259 OID 17742)
-- Name: idx_transaksis_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaksis_status ON public.transaksis USING btree (status);


--
-- TOC entry 3748 (class 1259 OID 17740)
-- Name: idx_transaksis_user_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaksis_user_status ON public.transaksis USING btree (id_user, status);


--
-- TOC entry 3749 (class 1259 OID 25654)
-- Name: idx_transaksis_waktu_masuk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaksis_waktu_masuk ON public.transaksis USING btree (waktu_masuk DESC);


--
-- TOC entry 3734 (class 1259 OID 17573)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 3773 (class 2606 OID 17680)
-- Name: blacklists fk_blacklists_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blacklists
    ADD CONSTRAINT fk_blacklists_user FOREIGN KEY (id_user) REFERENCES public.users(id_user);


--
-- TOC entry 3774 (class 2606 OID 25464)
-- Name: laporan_petugases fk_laporan_petugases_petugas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.laporan_petugases
    ADD CONSTRAINT fk_laporan_petugases_petugas FOREIGN KEY (id_petugas) REFERENCES public.users(id_user);


--
-- TOC entry 3772 (class 2606 OID 17665)
-- Name: penaltis fk_penaltis_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.penaltis
    ADD CONSTRAINT fk_penaltis_user FOREIGN KEY (id_user) REFERENCES public.users(id_user);


--
-- TOC entry 3766 (class 2606 OID 17613)
-- Name: slot_parkirs fk_slot_parkirs_zona; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slot_parkirs
    ADD CONSTRAINT fk_slot_parkirs_zona FOREIGN KEY (id_zona) REFERENCES public.zona_parkirs(id_zona);


--
-- TOC entry 3767 (class 2606 OID 17631)
-- Name: transaksis fk_transaksis_kendaraan; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaksis
    ADD CONSTRAINT fk_transaksis_kendaraan FOREIGN KEY (id_kendaraan) REFERENCES public.kendaraans(id_kendaraan);


--
-- TOC entry 3768 (class 2606 OID 17636)
-- Name: transaksis fk_transaksis_slot; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaksis
    ADD CONSTRAINT fk_transaksis_slot FOREIGN KEY (id_slot) REFERENCES public.slot_parkirs(id_slot);


--
-- TOC entry 3769 (class 2606 OID 17626)
-- Name: transaksis fk_transaksis_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaksis
    ADD CONSTRAINT fk_transaksis_user FOREIGN KEY (id_user) REFERENCES public.users(id_user);


--
-- TOC entry 3765 (class 2606 OID 17584)
-- Name: kendaraans fk_users_kendaraans; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kendaraans
    ADD CONSTRAINT fk_users_kendaraans FOREIGN KEY (id_user) REFERENCES public.users(id_user);


--
-- TOC entry 3764 (class 2606 OID 17568)
-- Name: users fk_users_role; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_role FOREIGN KEY (id_role) REFERENCES public.roles(id_role);


--
-- TOC entry 3770 (class 2606 OID 17653)
-- Name: waiting_lists fk_waiting_lists_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waiting_lists
    ADD CONSTRAINT fk_waiting_lists_user FOREIGN KEY (id_user) REFERENCES public.users(id_user);


--
-- TOC entry 3771 (class 2606 OID 17648)
-- Name: waiting_lists fk_waiting_lists_zona; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waiting_lists
    ADD CONSTRAINT fk_waiting_lists_zona FOREIGN KEY (id_zona) REFERENCES public.zona_parkirs(id_zona);


--
-- TOC entry 3952 (class 0 OID 0)
-- Dependencies: 44
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- TOC entry 3953 (class 0 OID 0)
-- Dependencies: 395
-- Name: TABLE blacklists; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.blacklists TO anon;
GRANT ALL ON TABLE public.blacklists TO authenticated;
GRANT ALL ON TABLE public.blacklists TO service_role;


--
-- TOC entry 3955 (class 0 OID 0)
-- Dependencies: 394
-- Name: SEQUENCE blacklists_id_blacklist_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.blacklists_id_blacklist_seq TO anon;
GRANT ALL ON SEQUENCE public.blacklists_id_blacklist_seq TO authenticated;
GRANT ALL ON SEQUENCE public.blacklists_id_blacklist_seq TO service_role;


--
-- TOC entry 3956 (class 0 OID 0)
-- Dependencies: 383
-- Name: TABLE kendaraans; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.kendaraans TO anon;
GRANT ALL ON TABLE public.kendaraans TO authenticated;
GRANT ALL ON TABLE public.kendaraans TO service_role;


--
-- TOC entry 3958 (class 0 OID 0)
-- Dependencies: 382
-- Name: SEQUENCE kendaraans_id_kendaraan_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.kendaraans_id_kendaraan_seq TO anon;
GRANT ALL ON SEQUENCE public.kendaraans_id_kendaraan_seq TO authenticated;
GRANT ALL ON SEQUENCE public.kendaraans_id_kendaraan_seq TO service_role;


--
-- TOC entry 3959 (class 0 OID 0)
-- Dependencies: 397
-- Name: TABLE laporan_petugases; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.laporan_petugases TO anon;
GRANT ALL ON TABLE public.laporan_petugases TO authenticated;
GRANT ALL ON TABLE public.laporan_petugases TO service_role;


--
-- TOC entry 3961 (class 0 OID 0)
-- Dependencies: 396
-- Name: SEQUENCE laporan_petugases_id_laporan_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.laporan_petugases_id_laporan_seq TO anon;
GRANT ALL ON SEQUENCE public.laporan_petugases_id_laporan_seq TO authenticated;
GRANT ALL ON SEQUENCE public.laporan_petugases_id_laporan_seq TO service_role;


--
-- TOC entry 3962 (class 0 OID 0)
-- Dependencies: 393
-- Name: TABLE penaltis; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.penaltis TO anon;
GRANT ALL ON TABLE public.penaltis TO authenticated;
GRANT ALL ON TABLE public.penaltis TO service_role;


--
-- TOC entry 3964 (class 0 OID 0)
-- Dependencies: 392
-- Name: SEQUENCE penaltis_id_penalti_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.penaltis_id_penalti_seq TO anon;
GRANT ALL ON SEQUENCE public.penaltis_id_penalti_seq TO authenticated;
GRANT ALL ON SEQUENCE public.penaltis_id_penalti_seq TO service_role;


--
-- TOC entry 3965 (class 0 OID 0)
-- Dependencies: 399
-- Name: TABLE qr_codes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.qr_codes TO anon;
GRANT ALL ON TABLE public.qr_codes TO authenticated;
GRANT ALL ON TABLE public.qr_codes TO service_role;


--
-- TOC entry 3967 (class 0 OID 0)
-- Dependencies: 398
-- Name: SEQUENCE qr_codes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.qr_codes_id_seq TO anon;
GRANT ALL ON SEQUENCE public.qr_codes_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.qr_codes_id_seq TO service_role;


--
-- TOC entry 3968 (class 0 OID 0)
-- Dependencies: 379
-- Name: TABLE roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.roles TO anon;
GRANT ALL ON TABLE public.roles TO authenticated;
GRANT ALL ON TABLE public.roles TO service_role;


--
-- TOC entry 3970 (class 0 OID 0)
-- Dependencies: 378
-- Name: SEQUENCE roles_id_role_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.roles_id_role_seq TO anon;
GRANT ALL ON SEQUENCE public.roles_id_role_seq TO authenticated;
GRANT ALL ON SEQUENCE public.roles_id_role_seq TO service_role;


--
-- TOC entry 3971 (class 0 OID 0)
-- Dependencies: 387
-- Name: TABLE slot_parkirs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.slot_parkirs TO anon;
GRANT ALL ON TABLE public.slot_parkirs TO authenticated;
GRANT ALL ON TABLE public.slot_parkirs TO service_role;


--
-- TOC entry 3973 (class 0 OID 0)
-- Dependencies: 386
-- Name: SEQUENCE slot_parkirs_id_slot_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.slot_parkirs_id_slot_seq TO anon;
GRANT ALL ON SEQUENCE public.slot_parkirs_id_slot_seq TO authenticated;
GRANT ALL ON SEQUENCE public.slot_parkirs_id_slot_seq TO service_role;


--
-- TOC entry 3974 (class 0 OID 0)
-- Dependencies: 389
-- Name: TABLE transaksis; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.transaksis TO anon;
GRANT ALL ON TABLE public.transaksis TO authenticated;
GRANT ALL ON TABLE public.transaksis TO service_role;


--
-- TOC entry 3976 (class 0 OID 0)
-- Dependencies: 388
-- Name: SEQUENCE transaksis_id_transaksi_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.transaksis_id_transaksi_seq TO anon;
GRANT ALL ON SEQUENCE public.transaksis_id_transaksi_seq TO authenticated;
GRANT ALL ON SEQUENCE public.transaksis_id_transaksi_seq TO service_role;


--
-- TOC entry 3977 (class 0 OID 0)
-- Dependencies: 381
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO anon;
GRANT ALL ON TABLE public.users TO authenticated;
GRANT ALL ON TABLE public.users TO service_role;


--
-- TOC entry 3979 (class 0 OID 0)
-- Dependencies: 380
-- Name: SEQUENCE users_id_user_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.users_id_user_seq TO anon;
GRANT ALL ON SEQUENCE public.users_id_user_seq TO authenticated;
GRANT ALL ON SEQUENCE public.users_id_user_seq TO service_role;


--
-- TOC entry 3980 (class 0 OID 0)
-- Dependencies: 391
-- Name: TABLE waiting_lists; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.waiting_lists TO anon;
GRANT ALL ON TABLE public.waiting_lists TO authenticated;
GRANT ALL ON TABLE public.waiting_lists TO service_role;


--
-- TOC entry 3982 (class 0 OID 0)
-- Dependencies: 390
-- Name: SEQUENCE waiting_lists_id_waiting_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.waiting_lists_id_waiting_seq TO anon;
GRANT ALL ON SEQUENCE public.waiting_lists_id_waiting_seq TO authenticated;
GRANT ALL ON SEQUENCE public.waiting_lists_id_waiting_seq TO service_role;


--
-- TOC entry 3983 (class 0 OID 0)
-- Dependencies: 385
-- Name: TABLE zona_parkirs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.zona_parkirs TO anon;
GRANT ALL ON TABLE public.zona_parkirs TO authenticated;
GRANT ALL ON TABLE public.zona_parkirs TO service_role;


--
-- TOC entry 3985 (class 0 OID 0)
-- Dependencies: 384
-- Name: SEQUENCE zona_parkirs_id_zona_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.zona_parkirs_id_zona_seq TO anon;
GRANT ALL ON SEQUENCE public.zona_parkirs_id_zona_seq TO authenticated;
GRANT ALL ON SEQUENCE public.zona_parkirs_id_zona_seq TO service_role;


--
-- TOC entry 2459 (class 826 OID 16494)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- TOC entry 2460 (class 826 OID 16495)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- TOC entry 2458 (class 826 OID 16493)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- TOC entry 2462 (class 826 OID 16497)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- TOC entry 2457 (class 826 OID 16492)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- TOC entry 2461 (class 826 OID 16496)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


-- Completed on 2026-06-05 10:16:07

--
-- PostgreSQL database dump complete
--

