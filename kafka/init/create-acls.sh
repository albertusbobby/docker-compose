#!/bin/bash

echo "Creating ACL..."

# app-a full access topic a,b,c

for topic in topic-a topic-b topic-c
do

kafka-acls \
 --bootstrap-server kafka:9092 \
 --add \
 --allow-principal User:app-a \
 --operation READ \
 --operation WRITE \
 --topic $topic

done



# app-b hanya topic-a

kafka-acls \
 --bootstrap-server kafka:9092 \
 --add \
 --allow-principal User:app-b \
 --operation READ \
 --operation WRITE \
 --topic topic-a



# readonly hanya READ

for topic in topic-a topic-b topic-c
do

kafka-acls \
 --bootstrap-server kafka:9092 \
 --add \
 --allow-principal User:readonly \
 --operation READ \
 --topic $topic

done


echo "ACL created"
