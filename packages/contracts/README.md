# Event contracts v1

Draft 2020-12 JSON Schemas live in `v1/`. Examples are hand-authored schema
fixtures, **not measured detector results or executed investigations**.

All timestamps are RFC 3339 UTC strings ending in `Z`. `event_time` preserves
the source timestamp; `ingested_at` is assigned at replay/ingestion. Detection
windows use ingestion time; `feature_summary.event_time_start/end` preserve
original bounds for evidence queries. IDs are opaque stable strings (max 256
characters), namespaced by source. Producers must derive log IDs deterministically
from source and original record identity (e.g. dataset digest and line number),
anomaly IDs from source/window/model version, and investigation IDs from anomaly
ID. Never derive a log ID from replay time. OpenSearch `_id` must equal `event_id`.

Boundary integration (replay, indexer, connector and detector are implemented):

| Boundary | Validation |
| --- | --- |
| Replay → Fluent Bit | Validate normalized log before writing JSONL |
| Kafka simulation → indexer | Remove only Fluent Bit's `fluent_bit_time` transport field; validate log before indexing |
| Connector → framework Kafka | Validate normalized log before publishing |
| Detector input/output | Validate log input and anomaly output before persistence/publication |
| Investigator input/output | Validate anomaly input and report before persistence |
| API | Validate incoming configuration and outgoing stored events |

Use a Draft 2020-12 validator with date-time format checking enabled in every
runtime. `pnpm test:contracts` uses AJV with strict mode and formats. The shared Go module embeds this schema and validates the Step 1–2 boundaries;
the Python detector validates both log inputs and anomaly outputs using these
schemas with format checking. Investigator and API integration remains for later milestones.
Reject unknown top-level fields; labels and answer keys must never be placed in
messages or `attributes`. Attributes are unindexed source metadata, not features.

Schemas enforce shape, required provenance, and completion prerequisites. They
cannot prove determinism, temporal ordering, source existence, excerpt accuracy,
or semantic support. Services must enforce these cross-field/data checks.
Verification must independently compare citations/excerpts with retrieved logs;
`completed` never means experimentally proven causality. Scores are finite numeric
values; the detector records negative Isolation Forest `score_samples` (higher
is more anomalous), its training-only threshold, and model metadata.

API OpenAPI is deferred to the actual FastAPI endpoints in Step 5.
