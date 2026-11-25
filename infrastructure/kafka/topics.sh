#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -eq 0 ]; then
  set -- framework.logs.v1 framework.anomalies.v1
fi
for topic in "$@"; do
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 \
    --create --if-not-exists --topic "$topic" --partitions 1 \
    --replication-factor 1 --config retention.ms=604800000
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 \
    --describe --topic "$topic"
done
