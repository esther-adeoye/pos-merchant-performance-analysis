--
-- PostgreSQL database dump
--

\restrict efrGtDWmoN6nCsojnMYyjj7depSrc3H2fP3motnHriiDtPb1MzAB0xNFuLtDaX0

-- Dumped from database version 17.11
-- Dumped by pg_dump version 17.11

-- Started on 2026-11-22 20:15:38

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
-- TOC entry 2 (class 3079 OID 16658)
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- TOC entry 5308 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 234 (class 1259 OID 17429)
-- Name: crm_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crm_assignments (
    crm_assignment_id bigint NOT NULL,
    merchant_id character varying(20) NOT NULL,
    relationship_manager_id character varying(20) NOT NULL,
    assigned_at timestamp without time zone NOT NULL,
    unassigned_at timestamp without time zone,
    assignment_status character varying(20) NOT NULL,
    CONSTRAINT valid_crm_period CHECK (((unassigned_at IS NULL) OR (unassigned_at > assigned_at)))
);


ALTER TABLE public.crm_assignments OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 17428)
-- Name: crm_assignments_crm_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.crm_assignments ALTER COLUMN crm_assignment_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.crm_assignments_crm_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 227 (class 1259 OID 17373)
-- Name: incident_terminal_impacts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.incident_terminal_impacts (
    impact_id bigint NOT NULL,
    incident_id character varying(20) NOT NULL,
    terminal_id character varying(20) NOT NULL,
    impact_started_at timestamp without time zone NOT NULL,
    impact_ended_at timestamp without time zone,
    impact_type character varying(40) NOT NULL,
    CONSTRAINT valid_impact_period CHECK (((impact_ended_at IS NULL) OR (impact_ended_at >= impact_started_at)))
);


ALTER TABLE public.incident_terminal_impacts OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 17372)
-- Name: incident_terminal_impacts_impact_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.incident_terminal_impacts ALTER COLUMN impact_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.incident_terminal_impacts_impact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 231 (class 1259 OID 17406)
-- Name: merchant_fee_contracts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.merchant_fee_contracts (
    contract_id bigint NOT NULL,
    merchant_id character varying(20) NOT NULL,
    payment_channel character varying(30) NOT NULL,
    effective_from timestamp without time zone NOT NULL,
    effective_to timestamp without time zone,
    percentage_rate numeric(8,6) DEFAULT 0 NOT NULL,
    fixed_fee numeric(18,2) DEFAULT 0 NOT NULL,
    fee_cap numeric(18,2),
    minimum_fee numeric(18,2),
    fee_exempt boolean DEFAULT false NOT NULL,
    contract_status character varying(20) NOT NULL,
    CONSTRAINT valid_contract_period CHECK (((effective_to IS NULL) OR (effective_to > effective_from))),
    CONSTRAINT valid_contract_rates CHECK (((percentage_rate >= (0)::numeric) AND (fixed_fee >= (0)::numeric) AND ((fee_cap IS NULL) OR (fee_cap >= (0)::numeric)) AND ((minimum_fee IS NULL) OR (minimum_fee >= (0)::numeric)) AND ((fee_cap IS NULL) OR (minimum_fee IS NULL) OR (minimum_fee <= fee_cap))))
);


ALTER TABLE public.merchant_fee_contracts OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 17405)
-- Name: merchant_fee_contracts_contract_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.merchant_fee_contracts ALTER COLUMN contract_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.merchant_fee_contracts_contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 218 (class 1259 OID 16631)
-- Name: merchants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.merchants (
    merchant_id character varying(20) NOT NULL,
    merchant_name character varying(150) NOT NULL,
    merchant_segment character varying(30) NOT NULL,
    industry character varying(60),
    state character varying(60) NOT NULL,
    region character varying(30) NOT NULL,
    onboarded_at date NOT NULL,
    account_status character varying(20) NOT NULL,
    merchant_type character varying(30) NOT NULL
);


ALTER TABLE public.merchants OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 17365)
-- Name: operational_incidents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operational_incidents (
    incident_id character varying(20) NOT NULL,
    incident_type character varying(50) NOT NULL,
    severity character varying(20) NOT NULL,
    started_at timestamp without time zone NOT NULL,
    resolved_at timestamp without time zone,
    incident_status character varying(20) NOT NULL,
    assigned_team character varying(60),
    sla_target_minutes integer,
    root_cause character varying(150),
    CONSTRAINT valid_incident_period CHECK (((resolved_at IS NULL) OR (resolved_at >= started_at))),
    CONSTRAINT valid_incident_sla CHECK (((sla_target_minutes IS NULL) OR (sla_target_minutes > 0)))
);


ALTER TABLE public.operational_incidents OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 17423)
-- Name: relationship_managers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.relationship_managers (
    relationship_manager_id character varying(20) NOT NULL,
    manager_name character varying(100) NOT NULL,
    team character varying(60),
    region character varying(30)
);


ALTER TABLE public.relationship_managers OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16642)
-- Name: terminal_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.terminal_assignments (
    assignment_id bigint NOT NULL,
    terminal_id character varying(20) NOT NULL,
    merchant_id character varying(20) NOT NULL,
    assigned_at timestamp without time zone NOT NULL,
    unassigned_at timestamp without time zone,
    assignment_reason character varying(30) NOT NULL,
    CONSTRAINT valid_assignment_period CHECK (((unassigned_at IS NULL) OR (unassigned_at > assigned_at)))
);


ALTER TABLE public.terminal_assignments OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16641)
-- Name: terminal_assignments_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.terminal_assignments ALTER COLUMN assignment_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.terminal_assignments_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 223 (class 1259 OID 17311)
-- Name: terminal_config_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.terminal_config_history (
    config_id bigint NOT NULL,
    terminal_id character varying(20) NOT NULL,
    software_version character varying(30) NOT NULL,
    software_generation character varying(20) NOT NULL,
    eod_enabled boolean NOT NULL,
    effective_from timestamp without time zone NOT NULL,
    effective_to timestamp without time zone,
    CONSTRAINT valid_config_period CHECK (((effective_to IS NULL) OR (effective_to > effective_from)))
);


ALTER TABLE public.terminal_config_history OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 17310)
-- Name: terminal_config_history_config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.terminal_config_history ALTER COLUMN config_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.terminal_config_history_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 219 (class 1259 OID 16636)
-- Name: terminals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.terminals (
    terminal_id character varying(20) NOT NULL,
    terminal_model character varying(50) NOT NULL,
    software_version character varying(30),
    software_generation character varying(20),
    eod_enabled boolean,
    acquired_at date NOT NULL,
    terminal_status character varying(20) NOT NULL
);


ALTER TABLE public.terminals OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 17390)
-- Name: transaction_fee_ledger; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction_fee_ledger (
    fee_entry_id bigint NOT NULL,
    transaction_id character varying(30) NOT NULL,
    entry_at timestamp without time zone NOT NULL,
    entry_type character varying(20) NOT NULL,
    amount numeric(18,2) NOT NULL,
    currency character(3) DEFAULT 'NGN'::bpchar NOT NULL,
    reference_id character varying(40) NOT NULL,
    adjustment_reason character varying(100),
    CONSTRAINT valid_fee_entry_amount CHECK ((amount >= (0)::numeric)),
    CONSTRAINT valid_fee_entry_type CHECK (((entry_type)::text = ANY ((ARRAY['Assessment'::character varying, 'Collection'::character varying, 'Refund'::character varying, 'Adjustment'::character varying])::text[])))
);


ALTER TABLE public.transaction_fee_ledger OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 17389)
-- Name: transaction_fee_ledger_fee_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.transaction_fee_ledger ALTER COLUMN fee_entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.transaction_fee_ledger_fee_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 224 (class 1259 OID 17346)
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    transaction_id character varying(30) NOT NULL,
    merchant_id character varying(20) NOT NULL,
    terminal_id character varying(20),
    transaction_at timestamp without time zone NOT NULL,
    payment_channel character varying(30) NOT NULL,
    amount numeric(18,2) NOT NULL,
    currency character(3) DEFAULT 'NGN'::bpchar NOT NULL,
    transaction_status character varying(20) NOT NULL,
    failure_reason character varying(100),
    provider character varying(50),
    actual_fee numeric(18,2),
    reversed_at timestamp without time zone,
    CONSTRAINT positive_transaction_amount CHECK ((amount > (0)::numeric)),
    CONSTRAINT valid_actual_fee CHECK (((actual_fee IS NULL) OR (actual_fee >= (0)::numeric))),
    CONSTRAINT valid_transaction_status CHECK (((transaction_status)::text = ANY ((ARRAY['Success'::character varying, 'Failed'::character varying, 'Abandoned'::character varying, 'Pending'::character varying])::text[])))
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 17504)
-- Name: vw_channel_performance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_channel_performance AS
 SELECT payment_channel,
    count(*) AS total_transactions,
    sum(amount) FILTER (WHERE ((transaction_status)::text = 'Success'::text)) AS successful_tpv,
    sum(actual_fee) FILTER (WHERE ((transaction_status)::text = 'Success'::text)) AS gross_fee_revenue
   FROM public.transactions
  WHERE ((transaction_at >= '2025-10-01 00:00:00'::timestamp without time zone) AND (transaction_at < '2026-10-01 00:00:00'::timestamp without time zone))
  GROUP BY payment_channel;


ALTER VIEW public.vw_channel_performance OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 17500)
-- Name: vw_hourly_transaction_kpis; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_hourly_transaction_kpis AS
 SELECT date_trunc('hour'::text, transaction_at) AS txn_hour,
    count(*) AS total_txns,
    count(*) FILTER (WHERE ((transaction_status)::text = 'Success'::text)) AS successful_txns,
    sum(amount) FILTER (WHERE ((transaction_status)::text = 'Success'::text)) AS successful_tpv,
    sum(actual_fee) FILTER (WHERE ((transaction_status)::text = 'Success'::text)) AS gross_fee_revenue,
    count(DISTINCT terminal_id) FILTER (WHERE ((transaction_status)::text = 'Success'::text)) AS active_terminals
   FROM public.transactions
  GROUP BY (date_trunc('hour'::text, transaction_at));


ALTER VIEW public.vw_hourly_transaction_kpis OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 17478)
-- Name: vw_incident_performance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_incident_performance AS
 SELECT incident_id,
    incident_type,
    severity,
    started_at,
    resolved_at,
    (date_trunc('month'::text, started_at))::date AS report_month,
    incident_status,
    assigned_team,
    sla_target_minutes,
    root_cause,
        CASE
            WHEN (resolved_at >= started_at) THEN round((EXTRACT(epoch FROM (resolved_at - started_at)) / 60.0), 2)
            ELSE NULL::numeric
        END AS resolution_minutes,
        CASE
            WHEN (((incident_status)::text = 'Resolved'::text) AND (resolved_at >= started_at) AND (sla_target_minutes IS NOT NULL) AND ((EXTRACT(epoch FROM (resolved_at - started_at)) / 60.0) <= (sla_target_minutes)::numeric)) THEN 1
            ELSE 0
        END AS within_sla,
        CASE
            WHEN (((incident_status)::text = 'Resolved'::text) AND (resolved_at >= started_at) AND (sla_target_minutes IS NOT NULL) AND ((EXTRACT(epoch FROM (resolved_at - started_at)) / 60.0) > (sla_target_minutes)::numeric)) THEN 1
            ELSE 0
        END AS sla_breached
   FROM public.operational_incidents;


ALTER VIEW public.vw_incident_performance OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 17468)
-- Name: vw_merchant_performance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_merchant_performance AS
 WITH months AS (
         SELECT (generate_series(((date_trunc('month'::text, min(transactions.transaction_at)))::date)::timestamp with time zone, ((date_trunc('month'::text, max(transactions.transaction_at)))::date)::timestamp with time zone, '1 mon'::interval))::date AS report_month
           FROM public.transactions
        ), monthly_merchant_txns AS (
         SELECT (date_trunc('month'::text, transactions.transaction_at))::date AS report_month,
            transactions.merchant_id,
            count(*) AS total_txns,
            count(*) FILTER (WHERE ((transactions.transaction_status)::text = 'Success'::text)) AS successful_txns,
            count(*) FILTER (WHERE ((transactions.transaction_status)::text = 'Failed'::text)) AS failed_txns,
            COALESCE(sum(transactions.amount) FILTER (WHERE ((transactions.transaction_status)::text = 'Success'::text)), (0)::numeric) AS successful_tpv,
            COALESCE(sum(transactions.actual_fee) FILTER (WHERE ((transactions.transaction_status)::text = 'Success'::text)), (0)::numeric) AS gross_fee_revenue
           FROM public.transactions
          WHERE (transactions.merchant_id IS NOT NULL)
          GROUP BY ((date_trunc('month'::text, transactions.transaction_at))::date), transactions.merchant_id
        )
 SELECT m.report_month,
    mc.merchant_id,
    COALESCE(mt.total_txns, (0)::bigint) AS total_txns,
    COALESCE(mt.successful_txns, (0)::bigint) AS successful_txns,
    COALESCE(mt.failed_txns, (0)::bigint) AS failed_txns,
    round(((100.0 * (COALESCE(mt.successful_txns, (0)::bigint))::numeric) / (NULLIF(mt.total_txns, 0))::numeric), 2) AS success_rate_pct,
    COALESCE(mt.successful_tpv, (0)::numeric) AS successful_tpv,
    COALESCE(mt.gross_fee_revenue, (0)::numeric) AS gross_fee_revenue,
        CASE
            WHEN (COALESCE(mt.successful_txns, (0)::bigint) > 0) THEN 1
            ELSE 0
        END AS is_active
   FROM ((months m
     CROSS JOIN public.merchants mc)
     LEFT JOIN monthly_merchant_txns mt ON (((m.report_month = mt.report_month) AND ((mc.merchant_id)::text = (mt.merchant_id)::text))));


ALTER VIEW public.vw_merchant_performance OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 17458)
-- Name: vw_monthly_transaction_kpis; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_monthly_transaction_kpis AS
 SELECT (date_trunc('month'::text, transaction_at))::date AS report_month,
    count(*) AS total_transactions,
    count(*) FILTER (WHERE ((transaction_status)::text = 'Success'::text)) AS successful_txns,
    count(*) FILTER (WHERE ((transaction_status)::text = 'Failed'::text)) AS failed_txns,
    count(*) FILTER (WHERE (((transaction_status)::text <> ALL ((ARRAY['Success'::character varying, 'Failed'::character varying])::text[])) OR (transaction_status IS NULL))) AS other_txns,
    round(((100.0 * (count(*) FILTER (WHERE ((transaction_status)::text = 'Success'::text)))::numeric) / (NULLIF(count(*), 0))::numeric), 2) AS success_rate_pct,
    COALESCE(sum(amount) FILTER (WHERE ((transaction_status)::text = 'Success'::text)), (0)::numeric) AS successful_tpv,
    COALESCE(sum(actual_fee) FILTER (WHERE ((transaction_status)::text = 'Success'::text)), (0)::numeric) AS gross_fee_revenue
   FROM public.transactions
  GROUP BY ((date_trunc('month'::text, transaction_at))::date);


ALTER VIEW public.vw_monthly_transaction_kpis OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 17463)
-- Name: vw_terminal_performance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_terminal_performance AS
 WITH months AS (
         SELECT (generate_series(date_trunc('month'::text, min(transactions.transaction_at)), date_trunc('month'::text, max(transactions.transaction_at)), '1 mon'::interval))::date AS report_month
           FROM public.transactions
        ), monthly_terminal_txns AS (
         SELECT (date_trunc('month'::text, transactions.transaction_at))::date AS report_month,
            transactions.terminal_id,
            count(*) AS total_txns,
            count(*) FILTER (WHERE ((transactions.transaction_status)::text = 'Success'::text)) AS successful_txns,
            count(*) FILTER (WHERE ((transactions.transaction_status)::text = 'Failed'::text)) AS failed_txns,
            COALESCE(sum(transactions.amount) FILTER (WHERE ((transactions.transaction_status)::text = 'Success'::text)), (0)::numeric) AS successful_tpv,
            COALESCE(sum(transactions.actual_fee) FILTER (WHERE ((transactions.transaction_status)::text = 'Success'::text)), (0)::numeric) AS gross_fee_revenue
           FROM public.transactions
          WHERE (((transactions.payment_channel)::text = ANY ((ARRAY['POS_CARD'::character varying, 'POS_TRANSFER'::character varying])::text[])) AND (transactions.terminal_id IS NOT NULL))
          GROUP BY ((date_trunc('month'::text, transactions.transaction_at))::date), transactions.terminal_id
        )
 SELECT m.report_month,
    t.terminal_id,
    COALESCE(mt.total_txns, (0)::bigint) AS total_txns,
    COALESCE(mt.successful_txns, (0)::bigint) AS successful_txns,
    COALESCE(mt.failed_txns, (0)::bigint) AS failed_txns,
    round(((100.0 * (COALESCE(mt.successful_txns, (0)::bigint))::numeric) / (NULLIF(mt.total_txns, 0))::numeric), 2) AS success_rate_pct,
    COALESCE(mt.successful_tpv, (0)::numeric) AS successful_tpv,
    COALESCE(mt.gross_fee_revenue, (0)::numeric) AS gross_fee_revenue,
        CASE
            WHEN (COALESCE(mt.successful_txns, (0)::bigint) > 0) THEN 1
            ELSE 0
        END AS is_active
   FROM ((months m
     CROSS JOIN public.terminals t)
     LEFT JOIN monthly_terminal_txns mt ON (((m.report_month = mt.report_month) AND ((t.terminal_id)::text = (mt.terminal_id)::text))));


ALTER VIEW public.vw_terminal_performance OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 17488)
-- Name: vw_monthly_mis_scorecard; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_monthly_mis_scorecard AS
 WITH monthly_terminals AS (
         SELECT vw_terminal_performance.report_month,
            count(*) AS total_terminals,
            sum(vw_terminal_performance.is_active) AS active_terminals,
            (count(*) - sum(vw_terminal_performance.is_active)) AS inactive_terminals,
            round(((100.0 * (sum(vw_terminal_performance.is_active))::numeric) / (NULLIF(count(*), 0))::numeric), 2) AS activation_rate_pct
           FROM public.vw_terminal_performance
          GROUP BY vw_terminal_performance.report_month
        ), monthly_incidents AS (
         SELECT vw_incident_performance.report_month,
            count(*) AS total_incidents,
            round(avg(vw_incident_performance.resolution_minutes) FILTER (WHERE ((vw_incident_performance.incident_status)::text = 'Resolved'::text)), 2) AS avg_resolution_minutes,
            sum(vw_incident_performance.within_sla) AS incidents_within_sla,
            sum(vw_incident_performance.sla_breached) AS sla_breaches,
            round(((100.0 * (sum(vw_incident_performance.within_sla))::numeric) / (NULLIF((sum(vw_incident_performance.within_sla) + sum(vw_incident_performance.sla_breached)), 0))::numeric), 2) AS sla_compliance_pct
           FROM public.vw_incident_performance
          GROUP BY vw_incident_performance.report_month
        ), monthly_scorecard AS (
         SELECT t.report_month,
            t.total_transactions,
            t.successful_txns,
            t.failed_txns,
            t.success_rate_pct,
            t.successful_tpv,
            t.gross_fee_revenue,
            mt.total_terminals,
            mt.active_terminals,
            mt.inactive_terminals,
            mt.activation_rate_pct,
            COALESCE(mi.total_incidents, (0)::bigint) AS total_incidents,
            mi.avg_resolution_minutes,
            COALESCE(mi.incidents_within_sla, (0)::bigint) AS incidents_within_sla,
            COALESCE(mi.sla_breaches, (0)::bigint) AS sla_breaches,
            mi.sla_compliance_pct
           FROM ((public.vw_monthly_transaction_kpis t
             LEFT JOIN monthly_terminals mt ON ((t.report_month = mt.report_month)))
             LEFT JOIN monthly_incidents mi ON ((t.report_month = mi.report_month)))
        )
 SELECT report_month,
    total_transactions,
    successful_txns,
    failed_txns,
    success_rate_pct,
    successful_tpv,
    gross_fee_revenue,
    total_terminals,
    active_terminals,
    inactive_terminals,
    activation_rate_pct,
    total_incidents,
    avg_resolution_minutes,
    incidents_within_sla,
    sla_breaches,
    sla_compliance_pct,
    round(((100.0 * (successful_tpv - lag(successful_tpv) OVER (ORDER BY report_month))) / NULLIF(lag(successful_tpv) OVER (ORDER BY report_month), (0)::numeric)), 2) AS tpv_mom_growth_pct,
    round(((100.0 * (gross_fee_revenue - lag(gross_fee_revenue) OVER (ORDER BY report_month))) / NULLIF(lag(gross_fee_revenue) OVER (ORDER BY report_month), (0)::numeric)), 2) AS revenue_mom_growth_pct
   FROM monthly_scorecard;


ALTER VIEW public.vw_monthly_mis_scorecard OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 17473)
-- Name: vw_regional_performance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_regional_performance AS
 SELECT (date_trunc('month'::text, t.transaction_at))::date AS report_month,
    m.region,
    count(*) AS total_txns,
    count(*) FILTER (WHERE ((t.transaction_status)::text = 'Success'::text)) AS successful_txns,
    count(*) FILTER (WHERE ((t.transaction_status)::text = 'Failed'::text)) AS failed_txns,
    round(((100.0 * (count(*) FILTER (WHERE ((t.transaction_status)::text = 'Success'::text)))::numeric) / (NULLIF(count(*), 0))::numeric), 2) AS success_rate_pct,
    COALESCE(sum(t.amount) FILTER (WHERE ((t.transaction_status)::text = 'Success'::text)), (0)::numeric) AS successful_tpv,
    COALESCE(sum(t.actual_fee) FILTER (WHERE ((t.transaction_status)::text = 'Success'::text)), (0)::numeric) AS gross_fee_revenue,
    count(DISTINCT t.merchant_id) FILTER (WHERE ((t.transaction_status)::text = 'Success'::text)) AS active_merchants,
    count(DISTINCT t.terminal_id) FILTER (WHERE (((t.transaction_status)::text = 'Success'::text) AND ((t.payment_channel)::text = ANY ((ARRAY['POS_CARD'::character varying, 'POS_TRANSFER'::character varying])::text[])))) AS active_pos_terminals
   FROM (public.transactions t
     JOIN public.merchants m ON (((t.merchant_id)::text = (m.merchant_id)::text)))
  GROUP BY ((date_trunc('month'::text, t.transaction_at))::date), m.region;


ALTER VIEW public.vw_regional_performance OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 17483)
-- Name: vw_rm_portfolio_performance_old; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_rm_portfolio_performance_old AS
 WITH rm_portfolio AS (
         SELECT DISTINCT r.relationship_manager_id,
            r.manager_name,
            r.region,
            r.team,
            c.merchant_id
           FROM (public.relationship_managers r
             LEFT JOIN public.crm_assignments c ON ((((r.relationship_manager_id)::text = (c.relationship_manager_id)::text) AND (c.assigned_at < '2026-10-01 00:00:00'::timestamp without time zone) AND ((c.unassigned_at IS NULL) OR (c.unassigned_at >= '2026-10-01 00:00:00'::timestamp without time zone)))))
        ), merchant_performance AS (
         SELECT t.merchant_id,
            count(*) FILTER (WHERE ((t.transaction_status)::text = 'Success'::text)) AS successful_txns,
            COALESCE(sum(t.amount) FILTER (WHERE ((t.transaction_status)::text = 'Success'::text)), (0)::numeric) AS successful_tpv,
            COALESCE(sum(t.actual_fee) FILTER (WHERE ((t.transaction_status)::text = 'Success'::text)), (0)::numeric) AS gross_fee_revenue
           FROM public.transactions t
          WHERE ((t.transaction_at >= '2025-10-01 00:00:00'::timestamp without time zone) AND (t.transaction_at < '2026-10-01 00:00:00'::timestamp without time zone))
          GROUP BY t.merchant_id
        )
 SELECT p.relationship_manager_id,
    p.manager_name,
    p.region,
    p.team,
    count(DISTINCT p.merchant_id) AS assigned_merchants,
    count(DISTINCT p.merchant_id) FILTER (WHERE (mp.successful_txns > 0)) AS revenue_generating_merchants,
    COALESCE(sum(mp.successful_txns), (0)::numeric) AS successful_txns,
    COALESCE(sum(mp.successful_tpv), (0)::numeric) AS successful_tpv,
    COALESCE(sum(mp.gross_fee_revenue), (0)::numeric) AS gross_fee_revenue,
    round((COALESCE(sum(mp.gross_fee_revenue), (0)::numeric) / (NULLIF(count(DISTINCT p.merchant_id), 0))::numeric), 2) AS revenue_per_merchant,
    round(((100.0 * (count(DISTINCT p.merchant_id) FILTER (WHERE (mp.successful_txns > 0)))::numeric) / (NULLIF(count(DISTINCT p.merchant_id), 0))::numeric), 2) AS merchant_activation_rate_pct
   FROM (rm_portfolio p
     LEFT JOIN merchant_performance mp ON (((p.merchant_id)::text = (mp.merchant_id)::text)))
  GROUP BY p.relationship_manager_id, p.manager_name, p.region, p.team;


ALTER VIEW public.vw_rm_portfolio_performance_old OWNER TO postgres;

--
-- TOC entry 5135 (class 2606 OID 17434)
-- Name: crm_assignments crm_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crm_assignments
    ADD CONSTRAINT crm_assignments_pkey PRIMARY KEY (crm_assignment_id);


--
-- TOC entry 5123 (class 2606 OID 17378)
-- Name: incident_terminal_impacts incident_terminal_impacts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident_terminal_impacts
    ADD CONSTRAINT incident_terminal_impacts_pkey PRIMARY KEY (impact_id);


--
-- TOC entry 5129 (class 2606 OID 17415)
-- Name: merchant_fee_contracts merchant_fee_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchant_fee_contracts
    ADD CONSTRAINT merchant_fee_contracts_pkey PRIMARY KEY (contract_id);


--
-- TOC entry 5107 (class 2606 OID 16635)
-- Name: merchants merchants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_pkey PRIMARY KEY (merchant_id);


--
-- TOC entry 5137 (class 2606 OID 17436)
-- Name: crm_assignments no_overlapping_crm_assignments; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crm_assignments
    ADD CONSTRAINT no_overlapping_crm_assignments EXCLUDE USING gist (merchant_id WITH =, tsrange(assigned_at, unassigned_at, '[)'::text) WITH &&);


--
-- TOC entry 5131 (class 2606 OID 17417)
-- Name: merchant_fee_contracts no_overlapping_fee_contracts; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchant_fee_contracts
    ADD CONSTRAINT no_overlapping_fee_contracts EXCLUDE USING gist (merchant_id WITH =, payment_channel WITH =, tsrange(effective_from, effective_to, '[)'::text) WITH &&);


--
-- TOC entry 5111 (class 2606 OID 17309)
-- Name: terminal_assignments no_overlapping_terminal_assignments; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terminal_assignments
    ADD CONSTRAINT no_overlapping_terminal_assignments EXCLUDE USING gist (terminal_id WITH =, tsrange(assigned_at, unassigned_at, '[)'::text) WITH &&);


--
-- TOC entry 5115 (class 2606 OID 17318)
-- Name: terminal_config_history no_overlapping_terminal_configs; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terminal_config_history
    ADD CONSTRAINT no_overlapping_terminal_configs EXCLUDE USING gist (terminal_id WITH =, tsrange(effective_from, effective_to, '[)'::text) WITH &&);


--
-- TOC entry 5121 (class 2606 OID 17371)
-- Name: operational_incidents operational_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operational_incidents
    ADD CONSTRAINT operational_incidents_pkey PRIMARY KEY (incident_id);


--
-- TOC entry 5133 (class 2606 OID 17427)
-- Name: relationship_managers relationship_managers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationship_managers
    ADD CONSTRAINT relationship_managers_pkey PRIMARY KEY (relationship_manager_id);


--
-- TOC entry 5113 (class 2606 OID 16647)
-- Name: terminal_assignments terminal_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terminal_assignments
    ADD CONSTRAINT terminal_assignments_pkey PRIMARY KEY (assignment_id);


--
-- TOC entry 5117 (class 2606 OID 17316)
-- Name: terminal_config_history terminal_config_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terminal_config_history
    ADD CONSTRAINT terminal_config_history_pkey PRIMARY KEY (config_id);


--
-- TOC entry 5109 (class 2606 OID 16640)
-- Name: terminals terminals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terminals
    ADD CONSTRAINT terminals_pkey PRIMARY KEY (terminal_id);


--
-- TOC entry 5125 (class 2606 OID 17397)
-- Name: transaction_fee_ledger transaction_fee_ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_fee_ledger
    ADD CONSTRAINT transaction_fee_ledger_pkey PRIMARY KEY (fee_entry_id);


--
-- TOC entry 5127 (class 2606 OID 17399)
-- Name: transaction_fee_ledger transaction_fee_ledger_reference_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_fee_ledger
    ADD CONSTRAINT transaction_fee_ledger_reference_id_key UNIQUE (reference_id);


--
-- TOC entry 5119 (class 2606 OID 17354)
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- TOC entry 5147 (class 2606 OID 17437)
-- Name: crm_assignments crm_assignments_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crm_assignments
    ADD CONSTRAINT crm_assignments_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id);


--
-- TOC entry 5148 (class 2606 OID 17442)
-- Name: crm_assignments crm_assignments_relationship_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crm_assignments
    ADD CONSTRAINT crm_assignments_relationship_manager_id_fkey FOREIGN KEY (relationship_manager_id) REFERENCES public.relationship_managers(relationship_manager_id);


--
-- TOC entry 5143 (class 2606 OID 17379)
-- Name: incident_terminal_impacts incident_terminal_impacts_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident_terminal_impacts
    ADD CONSTRAINT incident_terminal_impacts_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.operational_incidents(incident_id);


--
-- TOC entry 5144 (class 2606 OID 17384)
-- Name: incident_terminal_impacts incident_terminal_impacts_terminal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incident_terminal_impacts
    ADD CONSTRAINT incident_terminal_impacts_terminal_id_fkey FOREIGN KEY (terminal_id) REFERENCES public.terminals(terminal_id);


--
-- TOC entry 5146 (class 2606 OID 17418)
-- Name: merchant_fee_contracts merchant_fee_contracts_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchant_fee_contracts
    ADD CONSTRAINT merchant_fee_contracts_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id);


--
-- TOC entry 5138 (class 2606 OID 16653)
-- Name: terminal_assignments terminal_assignments_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terminal_assignments
    ADD CONSTRAINT terminal_assignments_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id);


--
-- TOC entry 5139 (class 2606 OID 16648)
-- Name: terminal_assignments terminal_assignments_terminal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terminal_assignments
    ADD CONSTRAINT terminal_assignments_terminal_id_fkey FOREIGN KEY (terminal_id) REFERENCES public.terminals(terminal_id);


--
-- TOC entry 5140 (class 2606 OID 17319)
-- Name: terminal_config_history terminal_config_history_terminal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terminal_config_history
    ADD CONSTRAINT terminal_config_history_terminal_id_fkey FOREIGN KEY (terminal_id) REFERENCES public.terminals(terminal_id);


--
-- TOC entry 5145 (class 2606 OID 17400)
-- Name: transaction_fee_ledger transaction_fee_ledger_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_fee_ledger
    ADD CONSTRAINT transaction_fee_ledger_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(transaction_id);


--
-- TOC entry 5141 (class 2606 OID 17355)
-- Name: transactions transactions_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id);


--
-- TOC entry 5142 (class 2606 OID 17360)
-- Name: transactions transactions_terminal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_terminal_id_fkey FOREIGN KEY (terminal_id) REFERENCES public.terminals(terminal_id);


-- Completed on 2026-11-22 20:15:39

--
-- PostgreSQL database dump complete
--

\unrestrict efrGtDWmoN6nCsojnMYyjj7depSrc3H2fP3motnHriiDtPb1MzAB0xNFuLtDaX0

