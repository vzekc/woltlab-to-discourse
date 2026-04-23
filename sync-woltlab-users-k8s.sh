#!/bin/bash
#
# Kubernetes-friendly Woltlab → Discourse user sync.
#
# Run from a CronJob (vzekc/cluster apps/discourse/cronjob-woltlab-sync.yaml).
# Assumes the container image already has:
#   - the Gemfile patched and `bundle install` done at build time
#   - the SSH key for forum.classic-computing.de mounted at /root/.ssh/id_rsa
#     (or wherever ssh_config picks it up)
#   - DB_PASSWORD in the environment (Woltlab MySQL password)
#   - Discourse DB env (DISCOURSE_DB_*) pointing at the cluster's CNPG
#     instance, set by the CronJob from the discourse-db-app secret
#
# Counterpart to sync-woltlab-users.sh, which is the legacy script for
# the docker-exec setup. Both run the same sync_users.rb; only the
# scaffolding differs. See that script's header for the post-cutover
# cleanup plan.

set -e

cd /var/www/discourse

ssh_user="discourse@forum.classic-computing.de"

cleanup() {
    pkill -f "ssh.*$ssh_user" 2>/dev/null || true
}
trap cleanup EXIT

ssh -f -N \
    -L 3306:127.0.0.1:3306 \
    -o ExitOnForwardFailure=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    "$ssh_user"

DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=forum DB_USER=discourse DB_PASSWORD="$DB_PASSWORD" \
RAILS_ENV=production IMPORT=1 LOAD_PLUGINS=1 \
    bundle exec rails runner script/import_scripts/woltlab/sync_users.rb
