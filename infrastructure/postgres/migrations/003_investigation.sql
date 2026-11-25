BEGIN;
SELECT pg_advisory_xact_lock(101000);
ALTER TABLE investigations ADD COLUMN IF NOT EXISTS attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0);
ALTER TABLE investigations ADD COLUMN IF NOT EXISTS metadata jsonb NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(metadata) = 'object');
CREATE TABLE IF NOT EXISTS investigation_rejections (
    topic text NOT NULL,
    partition_id integer NOT NULL,
    offset_id bigint NOT NULL,
    reason text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY(topic, partition_id, offset_id)
);
INSERT INTO schema_migrations(version) VALUES ('003_investigation') ON CONFLICT DO NOTHING;
COMMIT;
