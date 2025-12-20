# frozen_string_literal: true

# WoltLab User Sync Script
#
# Syncs users and group memberships from WoltLab to Discourse.
# Designed to run regularly (e.g., via cron) to keep data in sync.
#
# What it does:
#   1. Imports new users from WoltLab
#   2. Updates existing users with changes from WoltLab
#   3. Syncs group memberships (adds missing, removes stale)
#
# Environment variables:
#   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD - MySQL connection
#   IMPORT_SINCE - Optional: only sync users active since (e.g., "7days", "1month")
#   SKIP_FILES - Set to "1" to skip avatar/cover photo imports
#   REMOVE_STALE_MEMBERSHIPS - Set to "0" to only add memberships, not remove (default: "1")
#
# Usage:
#   bundle exec rails runner script/import_scripts/woltlab/sync_users.rb

unless defined?(Rails)
  puts "ERROR: This script must be run through Rails runner"
  puts ""
  puts "Usage:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/sync_users.rb"
  puts ""
  exit 1
end

def format_duration(seconds)
  if seconds < 60
    "#{seconds.round(1)}s"
  elsif seconds < 3600
    minutes = (seconds / 60).floor
    secs = (seconds % 60).round
    "#{minutes}m #{secs}s"
  else
    hours = (seconds / 3600).floor
    minutes = ((seconds % 3600) / 60).floor
    "#{hours}h #{minutes}m"
  end
end

puts "=" * 80
puts "WOLTLAB USER SYNC"
puts "=" * 80
puts ""
puts "This script will:"
puts "  1. Import/update users from WoltLab"
puts "  2. Sync group memberships"
puts ""

total_start = Time.now

# Step 1: Sync users
puts "=" * 80
puts "STEP 1: Syncing Users"
puts "=" * 80

step1_start = Time.now

# Force IMPORT_TYPES to users only and enable updates
original_import_types = ENV["IMPORT_TYPES"]
original_update_existing = ENV["UPDATE_EXISTING_USERS"]

ENV["IMPORT_TYPES"] = "users"
ENV["UPDATE_EXISTING_USERS"] = "1"

begin
  require_relative "import_contents"

  Rails.application.eager_load!

  # Run the user import
  importer = ImportScripts::Woltlab.new
  importer.perform
rescue StandardError => e
  puts "ERROR during user sync: #{e.message}"
  puts e.backtrace.first(10).join("\n")
ensure
  # Restore original environment
  if original_import_types
    ENV["IMPORT_TYPES"] = original_import_types
  else
    ENV.delete("IMPORT_TYPES")
  end

  if original_update_existing
    ENV["UPDATE_EXISTING_USERS"] = original_update_existing
  else
    ENV.delete("UPDATE_EXISTING_USERS")
  end
end

step1_duration = Time.now - step1_start
puts "\nStep 1 completed in #{format_duration(step1_duration)}"

# Step 2: Sync group memberships
puts ""
puts "=" * 80
puts "STEP 2: Syncing Group Memberships"
puts "=" * 80

step2_start = Time.now

begin
  require_relative "import_groups_and_permissions"

  remove_stale = ENV["REMOVE_STALE_MEMBERSHIPS"] != "0"

  migrator = PermissionMigrator.new
  migrator.sync_group_memberships(remove_stale: remove_stale)
rescue StandardError => e
  puts "ERROR during membership sync: #{e.message}"
  puts e.backtrace.first(10).join("\n")
end

step2_duration = Time.now - step2_start
puts "\nStep 2 completed in #{format_duration(step2_duration)}"

# Summary
total_duration = Time.now - total_start

puts ""
puts "=" * 80
puts "SYNC COMPLETE"
puts "=" * 80
puts ""
puts "Duration:"
puts "  User sync: #{format_duration(step1_duration)}"
puts "  Membership sync: #{format_duration(step2_duration)}"
puts "  Total: #{format_duration(total_duration)}"
puts ""
puts "=" * 80
