FROM discourse/base:release-stable

ENV RAILS_ENV=production \
    IMPORT=1 \
    LOAD_PLUGINS=1

WORKDIR /var/www/discourse

# Without this, any later git command in this tree fails with
# "dubious ownership" because the working tree was created by a
# different user during the base image build.
RUN git config --global --add safe.directory /var/www/discourse

# Match the runtime patch in sync-woltlab-users.sh: the WoltLab importer
# uses the older sqlite3 gem API. Pinning here moves the patch from
# every-run to image-build, so sync-woltlab-users-k8s.sh has nothing to
# fix up. Drop this when the legacy docker script is retired and the
# upstream Gemfile situation is reassessed.
RUN perl -pi -e 's/gem "sqlite3".*/gem "sqlite3", "~> 1.3", ">= 1.3.13"/' Gemfile

# mysql2 is needed by sync_users.rb to read from the WoltLab MySQL DB
# over the SSH tunnel.
RUN apt-get update && \
    apt-get install -y --no-install-recommends default-mysql-client && \
    rm -rf /var/lib/apt/lists/*

RUN bundle install --jobs 4 --retry 3

# Copy the import scripts into the place Discourse expects them.
COPY . /var/www/discourse/script/import_scripts/woltlab/

RUN chmod +x /var/www/discourse/script/import_scripts/woltlab/sync-woltlab-users.sh \
             /var/www/discourse/script/import_scripts/woltlab/sync-woltlab-users-k8s.sh

ENTRYPOINT ["/var/www/discourse/script/import_scripts/woltlab/sync-woltlab-users-k8s.sh"]
