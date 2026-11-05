#!/bin/bash
# Run ON THE SERVER (cron does it every night, see SERVER.md): a copy of the database in deploy/backups, the last 14 kept.
set -e
cd "$(dirname "$0")"
mkdir -p backups
docker compose exec -T db pg_dump -U postgres -d hara --no-owner --no-privileges | gzip > "backups/hara-$(date +%Y%m%d-%H%M).sql.gz"
ls -1t backups/hara-*.sql.gz | tail -n +15 | xargs -r rm --
echo "backup ok: $(ls -1t backups/hara-*.sql.gz | head -1)"
