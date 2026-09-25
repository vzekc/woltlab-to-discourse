#!/bin/bash

set -e

cd /var/www/discourse

ssh_user="discourse@forum.classic-computing.de"

cleanup() {
    pkill -f "ssh.*$ssh_user" 2>/dev/null || true
}
trap cleanup EXIT

# Monkey patch Gemfile for version parity
perl -pi.bak -e 's/gem "sqlite3".*/gem "sqlite3", "~> 1.3", ">= 1.3.13"/' Gemfile

RAILS_ENV=production IMPORT=1 LOAD_PLUGINS=1 \
                     bundle install

# Start tunnel in background
ssh -f -N \
    -L 3306:127.0.0.1:3306 \
    -o ExitOnForwardFailure=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    $ssh_user

# Only users active on WoltLab within this window get a Discourse account.
# Discourse's clean_up_inactive_users_after_days (730 on the live site) deletes
# accounts that never posted and were not seen for two years, so importing
# users idle for longer would create accounts that are deleted again the next
# day. The window stays below the cleanup threshold to keep the two apart.
IMPORT_SINCE="${IMPORT_SINCE:-700days}"

# Run sync
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=forum DB_USER=discourse DB_PASSWORD="$DB_PASSWORD" \
                  IMPORT_SINCE="$IMPORT_SINCE" \
                  RAILS_ENV=production IMPORT=1 LOAD_PLUGINS=1 \
                  bundle exec rails runner script/import_scripts/woltlab/sync_users.rb
