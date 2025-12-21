#!/bin/bash

set -e

ssh_user="discourse@forum.classic-computing.de"

cleanup() {
    pkill -f "ssh.*$ssh_user" 2>/dev/null || true
}
trap cleanup EXIT

# Start tunnel in background
ssh -f -N \
    -L 3306:127.0.0.1:3306 \
    -o ExitOnForwardFailure=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    $ssh_user

# Run sync
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=forum DB_USER=forum DB_PASSWORD="$DB_PASSWORD" \
                  RAILS_ENV=production IMPORT=1 LOAD_PLUGINS=1 \
                  bundle exec rails runner script/import_scripts/woltlab/sync_users.rb
