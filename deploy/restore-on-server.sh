#!/bin/bash
# Run ON THE SERVER, in the deploy folder, ONCE, to load the data made by export-from-pc.sh:
#   bash restore-on-server.sh /path/to/hara-data.tar.gz
# Replaces whatever is in the server's database with the packed data, and copies the photos in.
set -e
cd "$(dirname "$0")"
PACK="${1:?give the path of hara-data.tar.gz}"
WORK=$(mktemp -d)
tar -xzf "$PACK" -C "$WORK"

docker compose stop api
docker compose exec -T db psql -U postgres -c 'DROP DATABASE IF EXISTS hara WITH (FORCE)' -c 'CREATE DATABASE hara'
docker compose exec -T db psql -U postgres -d hara -v ON_ERROR_STOP=1 < "$WORK/hara.sql" > /dev/null
docker compose up -d api
sleep 5
docker compose cp "$WORK/uploads" api:/app/App_Data/
rm -rf "$WORK"
echo "Done. Restaurants in the database now: $(docker compose exec -T db psql -U postgres -d hara -t -A -c 'select count(*) from "Restaurants"')"
