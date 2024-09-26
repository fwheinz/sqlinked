--
-- PostgreSQL database dump
--

-- Dumped from database version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)

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
-- Name: accounts; Type: TABLE; Schema: public; Owner: sqlinked
--

CREATE TABLE public.accounts (
    uid integer NOT NULL,
    login text,
    pass text,
    name text,
    lastlogin timestamp without time zone
);


ALTER TABLE public.accounts OWNER TO sqlinked;

--
-- Name: accounts_uid_seq; Type: SEQUENCE; Schema: public; Owner: sqlinked
--

CREATE SEQUENCE public.accounts_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_uid_seq OWNER TO sqlinked;

--
-- Name: accounts_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sqlinked
--

ALTER SEQUENCE public.accounts_uid_seq OWNED BY public.accounts.uid;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: sqlinked
--

CREATE TABLE public.logs (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    action text,
    comment text
);


ALTER TABLE public.logs OWNER TO sqlinked;

--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: sqlinked
--

CREATE SEQUENCE public.logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.logs_id_seq OWNER TO sqlinked;

--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sqlinked
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- Name: accounts uid; Type: DEFAULT; Schema: public; Owner: sqlinked
--

ALTER TABLE ONLY public.accounts ALTER COLUMN uid SET DEFAULT nextval('public.accounts_uid_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: sqlinked
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: sqlinked
--

COPY public.accounts (uid, login, pass, name, lastlogin) FROM stdin;
2	max	1234	Max Mustermann	\N
3	tim	password	Tim Woods	\N
4	tom	313131	Thomas Miller	\N
5	charlie	xoxoxox	Charles Banks	\N
6	anna	ijreosvsd	Anna Hilbert	\N
1	flo	secret	Florian Heinz	\N
7	susan	011235813	Susan Smith	\N
8	karen	23571113	Karen Brick	\N
9	wolfgang	hellowurld!	Wolfgang Henderson	\N
10	paul	00000000	Paul Eriksson	\N
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: sqlinked
--

COPY public.logs (id, ts, action, comment) FROM stdin;
\.


--
-- Name: accounts_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: sqlinked
--

SELECT pg_catalog.setval('public.accounts_uid_seq', 10, true);


--
-- Name: logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sqlinked
--

SELECT pg_catalog.setval('public.logs_id_seq', 432, true);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: sqlinked
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (uid);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: sqlinked
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

