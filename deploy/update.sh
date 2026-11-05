#!/bin/bash
# Run ON THE SERVER to take the newest version from GitHub and restart what changed:
#   bash update.sh
set -e
cd "$(dirname "$0")"
git pull --ff-only
docker compose --profile tunnel up -d --build
docker image prune -f > /dev/null
echo "updated"
