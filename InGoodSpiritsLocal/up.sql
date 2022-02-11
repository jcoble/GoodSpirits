--
-- PostgreSQL database dump
--

-- Dumped from database version 12.7 (Debian 12.7-1.pgdg100+1)
-- Dumped by pg_dump version 14.1

-- Started on 2022-02-10 17:25:07

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

DROP DATABASE postgres;
--
-- TOC entry 3572 (class 1262 OID 13408)
-- Name: postgres; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.UTF-8';


ALTER DATABASE postgres OWNER TO postgres;

\connect postgres

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

--
-- TOC entry 3573 (class 0 OID 0)
-- Dependencies: 3572
-- Name: DATABASE postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- TOC entry 11 (class 2615 OID 16384)
-- Name: auth; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 16529)
-- Name: hdb_catalog; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA hdb_catalog;


ALTER SCHEMA hdb_catalog OWNER TO postgres;

--
-- TOC entry 12 (class 2615 OID 16385)
-- Name: storage; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA storage;


ALTER SCHEMA storage OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 16423)
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- TOC entry 3574 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- TOC entry 3 (class 3079 OID 16386)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 3575 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 826 (class 1247 OID 16694)
-- Name: email; Type: DOMAIN; Schema: auth; Owner: postgres
--

CREATE DOMAIN auth.email AS public.citext
	CONSTRAINT email_check CHECK ((VALUE OPERATOR(public.~) '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'::public.citext));


ALTER DOMAIN auth.email OWNER TO postgres;

--
-- TOC entry 368 (class 1255 OID 16692)
-- Name: set_current_timestamp_updated_at(); Type: FUNCTION; Schema: auth; Owner: postgres
--

CREATE FUNCTION auth.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := new;
  _new. "updated_at" = now();
  RETURN _new;
END;
$$;


ALTER FUNCTION auth.set_current_timestamp_updated_at() OWNER TO postgres;

--
-- TOC entry 355 (class 1255 OID 16530)
-- Name: gen_hasura_uuid(); Type: FUNCTION; Schema: hdb_catalog; Owner: postgres
--

CREATE FUNCTION hdb_catalog.gen_hasura_uuid() RETURNS uuid
    LANGUAGE sql
    AS $$select gen_random_uuid()$$;


ALTER FUNCTION hdb_catalog.gen_hasura_uuid() OWNER TO postgres;

--
-- TOC entry 370 (class 1255 OID 18673)
-- Name: function_create_employee_row(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.function_create_employee_row() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
INSERT INTO
    public."Employees" ("UserId")
VALUES
    (NEW.id);
RETURN NULL;
-- result is ignored since this is an AFTER trigger
end;
$$;


ALTER FUNCTION public.function_create_employee_row() OWNER TO postgres;

--
-- TOC entry 369 (class 1255 OID 18638)
-- Name: maint_sales_summary_bytime(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.maint_sales_summary_bytime() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ DECLARE delta_time_key integer;

delta_amount_sold numeric(15, 2);

delta_units_sold numeric(12);

delta_amount_cost numeric(15, 2);

delta_amount_purchased numeric(15, 2);

delta_units_purchased integer;

delta_units_changed integer;

BEGIN -- Work out the increment/decrement amount(s).
IF (TG_OP = 'DELETE') THEN delta_time_key = OLD.time_key;

delta_amount_sold = -1 * OLD.amount_sold;

delta_units_sold = -1 * OLD.units_sold;

delta_amount_cost = -1 * OLD.amount_cost;

delta_amount_purchased = -1 * OLD.amount_purchased;

delta_units_purchased = -1 * OLD.units_purchased;

delta_units_changed = -1 * OLD.units_on_hand;

ELSIF (TG_OP = 'UPDATE') THEN -- forbid updates that change the time_key -
-- (probably not too onerous, as DELETE + INSERT is how most
-- changes will be made).
IF (OLD.time_key != NEW.time_key) THEN RAISE EXCEPTION 'Update of time_key : % -> % not allowed',
OLD.time_key,
NEW.time_key;

END IF;

delta_time_key = OLD.time_key;

delta_amount_sold = NEW.amount_sold - OLD.amount_sold;

delta_units_sold = NEW.units_sold - OLD.units_sold;

delta_amount_cost = NEW.amount_cost - OLD.amount_cost;

delta_amount_purchased = NEW.amount_purchased - OLD.amount_purchased;

IF (NEW.units_sold > 0) THEN delta_units_changed = NEW.units_sold - NEW.units_sold;

ELSE delta_units_changed = -1 * (NEW.units_purchased - NEW.units_purchased);

END IF;

ELSIF (TG_OP = 'INSERT') THEN delta_time_key = NEW.time_key;

delta_amount_sold = NEW.amount_sold;

delta_units_sold = NEW.units_sold;

delta_amount_cost = NEW.amount_cost;

delta_amount_purchased = NEW.amount_purchased;

delta_units_purchased = NEW.delta_units_purchased;

IF (NEW.units_sold > 0) THEN delta_units_changed = NEW.units_sold;

ELSE delta_units_changed = -1 * NEW.units_purchased;

END IF;

END IF;

-- Insert or update the summary row with the new values.
< < insert_update > > LOOP
UPDATE
    sales_summary_bytime
SET
    amount_sold = amount_sold + delta_amount_sold,
    units_sold = units_sold + delta_units_sold,
    amount_cost = amount_cost + delta_amount_cost,
    amount_purchased = amount_purchased + delta_amount_purchased,
    units_purchased = units_purchased + delta_units_purchased,
    delta_units_on_hand = units_on_hand + delta_units_changed
WHERE
    time_key = delta_time_key;

EXIT insert_update
WHEN found;

BEGIN
INSERT INTO
    sales_summary_bytime (
        time_key,
        amount_sold,
        units_sold,
        amount_cost,
        amount_purchased,
        units_purchased,
        units_on_hand
    )
VALUES
    (
        delta_time_key,
        delta_amount_sold,
        delta_units_sold,
        delta_amount_cost,
        delta_amount_purchased,
        delta_units_purchaed,
        delta_units_on_hand
    );

EXIT insert_update;

EXCEPTION
WHEN UNIQUE_VIOLATION THEN -- do nothing
END;

END LOOP insert_update;

RETURN NULL;

END;

$$;


ALTER FUNCTION public.maint_sales_summary_bytime() OWNER TO postgres;

--
-- TOC entry 366 (class 1255 OID 16645)
-- Name: protect_default_bucket_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.protect_default_bucket_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.ID = 'default' THEN
    RAISE EXCEPTION 'Can not delete default bucket';
  END IF;
  RETURN OLD;
END;
$$;


ALTER FUNCTION public.protect_default_bucket_delete() OWNER TO postgres;

--
-- TOC entry 367 (class 1255 OID 16646)
-- Name: protect_default_bucket_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.protect_default_bucket_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.ID = 'default' AND NEW.ID <> 'default' THEN
    RAISE EXCEPTION 'Can not rename default bucket';
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.protect_default_bucket_update() OWNER TO postgres;

--
-- TOC entry 364 (class 1255 OID 16528)
-- Name: set_current_timestamp_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  _new record;
begin
  _new := new;
  _new. "updated_at" = now();
  return _new;
end;
$$;


ALTER FUNCTION public.set_current_timestamp_updated_at() OWNER TO postgres;

--
-- TOC entry 365 (class 1255 OID 16644)
-- Name: set_current_timestamp_updated_at(); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := new;
  _new. "updated_at" = now();
  RETURN _new;
END;
$$;


ALTER FUNCTION storage.set_current_timestamp_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 16684)
-- Name: migrations; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE auth.migrations OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16769)
-- Name: provider_requests; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.provider_requests (
    id uuid NOT NULL,
    redirect_url text NOT NULL
);


ALTER TABLE auth.provider_requests OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16747)
-- Name: providers; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.providers (
    id text NOT NULL
);


ALTER TABLE auth.providers OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16755)
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.refresh_tokens (
    refresh_token uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE auth.refresh_tokens OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16761)
-- Name: roles; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.roles (
    role text NOT NULL
);


ALTER TABLE auth.roles OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16696)
-- Name: user_providers; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.user_providers (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    access_token text NOT NULL,
    refresh_token text,
    provider_id text NOT NULL,
    provider_user_id text NOT NULL
);


ALTER TABLE auth.user_providers OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16711)
-- Name: user_roles; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.user_roles (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    role text NOT NULL
);


ALTER TABLE auth.user_roles OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16723)
-- Name: users; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.users (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone,
    disabled boolean DEFAULT false NOT NULL,
    display_name text DEFAULT ''::text NOT NULL,
    avatar_url text DEFAULT ''::text NOT NULL,
    locale character varying(2) NOT NULL,
    email auth.email,
    phone_number text,
    password_hash text,
    email_verified boolean DEFAULT false NOT NULL,
    phone_number_verified boolean DEFAULT false NOT NULL,
    new_email auth.email,
    otp_method_last_used text,
    otp_hash text,
    otp_hash_expires_at timestamp with time zone DEFAULT now() NOT NULL,
    default_role text DEFAULT 'user'::text NOT NULL,
    is_anonymous boolean DEFAULT false NOT NULL,
    totp_secret text,
    active_mfa_type text,
    ticket text,
    ticket_expires_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT active_mfa_types_check CHECK (((active_mfa_type = 'totp'::text) OR (active_mfa_type = 'sms'::text)))
);


ALTER TABLE auth.users OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 16554)
-- Name: hdb_action_log; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_action_log (
    id uuid DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    action_name text,
    input_payload jsonb NOT NULL,
    request_headers jsonb NOT NULL,
    session_variables jsonb NOT NULL,
    response_payload jsonb,
    errors jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    response_received_at timestamp with time zone,
    status text NOT NULL,
    CONSTRAINT hdb_action_log_status_check CHECK ((status = ANY (ARRAY['created'::text, 'processing'::text, 'completed'::text, 'error'::text])))
);


ALTER TABLE hdb_catalog.hdb_action_log OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16580)
-- Name: hdb_cron_event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_cron_event_invocation_logs (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    event_id text,
    status integer,
    request json,
    response json,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE hdb_catalog.hdb_cron_event_invocation_logs OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16565)
-- Name: hdb_cron_events; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_cron_events (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    trigger_name text NOT NULL,
    scheduled_time timestamp with time zone NOT NULL,
    status text DEFAULT 'scheduled'::text NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    next_retry_at timestamp with time zone,
    CONSTRAINT valid_status CHECK ((status = ANY (ARRAY['scheduled'::text, 'locked'::text, 'delivered'::text, 'error'::text, 'dead'::text])))
);


ALTER TABLE hdb_catalog.hdb_cron_events OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16543)
-- Name: hdb_metadata; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_metadata (
    id integer NOT NULL,
    metadata json NOT NULL,
    resource_version integer DEFAULT 1 NOT NULL
);


ALTER TABLE hdb_catalog.hdb_metadata OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 16610)
-- Name: hdb_scheduled_event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_scheduled_event_invocation_logs (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    event_id text,
    status integer,
    request json,
    response json,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE hdb_catalog.hdb_scheduled_event_invocation_logs OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 16596)
-- Name: hdb_scheduled_events; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_scheduled_events (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    webhook_conf json NOT NULL,
    scheduled_time timestamp with time zone NOT NULL,
    retry_conf json,
    payload json,
    header_conf json,
    status text DEFAULT 'scheduled'::text NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    next_retry_at timestamp with time zone,
    comment text,
    CONSTRAINT valid_status CHECK ((status = ANY (ARRAY['scheduled'::text, 'locked'::text, 'delivered'::text, 'error'::text, 'dead'::text])))
);


ALTER TABLE hdb_catalog.hdb_scheduled_events OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16625)
-- Name: hdb_schema_notifications; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_schema_notifications (
    id integer NOT NULL,
    notification json NOT NULL,
    resource_version integer DEFAULT 1 NOT NULL,
    instance_id uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT hdb_schema_notifications_id_check CHECK ((id = 1))
);


ALTER TABLE hdb_catalog.hdb_schema_notifications OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16531)
-- Name: hdb_version; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_version (
    hasura_uuid uuid DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    version text NOT NULL,
    upgraded_on timestamp with time zone NOT NULL,
    cli_state jsonb DEFAULT '{}'::jsonb NOT NULL,
    console_state jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE hdb_catalog.hdb_version OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 18190)
-- Name: Addresses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Addresses" (
    "Id" integer NOT NULL,
    "Line1" text,
    "Line2" text,
    "City" text,
    "Zip" text,
    "Provence" text,
    "State" text,
    "CountryId" integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public."Addresses" OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 18198)
-- Name: Addresses_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Addresses_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Addresses_Id_seq" OWNER TO postgres;

--
-- TOC entry 3576 (class 0 OID 0)
-- Dependencies: 227
-- Name: Addresses_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Addresses_Id_seq" OWNED BY public."Addresses"."Id";


--
-- TOC entry 228 (class 1259 OID 18200)
-- Name: Assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Assignments" (
    "Id" bigint NOT NULL,
    "EmployeeEventId" bigint,
    "JobSeriesCodeId" bigint,
    "CategoryId" bigint,
    "Status" integer,
    "Notes" text,
    deleted_at timestamp with time zone
);


ALTER TABLE public."Assignments" OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 18206)
-- Name: Assignments_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Assignments_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Assignments_Id_seq" OWNER TO postgres;

--
-- TOC entry 3577 (class 0 OID 0)
-- Dependencies: 229
-- Name: Assignments_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Assignments_Id_seq" OWNED BY public."Assignments"."Id";


--
-- TOC entry 230 (class 1259 OID 18208)
-- Name: Awards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Awards" (
    "Id" integer NOT NULL,
    "EventId" bigint NOT NULL,
    "Name" text,
    "Description" text,
    deleted_at timestamp with time zone
);


ALTER TABLE public."Awards" OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 18214)
-- Name: Awards_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Awards_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Awards_Id_seq" OWNER TO postgres;

--
-- TOC entry 3578 (class 0 OID 0)
-- Dependencies: 231
-- Name: Awards_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Awards_Id_seq" OWNED BY public."Awards"."Id";


--
-- TOC entry 232 (class 1259 OID 18216)
-- Name: Brand; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Brand" (
    "Id" integer NOT NULL,
    "Title" text,
    "Summary" text
);


ALTER TABLE public."Brand" OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 18222)
-- Name: Categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Categories" (
    "Id" bigint NOT NULL,
    "CategoryTypeId" integer,
    "Title" text,
    "Description" text,
    deleted_at timestamp with time zone
);


ALTER TABLE public."Categories" OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 18228)
-- Name: Categories_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Categories_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Categories_Id_seq" OWNER TO postgres;

--
-- TOC entry 3579 (class 0 OID 0)
-- Dependencies: 234
-- Name: Categories_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Categories_Id_seq" OWNED BY public."Categories"."Id";


--
-- TOC entry 235 (class 1259 OID 18230)
-- Name: Countries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Countries" (
    "Id" integer NOT NULL,
    "Name" text,
    "Abbreviation" text
);


ALTER TABLE public."Countries" OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 18236)
-- Name: Countries_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Countries_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Countries_Id_seq" OWNER TO postgres;

--
-- TOC entry 3580 (class 0 OID 0)
-- Dependencies: 236
-- Name: Countries_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Countries_Id_seq" OWNED BY public."Countries"."Id";


--
-- TOC entry 237 (class 1259 OID 18238)
-- Name: Customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Customer" (
    "Id" uuid DEFAULT public.gen_random_uuid() NOT NULL,
    "AddressId" bigint,
    "CustomerTypeCodeId" integer,
    "EmailAddress" text,
    "FirstName" text,
    "LastName" text,
    "DateBecameCustomer" timestamp with time zone,
    "DateLastPurchase" timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    deleted_at timestamp with time zone,
    "StoreId" bigint
);


ALTER TABLE public."Customer" OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 18247)
-- Name: CustomerTypeCode; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CustomerTypeCode" (
    "Id" integer NOT NULL,
    "CustomerTypeCode" text,
    "CustomerTypeDescription" text
);


ALTER TABLE public."CustomerTypeCode" OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 18253)
-- Name: CustomerTypeCodeId_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."CustomerTypeCodeId_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."CustomerTypeCodeId_Id_seq" OWNER TO postgres;

--
-- TOC entry 3581 (class 0 OID 0)
-- Dependencies: 239
-- Name: CustomerTypeCodeId_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."CustomerTypeCodeId_Id_seq" OWNED BY public."CustomerTypeCode"."Id";


--
-- TOC entry 240 (class 1259 OID 18255)
-- Name: EmployeeEvents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."EmployeeEvents" (
    "Id" bigint NOT NULL,
    "EmployeeId" bigint,
    "StartDate" timestamp with time zone,
    "EndDate" timestamp without time zone,
    "Notes" text,
    deleted_at timestamp with time zone
);


ALTER TABLE public."EmployeeEvents" OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 18261)
-- Name: EmployeeEvents_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."EmployeeEvents_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."EmployeeEvents_Id_seq" OWNER TO postgres;

--
-- TOC entry 3582 (class 0 OID 0)
-- Dependencies: 241
-- Name: EmployeeEvents_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."EmployeeEvents_Id_seq" OWNED BY public."EmployeeEvents"."Id";


--
-- TOC entry 242 (class 1259 OID 18263)
-- Name: Employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Employees" (
    "Id" bigint NOT NULL,
    "AddressId" bigint,
    "StoreId" bigint,
    "UserId" uuid NOT NULL
);


ALTER TABLE public."Employees" OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 18266)
-- Name: Employees_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Employees_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Employees_Id_seq" OWNER TO postgres;

--
-- TOC entry 3583 (class 0 OID 0)
-- Dependencies: 243
-- Name: Employees_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Employees_Id_seq" OWNED BY public."Employees"."Id";


--
-- TOC entry 244 (class 1259 OID 18268)
-- Name: JobSeriesCode; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."JobSeriesCode" (
    "Id" bigint NOT NULL,
    "Title" text,
    "Description" text,
    deleted_at timestamp with time zone
);


ALTER TABLE public."JobSeriesCode" OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 18274)
-- Name: JobSeriesCode_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."JobSeriesCode_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."JobSeriesCode_Id_seq" OWNER TO postgres;

--
-- TOC entry 3584 (class 0 OID 0)
-- Dependencies: 245
-- Name: JobSeriesCode_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."JobSeriesCode_Id_seq" OWNED BY public."JobSeriesCode"."Id";


--
-- TOC entry 246 (class 1259 OID 18276)
-- Name: Order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Order" (
    "Id" bigint NOT NULL,
    "SupplierId" bigint NOT NULL,
    "ProductId" bigint NOT NULL,
    "Status" smallint,
    "SubTotal" money,
    "ItemDiscount" money,
    "Tax" money,
    "Shipping" money,
    "Total" money,
    "Promo" text,
    "Discount" money,
    "GrandTotal" money,
    "StoreId" bigint,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    deleted_at timestamp with time zone,
    "CustomerId" uuid
);


ALTER TABLE public."Order" OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 18284)
-- Name: OrderItem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OrderItem" (
    "Id" bigint NOT NULL,
    "OrderId" bigint,
    "ProductId" bigint,
    "Name" text,
    "Description" text,
    "Price" money,
    "Discount" money,
    "Quantity" integer,
    "Tax" money,
    "SubTotal" money,
    "Total" money,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    deleted_at timestamp with time zone
);


ALTER TABLE public."OrderItem" OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 18292)
-- Name: OrderItem_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."OrderItem_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."OrderItem_Id_seq" OWNER TO postgres;

--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 248
-- Name: OrderItem_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."OrderItem_Id_seq" OWNED BY public."OrderItem"."Id";


--
-- TOC entry 249 (class 1259 OID 18294)
-- Name: Order_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Order_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Order_Id_seq" OWNER TO postgres;

--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 249
-- Name: Order_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Order_Id_seq" OWNED BY public."Order"."Id";


--
-- TOC entry 250 (class 1259 OID 18296)
-- Name: ProductType; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ProductType" (
    "Id" integer NOT NULL,
    "Name" text,
    "Description" text,
    deleted_at timestamp with time zone
);


ALTER TABLE public."ProductType" OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 18302)
-- Name: ProductType_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ProductType_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."ProductType_Id_seq" OWNER TO postgres;

--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 251
-- Name: ProductType_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ProductType_Id_seq" OWNED BY public."ProductType"."Id";


--
-- TOC entry 252 (class 1259 OID 18304)
-- Name: Product_Prices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Product_Prices" (
    "ProductId" bigint NOT NULL,
    "StoreId" bigint,
    "DateFrom" timestamp with time zone,
    "Price" money
);


ALTER TABLE public."Product_Prices" OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 18307)
-- Name: Product_Supplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Product_Supplier" (
    "Id" bigint NOT NULL,
    "StoreId" bigint,
    "ProductId" bigint,
    "SupplierId" bigint
);


ALTER TABLE public."Product_Supplier" OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 18310)
-- Name: Product_Supplier_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Product_Supplier_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Product_Supplier_Id_seq" OWNER TO postgres;

--
-- TOC entry 3588 (class 0 OID 0)
-- Dependencies: 254
-- Name: Product_Supplier_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Product_Supplier_Id_seq" OWNED BY public."Product_Supplier"."Id";


--
-- TOC entry 255 (class 1259 OID 18312)
-- Name: Products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Products" (
    "Id" bigint NOT NULL,
    "PromotionId" integer,
    "ProductTypeId" integer,
    "DailyInvLevelsId" bigint,
    "ProductSupplierId" bigint,
    "ProductsInPurchaseId" bigint,
    "PriceId" bigint,
    "CategoryId" bigint,
    "Name" text,
    "Description" text,
    "NationalMaxPrice" money,
    "NationalMinPrice" money,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    deleted_at timestamp with time zone,
    "BrandId" integer
);


ALTER TABLE public."Products" OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 18320)
-- Name: Store_Mangr_Employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Store_Mangr_Employee" (
    "Id" bigint NOT NULL,
    "StoreId" bigint,
    "EmployeeId" bigint
);


ALTER TABLE public."Store_Mangr_Employee" OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 18323)
-- Name: Store_Mangr_Employee_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Store_Mangr_Employee_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Store_Mangr_Employee_Id_seq" OWNER TO postgres;

--
-- TOC entry 3589 (class 0 OID 0)
-- Dependencies: 257
-- Name: Store_Mangr_Employee_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Store_Mangr_Employee_Id_seq" OWNED BY public."Store_Mangr_Employee"."Id";


--
-- TOC entry 258 (class 1259 OID 18325)
-- Name: Stores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Stores" (
    "Id" bigint NOT NULL,
    "AreaId" integer,
    "StoreMngEmployeeId" bigint,
    "AddressId" bigint,
    "Name" text,
    "PhoneNumber" text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    deleted_at timestamp with time zone
);


ALTER TABLE public."Stores" OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 18333)
-- Name: Stores_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Stores_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Stores_Id_seq" OWNER TO postgres;

--
-- TOC entry 3590 (class 0 OID 0)
-- Dependencies: 259
-- Name: Stores_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Stores_Id_seq" OWNED BY public."Stores"."Id";


--
-- TOC entry 260 (class 1259 OID 18335)
-- Name: Stores_Product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Stores_Product" (
    "Id" bigint NOT NULL,
    "StoreId" bigint,
    "ProductId" bigint
);


ALTER TABLE public."Stores_Product" OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 18338)
-- Name: Stores_Product_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Stores_Product_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Stores_Product_Id_seq" OWNER TO postgres;

--
-- TOC entry 3591 (class 0 OID 0)
-- Dependencies: 261
-- Name: Stores_Product_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Stores_Product_Id_seq" OWNED BY public."Stores_Product"."Id";


--
-- TOC entry 262 (class 1259 OID 18340)
-- Name: Supplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Supplier" (
    "Id" bigint NOT NULL,
    "Name" text,
    "AddressId" bigint,
    "Description" text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    deleted_at timestamp with time zone
);


ALTER TABLE public."Supplier" OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 18348)
-- Name: Supplier_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Supplier_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Supplier_Id_seq" OWNER TO postgres;

--
-- TOC entry 3592 (class 0 OID 0)
-- Dependencies: 263
-- Name: Supplier_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Supplier_Id_seq" OWNED BY public."Supplier"."Id";


--
-- TOC entry 264 (class 1259 OID 18350)
-- Name: TransactionType; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."TransactionType" (
    "Id" integer NOT NULL,
    "TransactionType" text,
    "Description" text
);


ALTER TABLE public."TransactionType" OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 18356)
-- Name: Transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Transactions" (
    "Id" bigint NOT NULL,
    "StoreId" bigint,
    "ProductId" bigint,
    "SupplierId" bigint,
    "OrderLineId" bigint,
    "PurchaseLineId" bigint,
    "TransactionType" integer,
    "Cost" money,
    "TransactionDate" timestamp without time zone,
    "Quantity" integer,
    "CustomerId" uuid,
    time_key bigint NOT NULL
);


ALTER TABLE public."Transactions" OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 18359)
-- Name: Transactions_Id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Transactions_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Transactions_Id_seq" OWNER TO postgres;

--
-- TOC entry 3593 (class 0 OID 0)
-- Dependencies: 266
-- Name: Transactions_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Transactions_Id_seq" OWNED BY public."Transactions"."Id";


--
-- TOC entry 268 (class 1259 OID 18365)
-- Name: sales_purchase_fact; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sales_purchase_fact (
    time_key integer NOT NULL,
    product_key integer NOT NULL,
    amount_sold numeric(12,2) NOT NULL,
    units_sold integer NOT NULL,
    amount_cost numeric(12,2) NOT NULL,
    amount_purchased numeric(12,2) NOT NULL,
    units_purchased integer NOT NULL
);


ALTER TABLE public.sales_purchase_fact OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 18369)
-- Name: sales_summary_bytime; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sales_summary_bytime (
    time_key integer NOT NULL,
    amount_sold numeric(15,2) NOT NULL,
    units_sold numeric(12,0) NOT NULL,
    amount_cost numeric(15,2) NOT NULL,
    amount_purchased numeric(15,2) NOT NULL,
    units_purchased integer NOT NULL,
    units_on_hand numeric(12,0) NOT NULL
);


ALTER TABLE public.sales_summary_bytime OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 18361)
-- Name: time_dimension; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.time_dimension (
    time_key integer NOT NULL,
    day_of_week integer NOT NULL,
    day_of_month integer NOT NULL,
    month integer NOT NULL,
    quarter integer NOT NULL,
    year integer NOT NULL
);


ALTER TABLE public.time_dimension OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16647)
-- Name: buckets; Type: TABLE; Schema: storage; Owner: postgres
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    download_expiration integer DEFAULT 30 NOT NULL,
    min_upload_file_size integer DEFAULT 1 NOT NULL,
    max_upload_file_size integer DEFAULT 50000000 NOT NULL,
    cache_control text DEFAULT 'max-age=3600'::text,
    presigned_urls_enabled boolean DEFAULT true NOT NULL
);


ALTER TABLE storage.buckets OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16662)
-- Name: files; Type: TABLE; Schema: storage; Owner: postgres
--

CREATE TABLE storage.files (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    bucket_id text DEFAULT 'default'::text NOT NULL,
    name text,
    size integer,
    mime_type text,
    etag text,
    is_uploaded boolean DEFAULT false,
    uploaded_by_user_id uuid
);


ALTER TABLE storage.files OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16636)
-- Name: migrations; Type: TABLE; Schema: storage; Owner: postgres
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE storage.migrations OWNER TO postgres;

--
-- TOC entry 3222 (class 2604 OID 18373)
-- Name: Addresses Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Addresses" ALTER COLUMN "Id" SET DEFAULT nextval('public."Addresses_Id_seq"'::regclass);


--
-- TOC entry 3223 (class 2604 OID 18374)
-- Name: Assignments Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Assignments" ALTER COLUMN "Id" SET DEFAULT nextval('public."Assignments_Id_seq"'::regclass);


--
-- TOC entry 3224 (class 2604 OID 18375)
-- Name: Awards Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Awards" ALTER COLUMN "Id" SET DEFAULT nextval('public."Awards_Id_seq"'::regclass);


--
-- TOC entry 3225 (class 2604 OID 18376)
-- Name: Categories Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories" ALTER COLUMN "Id" SET DEFAULT nextval('public."Categories_Id_seq"'::regclass);


--
-- TOC entry 3226 (class 2604 OID 18377)
-- Name: Countries Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Countries" ALTER COLUMN "Id" SET DEFAULT nextval('public."Countries_Id_seq"'::regclass);


--
-- TOC entry 3230 (class 2604 OID 18378)
-- Name: CustomerTypeCode Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CustomerTypeCode" ALTER COLUMN "Id" SET DEFAULT nextval('public."CustomerTypeCodeId_Id_seq"'::regclass);


--
-- TOC entry 3231 (class 2604 OID 18379)
-- Name: EmployeeEvents Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."EmployeeEvents" ALTER COLUMN "Id" SET DEFAULT nextval('public."EmployeeEvents_Id_seq"'::regclass);


--
-- TOC entry 3232 (class 2604 OID 18380)
-- Name: Employees Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employees" ALTER COLUMN "Id" SET DEFAULT nextval('public."Employees_Id_seq"'::regclass);


--
-- TOC entry 3233 (class 2604 OID 18381)
-- Name: JobSeriesCode Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JobSeriesCode" ALTER COLUMN "Id" SET DEFAULT nextval('public."JobSeriesCode_Id_seq"'::regclass);


--
-- TOC entry 3236 (class 2604 OID 18382)
-- Name: Order Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order" ALTER COLUMN "Id" SET DEFAULT nextval('public."Order_Id_seq"'::regclass);


--
-- TOC entry 3239 (class 2604 OID 18383)
-- Name: OrderItem Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem" ALTER COLUMN "Id" SET DEFAULT nextval('public."OrderItem_Id_seq"'::regclass);


--
-- TOC entry 3240 (class 2604 OID 18384)
-- Name: ProductType Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductType" ALTER COLUMN "Id" SET DEFAULT nextval('public."ProductType_Id_seq"'::regclass);


--
-- TOC entry 3241 (class 2604 OID 18385)
-- Name: Product_Supplier Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product_Supplier" ALTER COLUMN "Id" SET DEFAULT nextval('public."Product_Supplier_Id_seq"'::regclass);


--
-- TOC entry 3244 (class 2604 OID 18386)
-- Name: Store_Mangr_Employee Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Store_Mangr_Employee" ALTER COLUMN "Id" SET DEFAULT nextval('public."Store_Mangr_Employee_Id_seq"'::regclass);


--
-- TOC entry 3247 (class 2604 OID 18387)
-- Name: Stores Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stores" ALTER COLUMN "Id" SET DEFAULT nextval('public."Stores_Id_seq"'::regclass);


--
-- TOC entry 3248 (class 2604 OID 18388)
-- Name: Stores_Product Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stores_Product" ALTER COLUMN "Id" SET DEFAULT nextval('public."Stores_Product_Id_seq"'::regclass);


--
-- TOC entry 3251 (class 2604 OID 18389)
-- Name: Supplier Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Supplier" ALTER COLUMN "Id" SET DEFAULT nextval('public."Supplier_Id_seq"'::regclass);


--
-- TOC entry 3252 (class 2604 OID 18390)
-- Name: Transactions Id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions" ALTER COLUMN "Id" SET DEFAULT nextval('public."Transactions_Id_seq"'::regclass);


--
-- TOC entry 3285 (class 2606 OID 16691)
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- TOC entry 3287 (class 2606 OID 16689)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3311 (class 2606 OID 16776)
-- Name: provider_requests provider_requests_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.provider_requests
    ADD CONSTRAINT provider_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 3305 (class 2606 OID 16754)
-- Name: providers providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.providers
    ADD CONSTRAINT providers_pkey PRIMARY KEY (id);


--
-- TOC entry 3307 (class 2606 OID 16760)
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (refresh_token);


--
-- TOC entry 3309 (class 2606 OID 16768)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role);


--
-- TOC entry 3289 (class 2606 OID 16706)
-- Name: user_providers user_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_providers
    ADD CONSTRAINT user_providers_pkey PRIMARY KEY (id);


--
-- TOC entry 3291 (class 2606 OID 16710)
-- Name: user_providers user_providers_provider_id_provider_user_id_key; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_providers
    ADD CONSTRAINT user_providers_provider_id_provider_user_id_key UNIQUE (provider_id, provider_user_id);


--
-- TOC entry 3293 (class 2606 OID 16708)
-- Name: user_providers user_providers_user_id_provider_id_key; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_providers
    ADD CONSTRAINT user_providers_user_id_provider_id_key UNIQUE (user_id, provider_id);


--
-- TOC entry 3295 (class 2606 OID 16720)
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 3297 (class 2606 OID 16722)
-- Name: user_roles user_roles_user_id_role_key; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_roles
    ADD CONSTRAINT user_roles_user_id_role_key UNIQUE (user_id, role);


--
-- TOC entry 3299 (class 2606 OID 16744)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3301 (class 2606 OID 16746)
-- Name: users users_phone_number_key; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_number_key UNIQUE (phone_number);


--
-- TOC entry 3303 (class 2606 OID 16742)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3261 (class 2606 OID 16564)
-- Name: hdb_action_log hdb_action_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_action_log
    ADD CONSTRAINT hdb_action_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3268 (class 2606 OID 16589)
-- Name: hdb_cron_event_invocation_logs hdb_cron_event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_cron_event_invocation_logs
    ADD CONSTRAINT hdb_cron_event_invocation_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 3264 (class 2606 OID 16577)
-- Name: hdb_cron_events hdb_cron_events_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_cron_events
    ADD CONSTRAINT hdb_cron_events_pkey PRIMARY KEY (id);


--
-- TOC entry 3257 (class 2606 OID 16551)
-- Name: hdb_metadata hdb_metadata_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_metadata
    ADD CONSTRAINT hdb_metadata_pkey PRIMARY KEY (id);


--
-- TOC entry 3259 (class 2606 OID 16553)
-- Name: hdb_metadata hdb_metadata_resource_version_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_metadata
    ADD CONSTRAINT hdb_metadata_resource_version_key UNIQUE (resource_version);


--
-- TOC entry 3273 (class 2606 OID 16619)
-- Name: hdb_scheduled_event_invocation_logs hdb_scheduled_event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_scheduled_event_invocation_logs
    ADD CONSTRAINT hdb_scheduled_event_invocation_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 3271 (class 2606 OID 16608)
-- Name: hdb_scheduled_events hdb_scheduled_events_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_scheduled_events
    ADD CONSTRAINT hdb_scheduled_events_pkey PRIMARY KEY (id);


--
-- TOC entry 3275 (class 2606 OID 16635)
-- Name: hdb_schema_notifications hdb_schema_notifications_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_schema_notifications
    ADD CONSTRAINT hdb_schema_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 3255 (class 2606 OID 16541)
-- Name: hdb_version hdb_version_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_version
    ADD CONSTRAINT hdb_version_pkey PRIMARY KEY (hasura_uuid);


--
-- TOC entry 3313 (class 2606 OID 18392)
-- Name: Addresses Addresses_Id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Addresses"
    ADD CONSTRAINT "Addresses_Id_key" UNIQUE ("Id");


--
-- TOC entry 3315 (class 2606 OID 18394)
-- Name: Addresses Addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Addresses"
    ADD CONSTRAINT "Addresses_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3317 (class 2606 OID 18396)
-- Name: Assignments Assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Assignments"
    ADD CONSTRAINT "Assignments_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3319 (class 2606 OID 18398)
-- Name: Awards Awards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Awards"
    ADD CONSTRAINT "Awards_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3321 (class 2606 OID 18400)
-- Name: Brand Brand_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Brand"
    ADD CONSTRAINT "Brand_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3323 (class 2606 OID 18402)
-- Name: Categories Categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Categories"
    ADD CONSTRAINT "Categories_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3325 (class 2606 OID 18404)
-- Name: Countries Countries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Countries"
    ADD CONSTRAINT "Countries_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3329 (class 2606 OID 18406)
-- Name: CustomerTypeCode CustomerTypeCodeId_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CustomerTypeCode"
    ADD CONSTRAINT "CustomerTypeCodeId_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3327 (class 2606 OID 18408)
-- Name: Customer Customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3331 (class 2606 OID 18410)
-- Name: EmployeeEvents EmployeeEvents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."EmployeeEvents"
    ADD CONSTRAINT "EmployeeEvents_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3333 (class 2606 OID 18412)
-- Name: Employees Employees_Id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employees"
    ADD CONSTRAINT "Employees_Id_key" UNIQUE ("Id");


--
-- TOC entry 3335 (class 2606 OID 18414)
-- Name: Employees Employees_UserId_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employees"
    ADD CONSTRAINT "Employees_UserId_key" UNIQUE ("UserId");


--
-- TOC entry 3337 (class 2606 OID 18416)
-- Name: Employees Employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employees"
    ADD CONSTRAINT "Employees_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3339 (class 2606 OID 18418)
-- Name: JobSeriesCode JobSeriesCode_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JobSeriesCode"
    ADD CONSTRAINT "JobSeriesCode_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3345 (class 2606 OID 18420)
-- Name: OrderItem OrderItem_Id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_Id_key" UNIQUE ("Id");


--
-- TOC entry 3347 (class 2606 OID 18422)
-- Name: OrderItem OrderItem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3341 (class 2606 OID 18424)
-- Name: Order Order_Id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_Id_key" UNIQUE ("Id");


--
-- TOC entry 3343 (class 2606 OID 18426)
-- Name: Order Order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3349 (class 2606 OID 18428)
-- Name: ProductType ProductType_Id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductType"
    ADD CONSTRAINT "ProductType_Id_key" UNIQUE ("Id");


--
-- TOC entry 3351 (class 2606 OID 18430)
-- Name: ProductType ProductType_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductType"
    ADD CONSTRAINT "ProductType_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3353 (class 2606 OID 18432)
-- Name: Product_Prices Product_Prices_ProductId_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product_Prices"
    ADD CONSTRAINT "Product_Prices_ProductId_key" UNIQUE ("ProductId");


--
-- TOC entry 3355 (class 2606 OID 18434)
-- Name: Product_Prices Product_Prices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product_Prices"
    ADD CONSTRAINT "Product_Prices_pkey" PRIMARY KEY ("ProductId");


--
-- TOC entry 3357 (class 2606 OID 18436)
-- Name: Product_Supplier Product_Supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product_Supplier"
    ADD CONSTRAINT "Product_Supplier_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3359 (class 2606 OID 18438)
-- Name: Products Products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3361 (class 2606 OID 18440)
-- Name: Store_Mangr_Employee Store_Mangr_Employee_Id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Store_Mangr_Employee"
    ADD CONSTRAINT "Store_Mangr_Employee_Id_key" UNIQUE ("Id");


--
-- TOC entry 3363 (class 2606 OID 18442)
-- Name: Store_Mangr_Employee Store_Mangr_Employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Store_Mangr_Employee"
    ADD CONSTRAINT "Store_Mangr_Employee_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3367 (class 2606 OID 18444)
-- Name: Stores_Product Stores_Product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stores_Product"
    ADD CONSTRAINT "Stores_Product_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3365 (class 2606 OID 18446)
-- Name: Stores Stores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stores"
    ADD CONSTRAINT "Stores_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3369 (class 2606 OID 18448)
-- Name: Supplier Supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Supplier"
    ADD CONSTRAINT "Supplier_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3371 (class 2606 OID 18666)
-- Name: TransactionType TransactionType_Id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TransactionType"
    ADD CONSTRAINT "TransactionType_Id_key" UNIQUE ("Id");


--
-- TOC entry 3373 (class 2606 OID 18450)
-- Name: TransactionType TransactionType_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TransactionType"
    ADD CONSTRAINT "TransactionType_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3375 (class 2606 OID 18452)
-- Name: Transactions Transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_pkey" PRIMARY KEY ("Id");


--
-- TOC entry 3281 (class 2606 OID 16661)
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- TOC entry 3283 (class 2606 OID 16674)
-- Name: files files_pkey; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- TOC entry 3277 (class 2606 OID 16643)
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- TOC entry 3279 (class 2606 OID 16641)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3266 (class 1259 OID 16595)
-- Name: hdb_cron_event_invocation_event_id; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX hdb_cron_event_invocation_event_id ON hdb_catalog.hdb_cron_event_invocation_logs USING btree (event_id);


--
-- TOC entry 3262 (class 1259 OID 16578)
-- Name: hdb_cron_event_status; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX hdb_cron_event_status ON hdb_catalog.hdb_cron_events USING btree (status);


--
-- TOC entry 3265 (class 1259 OID 16579)
-- Name: hdb_cron_events_unique_scheduled; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE UNIQUE INDEX hdb_cron_events_unique_scheduled ON hdb_catalog.hdb_cron_events USING btree (trigger_name, scheduled_time) WHERE (status = 'scheduled'::text);


--
-- TOC entry 3269 (class 1259 OID 16609)
-- Name: hdb_scheduled_event_status; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX hdb_scheduled_event_status ON hdb_catalog.hdb_scheduled_events USING btree (status);


--
-- TOC entry 3253 (class 1259 OID 16542)
-- Name: hdb_version_one_row; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE UNIQUE INDEX hdb_version_one_row ON hdb_catalog.hdb_version USING btree (((version IS NOT NULL)));


--
-- TOC entry 3377 (class 1259 OID 18368)
-- Name: sales_purchase_fact_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sales_purchase_fact_time ON public.sales_purchase_fact USING btree (time_key);


--
-- TOC entry 3378 (class 1259 OID 18372)
-- Name: sales_summary_bytime_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sales_summary_bytime_key ON public.sales_summary_bytime USING btree (time_key);


--
-- TOC entry 3376 (class 1259 OID 18364)
-- Name: time_dimension_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX time_dimension_key ON public.time_dimension USING btree (time_key);


--
-- TOC entry 3430 (class 2620 OID 16807)
-- Name: user_providers set_auth_user_providers_updated_at; Type: TRIGGER; Schema: auth; Owner: postgres
--

CREATE TRIGGER set_auth_user_providers_updated_at BEFORE UPDATE ON auth.user_providers FOR EACH ROW EXECUTE FUNCTION auth.set_current_timestamp_updated_at();


--
-- TOC entry 3431 (class 2620 OID 16808)
-- Name: users set_auth_users_updated_at; Type: TRIGGER; Schema: auth; Owner: postgres
--

CREATE TRIGGER set_auth_users_updated_at BEFORE UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION auth.set_current_timestamp_updated_at();


--
-- TOC entry 3432 (class 2620 OID 18674)
-- Name: users user_insert_trigger; Type: TRIGGER; Schema: auth; Owner: postgres
--

CREATE TRIGGER user_insert_trigger AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.function_create_employee_row();


--
-- TOC entry 3440 (class 2620 OID 18639)
-- Name: sales_purchase_fact maint_sales_summary_bytime; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER maint_sales_summary_bytime AFTER INSERT OR DELETE OR UPDATE ON public.sales_purchase_fact FOR EACH ROW EXECUTE FUNCTION public.maint_sales_summary_bytime();


--
-- TOC entry 3433 (class 2620 OID 18640)
-- Name: Addresses set_public_Addresses_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "set_public_Addresses_updated_at" BEFORE UPDATE ON public."Addresses" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 3594 (class 0 OID 0)
-- Dependencies: 3433
-- Name: TRIGGER "set_public_Addresses_updated_at" ON "Addresses"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "set_public_Addresses_updated_at" ON public."Addresses" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 3434 (class 2620 OID 18641)
-- Name: Customer set_public_Customer_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "set_public_Customer_updated_at" BEFORE UPDATE ON public."Customer" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 3595 (class 0 OID 0)
-- Dependencies: 3434
-- Name: TRIGGER "set_public_Customer_updated_at" ON "Customer"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "set_public_Customer_updated_at" ON public."Customer" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 3436 (class 2620 OID 18642)
-- Name: OrderItem set_public_OrderItem_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "set_public_OrderItem_updated_at" BEFORE UPDATE ON public."OrderItem" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 3596 (class 0 OID 0)
-- Dependencies: 3436
-- Name: TRIGGER "set_public_OrderItem_updated_at" ON "OrderItem"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "set_public_OrderItem_updated_at" ON public."OrderItem" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 3435 (class 2620 OID 18643)
-- Name: Order set_public_Order_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "set_public_Order_updated_at" BEFORE UPDATE ON public."Order" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 3597 (class 0 OID 0)
-- Dependencies: 3435
-- Name: TRIGGER "set_public_Order_updated_at" ON "Order"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "set_public_Order_updated_at" ON public."Order" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 3437 (class 2620 OID 18644)
-- Name: Products set_public_Products_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "set_public_Products_updated_at" BEFORE UPDATE ON public."Products" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 3598 (class 0 OID 0)
-- Dependencies: 3437
-- Name: TRIGGER "set_public_Products_updated_at" ON "Products"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "set_public_Products_updated_at" ON public."Products" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 3438 (class 2620 OID 18645)
-- Name: Stores set_public_Stores_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "set_public_Stores_updated_at" BEFORE UPDATE ON public."Stores" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 3599 (class 0 OID 0)
-- Dependencies: 3438
-- Name: TRIGGER "set_public_Stores_updated_at" ON "Stores"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "set_public_Stores_updated_at" ON public."Stores" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 3439 (class 2620 OID 18646)
-- Name: Supplier set_public_Supplier_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "set_public_Supplier_updated_at" BEFORE UPDATE ON public."Supplier" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 3600 (class 0 OID 0)
-- Dependencies: 3439
-- Name: TRIGGER "set_public_Supplier_updated_at" ON "Supplier"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "set_public_Supplier_updated_at" ON public."Supplier" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 3427 (class 2620 OID 16682)
-- Name: buckets check_default_bucket_delete; Type: TRIGGER; Schema: storage; Owner: postgres
--

CREATE TRIGGER check_default_bucket_delete BEFORE DELETE ON storage.buckets FOR EACH ROW EXECUTE FUNCTION public.protect_default_bucket_delete();


--
-- TOC entry 3428 (class 2620 OID 16683)
-- Name: buckets check_default_bucket_update; Type: TRIGGER; Schema: storage; Owner: postgres
--

CREATE TRIGGER check_default_bucket_update BEFORE UPDATE ON storage.buckets FOR EACH ROW EXECUTE FUNCTION public.protect_default_bucket_update();


--
-- TOC entry 3426 (class 2620 OID 16680)
-- Name: buckets set_storage_buckets_updated_at; Type: TRIGGER; Schema: storage; Owner: postgres
--

CREATE TRIGGER set_storage_buckets_updated_at BEFORE UPDATE ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.set_current_timestamp_updated_at();


--
-- TOC entry 3429 (class 2620 OID 16681)
-- Name: files set_storage_files_updated_at; Type: TRIGGER; Schema: storage; Owner: postgres
--

CREATE TRIGGER set_storage_files_updated_at BEFORE UPDATE ON storage.files FOR EACH ROW EXECUTE FUNCTION storage.set_current_timestamp_updated_at();


--
-- TOC entry 3386 (class 2606 OID 16797)
-- Name: users fk_default_role; Type: FK CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT fk_default_role FOREIGN KEY (default_role) REFERENCES auth.roles(role) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3383 (class 2606 OID 16782)
-- Name: user_providers fk_provider; Type: FK CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_providers
    ADD CONSTRAINT fk_provider FOREIGN KEY (provider_id) REFERENCES auth.providers(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3385 (class 2606 OID 16792)
-- Name: user_roles fk_role; Type: FK CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_roles
    ADD CONSTRAINT fk_role FOREIGN KEY (role) REFERENCES auth.roles(role) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3382 (class 2606 OID 16777)
-- Name: user_providers fk_user; Type: FK CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_providers
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3384 (class 2606 OID 16787)
-- Name: user_roles fk_user; Type: FK CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.user_roles
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3387 (class 2606 OID 16802)
-- Name: refresh_tokens fk_user; Type: FK CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3379 (class 2606 OID 16590)
-- Name: hdb_cron_event_invocation_logs hdb_cron_event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_cron_event_invocation_logs
    ADD CONSTRAINT hdb_cron_event_invocation_logs_event_id_fkey FOREIGN KEY (event_id) REFERENCES hdb_catalog.hdb_cron_events(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3380 (class 2606 OID 16620)
-- Name: hdb_scheduled_event_invocation_logs hdb_scheduled_event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_scheduled_event_invocation_logs
    ADD CONSTRAINT hdb_scheduled_event_invocation_logs_event_id_fkey FOREIGN KEY (event_id) REFERENCES hdb_catalog.hdb_scheduled_events(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3388 (class 2606 OID 18453)
-- Name: Addresses Addresses_CountryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Addresses"
    ADD CONSTRAINT "Addresses_CountryId_fkey" FOREIGN KEY ("CountryId") REFERENCES public."Countries"("Id");


--
-- TOC entry 3389 (class 2606 OID 18463)
-- Name: Assignments Assignments_CategoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Assignments"
    ADD CONSTRAINT "Assignments_CategoryId_fkey" FOREIGN KEY ("CategoryId") REFERENCES public."Categories"("Id");


--
-- TOC entry 3390 (class 2606 OID 18468)
-- Name: Assignments Assignments_EmployeeEventId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Assignments"
    ADD CONSTRAINT "Assignments_EmployeeEventId_fkey" FOREIGN KEY ("EmployeeEventId") REFERENCES public."EmployeeEvents"("Id");


--
-- TOC entry 3391 (class 2606 OID 18473)
-- Name: Assignments Assignments_JobSeriesCodeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Assignments"
    ADD CONSTRAINT "Assignments_JobSeriesCodeId_fkey" FOREIGN KEY ("JobSeriesCodeId") REFERENCES public."JobSeriesCode"("Id");


--
-- TOC entry 3392 (class 2606 OID 18478)
-- Name: Awards Awards_EventId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Awards"
    ADD CONSTRAINT "Awards_EventId_fkey" FOREIGN KEY ("EventId") REFERENCES public."EmployeeEvents"("Id");


--
-- TOC entry 3393 (class 2606 OID 18483)
-- Name: Customer Customer_AddressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_AddressId_fkey" FOREIGN KEY ("AddressId") REFERENCES public."Addresses"("Id");


--
-- TOC entry 3394 (class 2606 OID 18488)
-- Name: Customer Customer_CustomerTypeCodeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_CustomerTypeCodeId_fkey" FOREIGN KEY ("CustomerTypeCodeId") REFERENCES public."CustomerTypeCode"("Id");


--
-- TOC entry 3395 (class 2606 OID 18493)
-- Name: Customer Customer_StoreId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_StoreId_fkey" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id");


--
-- TOC entry 3396 (class 2606 OID 18498)
-- Name: EmployeeEvents EmployeeEvents_EmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."EmployeeEvents"
    ADD CONSTRAINT "EmployeeEvents_EmployeeId_fkey" FOREIGN KEY ("EmployeeId") REFERENCES public."Employees"("Id");


--
-- TOC entry 3397 (class 2606 OID 18503)
-- Name: Employees Employees_AddressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employees"
    ADD CONSTRAINT "Employees_AddressId_fkey" FOREIGN KEY ("AddressId") REFERENCES public."Addresses"("Id");


--
-- TOC entry 3398 (class 2606 OID 18508)
-- Name: Employees Employees_StoreId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employees"
    ADD CONSTRAINT "Employees_StoreId_fkey" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id") ON UPDATE CASCADE;


--
-- TOC entry 3399 (class 2606 OID 18648)
-- Name: Employees Employees_UserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employees"
    ADD CONSTRAINT "Employees_UserId_fkey" FOREIGN KEY ("UserId") REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3404 (class 2606 OID 18513)
-- Name: OrderItem OrderItem_OrderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_OrderId_fkey" FOREIGN KEY ("OrderId") REFERENCES public."Order"("Id");


--
-- TOC entry 3405 (class 2606 OID 18518)
-- Name: OrderItem OrderItem_ProductId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_ProductId_fkey" FOREIGN KEY ("ProductId") REFERENCES public."Products"("Id");


--
-- TOC entry 3400 (class 2606 OID 18523)
-- Name: Order Order_CustomerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_CustomerId_fkey" FOREIGN KEY ("CustomerId") REFERENCES public."Customer"("Id");


--
-- TOC entry 3401 (class 2606 OID 18528)
-- Name: Order Order_ProductId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_ProductId_fkey" FOREIGN KEY ("ProductId") REFERENCES public."Products"("Id");


--
-- TOC entry 3402 (class 2606 OID 18533)
-- Name: Order Order_StoreId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_StoreId_fkey" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id");


--
-- TOC entry 3403 (class 2606 OID 18538)
-- Name: Order Order_SupplierId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_SupplierId_fkey" FOREIGN KEY ("SupplierId") REFERENCES public."Supplier"("Id");


--
-- TOC entry 3406 (class 2606 OID 18543)
-- Name: Product_Prices Product_Prices_StoreId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product_Prices"
    ADD CONSTRAINT "Product_Prices_StoreId_fkey" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id");


--
-- TOC entry 3407 (class 2606 OID 18548)
-- Name: Product_Supplier Product_Supplier_ProductId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product_Supplier"
    ADD CONSTRAINT "Product_Supplier_ProductId_fkey" FOREIGN KEY ("ProductId") REFERENCES public."Products"("Id");


--
-- TOC entry 3408 (class 2606 OID 18553)
-- Name: Product_Supplier Product_Supplier_StoreId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product_Supplier"
    ADD CONSTRAINT "Product_Supplier_StoreId_fkey" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id");


--
-- TOC entry 3409 (class 2606 OID 18558)
-- Name: Product_Supplier Product_Supplier_SupplierId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product_Supplier"
    ADD CONSTRAINT "Product_Supplier_SupplierId_fkey" FOREIGN KEY ("SupplierId") REFERENCES public."Supplier"("Id");


--
-- TOC entry 3410 (class 2606 OID 18563)
-- Name: Products Products_BrandId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_BrandId_fkey" FOREIGN KEY ("BrandId") REFERENCES public."Brand"("Id");


--
-- TOC entry 3411 (class 2606 OID 18568)
-- Name: Products Products_CategoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_CategoryId_fkey" FOREIGN KEY ("CategoryId") REFERENCES public."Categories"("Id");


--
-- TOC entry 3412 (class 2606 OID 18573)
-- Name: Products Products_Id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_Id_fkey" FOREIGN KEY ("Id") REFERENCES public."Product_Prices"("ProductId") ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3413 (class 2606 OID 18578)
-- Name: Products Products_ProductTypeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Products"
    ADD CONSTRAINT "Products_ProductTypeId_fkey" FOREIGN KEY ("ProductTypeId") REFERENCES public."ProductType"("Id") ON UPDATE CASCADE;


--
-- TOC entry 3414 (class 2606 OID 18583)
-- Name: Store_Mangr_Employee Store_Mangr_Employee_EmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Store_Mangr_Employee"
    ADD CONSTRAINT "Store_Mangr_Employee_EmployeeId_fkey" FOREIGN KEY ("EmployeeId") REFERENCES public."Employees"("Id") ON UPDATE CASCADE;


--
-- TOC entry 3415 (class 2606 OID 18588)
-- Name: Store_Mangr_Employee Store_Mangr_Employee_StoreId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Store_Mangr_Employee"
    ADD CONSTRAINT "Store_Mangr_Employee_StoreId_fkey" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id");


--
-- TOC entry 3416 (class 2606 OID 18593)
-- Name: Stores Stores_AddressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stores"
    ADD CONSTRAINT "Stores_AddressId_fkey" FOREIGN KEY ("AddressId") REFERENCES public."Addresses"("Id");


--
-- TOC entry 3417 (class 2606 OID 18598)
-- Name: Stores_Product Stores_Product_ProductId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stores_Product"
    ADD CONSTRAINT "Stores_Product_ProductId_fkey" FOREIGN KEY ("ProductId") REFERENCES public."Products"("Id");


--
-- TOC entry 3418 (class 2606 OID 18603)
-- Name: Stores_Product Stores_Product_StoreId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stores_Product"
    ADD CONSTRAINT "Stores_Product_StoreId_fkey" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id");


--
-- TOC entry 3419 (class 2606 OID 18608)
-- Name: Transactions Transactions_CustomerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_CustomerId_fkey" FOREIGN KEY ("CustomerId") REFERENCES public."Customer"("Id");


--
-- TOC entry 3420 (class 2606 OID 18613)
-- Name: Transactions Transactions_OrderLineId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_OrderLineId_fkey" FOREIGN KEY ("OrderLineId") REFERENCES public."OrderItem"("Id");


--
-- TOC entry 3421 (class 2606 OID 18618)
-- Name: Transactions Transactions_ProductId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_ProductId_fkey" FOREIGN KEY ("ProductId") REFERENCES public."Products"("Id") ON UPDATE CASCADE;


--
-- TOC entry 3422 (class 2606 OID 18623)
-- Name: Transactions Transactions_StoreId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_StoreId_fkey" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id");


--
-- TOC entry 3423 (class 2606 OID 18628)
-- Name: Transactions Transactions_SupplierId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_SupplierId_fkey" FOREIGN KEY ("SupplierId") REFERENCES public."Supplier"("Id");


--
-- TOC entry 3425 (class 2606 OID 18689)
-- Name: Transactions Transactions_TransactionType_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_TransactionType_fkey" FOREIGN KEY ("TransactionType") REFERENCES public."TransactionType"("Id");


--
-- TOC entry 3424 (class 2606 OID 18660)
-- Name: Transactions Transactions_time_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Transactions"
    ADD CONSTRAINT "Transactions_time_key_fkey" FOREIGN KEY (time_key) REFERENCES public.time_dimension(time_key) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3381 (class 2606 OID 16675)
-- Name: files fk_bucket; Type: FK CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.files
    ADD CONSTRAINT fk_bucket FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2022-02-10 17:25:07

--
-- PostgreSQL database dump complete
--

