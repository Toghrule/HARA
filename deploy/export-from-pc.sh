#!/bin/bash
# Run ON THE PC (Git Bash), from the deploy folder, to pack the pilot data for the server:
#   bash export-from-pc.sh
# Makes deploy/backups/hara-data.tar.gz = the database (hara_pilot) + the uploaded photos. Copy it to the server (see SERVER.md).
set -e
cd "$(dirname "$0")"
mkdir -p backups/pack
docker exec hara-postgres pg_dump -U postgres -d hara_pilot --no-owner --no-privileges > backups/pack/hara.sql
cp -r ../backend/src/ui/Hara.Api/App_Data/uploads backups/pack/uploads 2>/dev/null || mkdir -p backups/pack/uploads
tar -czf backups/hara-data.tar.gz -C backups/pack .
rm -rf backups/pack
ls -la backups/hara-data.tar.gz
