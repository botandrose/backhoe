--
-- PostgreSQL database dump
--

-- Dumped from database version 14.11 (Ubuntu 14.11-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.11 (Ubuntu 14.11-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: micah
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO micah;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: micah
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    user_id integer,
    body text
);


ALTER TABLE public.posts OWNER TO micah;

--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: micah
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.posts_id_seq OWNER TO micah;

--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: micah
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: micah
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO micah;

--
-- Name: users; Type: TABLE; Schema: public; Owner: micah
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name integer,
    email character varying,
    passhash character varying
);


ALTER TABLE public.users OWNER TO micah;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: micah
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO micah;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: micah
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: micah
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: micah
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: micah
--

INSERT INTO public.ar_internal_metadata (key, value, created_at, updated_at) VALUES ('environment', 'default_env', '2024-03-31 17:39:14.486218', '2024-03-31 17:39:14.486225');


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: micah
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: micah
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: micah
--



--
-- Name: posts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: micah
--

SELECT pg_catalog.setval('public.posts_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: micah
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: micah
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: micah
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: micah
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: micah
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

