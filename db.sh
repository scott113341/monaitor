#!/bin/bash

export PATH=/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH

DB_NAME=monaitor
DB=postgresql://scott@localhost/$DB_NAME\?sslmode=disable

read -p "Are you sure you want to drop and recreate the database? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

psql -c "DROP DATABASE IF EXISTS $DB_NAME"
psql -c "CREATE DATABASE $DB_NAME"

pgroll init --postgres-url $DB

for migration in $(find sql -name "*.yaml" | sort -V); do
  pgroll start --complete --postgres-url $DB $migration
done
