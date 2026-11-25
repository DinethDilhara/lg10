#!/bin/sh
set -eu
for migration in /migrations/*.sql; do
  psql -v ON_ERROR_STOP=1 -f "$migration"
done

# Seed the configured source ID so detector records can reference it on first boot.
psql -v ON_ERROR_STOP=1 -v source_id="$SOURCE_ID" -v endpoint="$SOURCE_OPENSEARCH_URL"   -v index_pattern="$SOURCE_INDEX" -f /register-source.sql
