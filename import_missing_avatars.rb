# frozen_string_literal: true

# Batch import missing avatars for users affected by the website field bug
#
# This script reads missing_avatars.csv and imports all avatars

unless defined?(Rails)
  puts "ERROR: This script must be run through Rails runner"
  puts ""
  puts "Usage:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/import_missing_avatars.rb"
  puts ""
  exit 1
end

require "csv"
require_relative "import_contents"

unless File.exist?("missing_avatars.csv")
  puts "ERROR: missing_avatars.csv not found"
  puts "Run find_missing_avatars.rb first to generate the list"
  exit 1
end

puts "=" * 80
puts "BATCH IMPORT MISSING AVATARS"
puts "=" * 80
puts ""

# Load CSV
missing = CSV.read("missing_avatars.csv", headers: true)
puts "Found #{missing.length} users with missing avatars"
puts ""

# Initialize importer
importer = ImportScripts::Woltlab.new
importer.instance_variable_set(:@import_avatars, true)

# Track results
imported = 0
failed = 0
skipped = 0

missing.each_with_index do |row, i|
  discourse_id = row["discourse_id"].to_i
  username = row["username"]
  avatar_id = row["avatar_id"]
  file_hash = row["file_hash"]
  extension = row["extension"]

  print "[#{i + 1}/#{missing.length}] #{username}... "

  begin
    user = User.find(discourse_id)

    # Skip if already has avatar
    if user.uploaded_avatar_id
      puts "already has avatar (ID: #{user.uploaded_avatar_id})"
      skipped += 1
      next
    end

    # Import avatar
    importer.send(
      :import_avatar,
      user,
      { "avatarID" => avatar_id, "fileHash" => file_hash, "avatarExtension" => extension },
    )

    user.reload
    if user.uploaded_avatar_id
      puts "✓ imported (ID: #{user.uploaded_avatar_id})"
      imported += 1
    else
      puts "✗ failed (no error but avatar not set)"
      failed += 1
    end
  rescue StandardError => e
    puts "✗ ERROR: #{e.message}"
    failed += 1
  end
end

puts ""
puts "=" * 80
puts "BATCH IMPORT COMPLETE"
puts "=" * 80
puts ""
puts "Results:"
puts "  Successfully imported: #{imported}"
puts "  Already had avatar: #{skipped}"
puts "  Failed: #{failed}"
puts "  Total processed: #{missing.length}"
puts ""
