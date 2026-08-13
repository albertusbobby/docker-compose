#!/bin/bash

echo "Creating SCRAM users..."

kafka-configs \
  --bootstrap-server kafka:9092 \
  --alter \
  --add-config 'SCRAM-SHA-256=[password=admin123]' \
  --entity-type users \
  --entity-name admin


kafka-configs \
  --bootstrap-server kafka:9092 \
  --alter \
  --add-config 'SCRAM-SHA-256=[password=appa123]' \
  --entity-type users \
  --entity-name app-a


kafka-configs \
  --bootstrap-server kafka:9092 \
  --alter \
  --add-config 'SCRAM-SHA-256=[password=appb123]' \
  --entity-type users \
  --entity-name app-b


kafka-configs \
  --bootstrap-server kafka:9092 \
  --alter \
  --add-config 'SCRAM-SHA-256=[password=readonly123]' \
  --entity-type users \
  --entity-name readonly


echo "Users created"
