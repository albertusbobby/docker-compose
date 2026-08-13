#!/bin/bash

echo "Creating topics..."

kafka-topics \
  --bootstrap-server kafka:9092 \
  --create \
  --if-not-exists \
  --topic topic-a \
  --partitions 3 \
  --replication-factor 1


kafka-topics \
  --bootstrap-server kafka:9092 \
  --create \
  --if-not-exists \
  --topic topic-b \
  --partitions 3 \
  --replication-factor 1


kafka-topics \
  --bootstrap-server kafka:9092 \
  --create \
  --if-not-exists \
  --topic topic-c \
  --partitions 3 \
  --replication-factor 1


echo "Topics created"
