#!/bin/bash

source .env

for migration in $(find sql -name "*.yaml" | sort -V); do
  pgroll start --complete --postgres-url $DATABASE_URL $migration
done
