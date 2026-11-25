#!/bin/sh
set -eu
curl -fsS --retry 5 --retry-all-errors -X PUT \
  http://opensearch:9200/_index_template/lg-ten-logs-v1 \
  -H 'Content-Type: application/json' --data-binary @/init/logs-template.json
# HEAD distinguishes an existing index from a failed request; never swallow errors.
code=$(curl -sS -o /dev/null -w '%{http_code}' -I http://opensearch:9200/lg-ten-logs-v1)
case "$code" in
  200) ;;
  404) curl -fsS -X PUT http://opensearch:9200/lg-ten-logs-v1 ;;
  *) echo "Index lookup failed: HTTP $code" >&2; exit 1 ;;
esac
