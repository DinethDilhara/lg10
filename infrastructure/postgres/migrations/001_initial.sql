BEGIN;
SELECT pg_advisory_xact_lock(101000);
CREATE TABLE IF NOT EXISTS schema_migrations (
    version text PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
);

-- API owns source configuration. Only env/secret references, never credentials.
CREATE TABLE IF NOT EXISTS sources (
    source_id text PRIMARY KEY,
    name text NOT NULL,
    endpoint text NOT NULL CHECK (endpoint ~ '^https?://'),
    index_pattern text NOT NULL CHECK (length(index_pattern) > 0),
    credentials_env_ref text,
    enabled boolean NOT NULL DEFAULT true,
    status text NOT NULL DEFAULT 'untested'
        CHECK (status IN ('untested', 'connected', 'error')),
    last_error text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Connector owns durable polling position; no advance before Kafka confirms.
CREATE TABLE IF NOT EXISTS connector_checkpoints (
    source_id text PRIMARY KEY REFERENCES sources(source_id),
    ingested_at timestamptz NOT NULL,
    event_id text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Detector owns anomalies; payload is the schema-validated anomaly event.
CREATE TABLE IF NOT EXISTS anomalies (
    anomaly_id text PRIMARY KEY,
    source_id text NOT NULL REFERENCES sources(source_id),
    window_start timestamptz NOT NULL,
    window_end timestamptz NOT NULL CHECK (window_end >= window_start),
    score double precision NOT NULL CHECK (score > '-Infinity'::float8 AND score < 'Infinity'::float8),
    model_version text NOT NULL,
    payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anomalies_source_window_idx ON anomalies(source_id, window_start DESC);

-- Investigator owns reports and concise execution summaries.
CREATE TABLE IF NOT EXISTS investigations (
    investigation_id text PRIMARY KEY,
    anomaly_id text NOT NULL UNIQUE REFERENCES anomalies(anomaly_id),
    status text NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'inconclusive', 'failed')),
    report jsonb CHECK (report IS NULL OR jsonb_typeof(report) = 'object'),
    duration_ms bigint CHECK (duration_ms >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS agent_execution_events (
    execution_event_id text PRIMARY KEY,
    investigation_id text NOT NULL REFERENCES investigations(investigation_id),
    sequence integer NOT NULL CHECK (sequence >= 0),
    agent text NOT NULL CHECK (agent IN ('supervisor', 'retrieval', 'analysis', 'verification')),
    status text NOT NULL CHECK (status IN ('started', 'completed', 'failed')),
    occurred_at timestamptz NOT NULL,
    summary text NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(metadata) = 'object'),
    UNIQUE (investigation_id, sequence)
);
INSERT INTO schema_migrations(version) VALUES ('001_initial') ON CONFLICT DO NOTHING;
COMMIT;
