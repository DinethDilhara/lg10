# LG Ten

LG Ten detects unusual log windows and investigates them using evidence from
indexed logs. The localhost MVP runs as two separate Compose projects and a
local Next.js process.

| Project | Services | Host address |
| --- | --- | --- |
| `lgten-simulation` | Manual BGL replay, Fluent Bit, simulation Kafka, log indexer, OpenSearch | `http://localhost:9200` |
| `lgten-framework` | Connector, framework Kafka, Isolation Forest detector, LangGraph worker, PostgreSQL, FastAPI | `http://localhost:8000` |
| Dashboard | Next.js development server | `http://localhost:3000` |

Kafka, PostgreSQL, and connector traffic inside each project uses Docker service
names. The simulation broker is internal. The framework broker exposes local
port 19092 for diagnostics. Each project owns its network and persistent volumes.
OpenSearch and FastAPI bind to loopback.

## Start locally

Use Docker Desktop with Compose v2, Node.js 22+, and pnpm 11.18.0. Docker needs
enough memory for OpenSearch and both Kafka brokers. On Linux, OpenSearch may
also require `vm.max_map_count >= 262144`. The localhost bridge documented here
uses Docker Desktop's `host.docker.internal`.

1. Install dependencies with `pnpm install --frozen-lockfile`. If you do not have
   an ignored `.env`, copy `.env.example` to `.env`. Set `POSTGRES_PASSWORD`
   and either `OPENAI_API_KEY` or `GEMINI_API_KEY` for the investigation worker.
2. Use `bash scripts/download-bgl-sample.sh` if
   `datasets/raw/bgl/BGL_2k.log` is missing. Set `BGL_DATASET` to a path relative
   to `datasets/` for a different BGL file. Set `BGL_REPLAY_RATE` to change rate.
3. Run the commands below from the repository root.

```bash
pnpm simulation:up
pnpm framework:up
pnpm dashboard:dev
```

Keep the dashboard command running in its own terminal. The existing root
`pnpm dev` command also starts the dashboard. The framework can start before
the simulation or with another OpenSearch source. Startup trains the detector
only if its local model files are missing. Kafka topics and PostgreSQL migrations
are initialized by one-shot services.

Open [LG1(0)](http://localhost:3000), enter `http://localhost:9200`, select the
configured LLM provider, and connect. FastAPI maps that specific local demo URL
to `http://host.docker.internal:9200` before it reaches the connector. The
connector validates the origin against `SOURCE_ALLOWED_HOSTS` and queries the
registered index. Add a trusted external hostname to that list to use an
external source. The dashboard uses the same-origin Next.js proxy to
`http://127.0.0.1:8000`. API docs are at [localhost:8000/docs](http://localhost:8000/docs).

```bash
pnpm replay:live
pnpm replay:stop
pnpm local:health
pnpm local:down
```

`pnpm replay:live` loops the BGL sample and uses fresh event IDs and ingestion
timestamps for each pass. Use it to watch the dashboard update, then stop it
with `pnpm replay:stop`. Live replay grows the local data volumes while running.
`pnpm replay:start` is a finite, reproducible pass. Repeating it preserves event
IDs, so OpenSearch keeps the original records and timestamps. Labels stay in
`datasets/labels/`. `local:down` preserves volumes. Stop
the Next.js process with Ctrl-C. If upgrading from the shared `lg-ten` project,
stop its containers first to free ports. Its volumes remain separate.

## Verify the pipeline

After BGL replay finishes, run:

```bash
pnpm test:contracts
python3 tests/integration/local_mvp.py
```

The integration test registers the demo URL through the dashboard proxy, checks
indexed BGL records, replays a fresh controlled outage, waits for a genuine model
alert, and manually queues an investigation. It compares report citations with
OpenSearch. Use `LOCAL_TEST_PROVIDER=gemini` if Gemini is configured. The
controlled outage provides a known scenario for root cause analysis. BGL labels
stay outside inference and do not establish root causes.

Compose readiness indicates a running framework and initialized database.
`/health` additionally checks whether the connector can reach the current source.
See [dashboard details](apps/dashboard/README.md) and the [local validation record](tests/LOCAL-MVP.md).
