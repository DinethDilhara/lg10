BEGIN;
SELECT pg_advisory_xact_lock(101000);
CREATE TABLE IF NOT EXISTS detector_models (
 model_version text PRIMARY KEY,
 metadata jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS detector_events (
 model_version text NOT NULL REFERENCES detector_models(model_version),
 source_id text NOT NULL REFERENCES sources(source_id),
 event_id text NOT NULL,
 window_start timestamptz NOT NULL,
 payload jsonb NOT NULL,
 late boolean NOT NULL DEFAULT false,
 received_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(model_version, source_id, event_id)
);
CREATE INDEX IF NOT EXISTS detector_events_window_idx ON detector_events(model_version, source_id, window_start);
CREATE TABLE IF NOT EXISTS detector_windows (
 model_version text NOT NULL REFERENCES detector_models(model_version),
 source_id text NOT NULL REFERENCES sources(source_id),
 window_start timestamptz NOT NULL,
 window_end timestamptz NOT NULL,
 score double precision NOT NULL CHECK(score > '-Infinity'::float8 AND score < 'Infinity'::float8),
 threshold double precision NOT NULL,
 is_anomaly boolean NOT NULL,
 feature_summary jsonb NOT NULL,
 log_ids jsonb NOT NULL,
 scored_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(model_version, source_id, window_start)
);
CREATE TABLE IF NOT EXISTS detector_outbox (
 anomaly_id text PRIMARY KEY REFERENCES anomalies(anomaly_id),
 payload jsonb NOT NULL,
 published_at timestamptz
);
INSERT INTO schema_migrations(version) VALUES ('002_detector') ON CONFLICT DO NOTHING;
COMMIT;
