#!/bin/bash
#
# Used by the legacy Docker-based migrate container on the host VM,
# invoked from /etc/systemd/system/woltlab-sync.service via:
#   docker exec -e DB_PASSWORD=... migrate sync-woltlab-users.sh
#
# Patches Discourse's Gemfile in place at runtime, which is the wrong
# layer but matches how the docker container is built today. The
# Kubernetes sync uses sync-woltlab-users-k8s.sh, which assumes the
# image already has the right Gemfile baked in.
#
# CLEANUP (post-cutover, when the docker setup is gone):
#   - Delete this script.
#   - Rename sync-woltlab-users-k8s.sh -> sync-woltlab-users.sh.
#   - Remove the gem-pin Dockerfile patch from this repo's Dockerfile;
#     the upstream Discourse Gemfile may have moved on by then.

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

# Run sync
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=forum DB_USER=discourse DB_PASSWORD="$DB_PASSWORD" \
                  RAILS_ENV=production IMPORT=1 LOAD_PLUGINS=1 \
                  bundle exec rails runner script/import_scripts/woltlab/sync_users.rb
