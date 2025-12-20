# frozen_string_literal: true

# Import WoltLab Burning Board 3 smilies as Discourse custom emojis
#
# Usage:
#   RAILS_ENV=development bundle exec rails runner script/import_scripts/woltlab/import_custom_emojis.rb
#
# Environment variables:
#   DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=forum DB_USER=forum DB_PASSWORD=$(cat /tmp/pw.txt)
#
# This script:
# - Queries WoltLab database for smilies and categories
# - Downloads smiley images
# - Creates Discourse CustomEmoji records with proper group categorization
# - Handles duplicate smiley codes by falling back to title

require "mysql2"
require "net/http"
require "uri"
require "tempfile"

# Database configuration
DB_HOST = ENV["DB_HOST"] || "localhost"
DB_PORT = ENV["DB_PORT"] || "3306"
DB_NAME = ENV["DB_NAME"] || "forum"
DB_USER = ENV["DB_USER"] || "forum"
DB_PASSWORD = ENV["DB_PASSWORD"] || ""

# Base URL for smiley images
BASE_URL = ENV["BASE_URL"] || "https://forum.classic-computing.de/"

puts "=" * 80
puts "WoltLab Custom Emoji Importer"
puts "=" * 80
puts "Database: #{DB_HOST}:#{DB_PORT}/#{DB_NAME}"
puts "Base URL: #{BASE_URL}"
puts

# Connect to MySQL
puts "Connecting to database..."
client =
  Mysql2::Client.new(
    host: DB_HOST,
    port: DB_PORT,
    database: DB_NAME,
    username: DB_USER,
    password: DB_PASSWORD,
  )

# Sanitize emoji name following Discourse convention
def sanitize_emoji_name(name)
  # Remove colons if present
  name = name.gsub(/^:|:$/, "")
  # Replace invalid characters with underscore, preserve + and -
  name = name.gsub(/[^a-z0-9\+\-]+/i, "_")
  # Remove multiple underscores
  name = name.gsub(/_{2,}/, "_")
  # Remove leading/trailing underscores
  name = name.gsub(/^_|_$/, "")
  # Lowercase
  name.downcase
end

# Sanitize category name for group field
def sanitize_category_name(category)
  return "default" if category.nil? || category.empty?
  # Lowercase and replace spaces with underscores, keep & character
  category.downcase.gsub(/\s+/, "_")
end

# Download file to temp file
def download_to_tempfile(url, original_filename)
  uri = URI.parse(url)

  tempfile = Tempfile.new([File.basename(original_filename, ".*"), File.extname(original_filename)])
  tempfile.binmode

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code == "200"
      tempfile.write(response.body)
      tempfile.rewind
      return tempfile
    else
      tempfile.close
      tempfile.unlink
      raise "HTTP #{response.code} for #{url}"
    end
  end
rescue StandardError => e
  tempfile&.close
  tempfile&.unlink
  raise e
end

# Get system user for emoji ownership
system_user = Discourse.system_user
unless system_user
  puts "ERROR: System user not found!"
  exit 1
end

puts "System user: #{system_user.username} (ID: #{system_user.id})"
puts

# Get smiley objectTypeID for categories
puts "Fetching smiley categories..."
smiley_object_type =
  client.query(
    "SELECT objectTypeID FROM wcf3_object_type WHERE objectType LIKE '%smiley%' LIMIT 1",
  ).first

category_map = {}
if smiley_object_type
  categories =
    client.query(
      "SELECT categoryID, title FROM wcf3_category
       WHERE objectTypeID = #{smiley_object_type["objectTypeID"]}",
    )
  categories.each { |cat| category_map[cat["categoryID"]] = cat["title"] }
  puts "Found #{category_map.size} categories"
else
  puts "Warning: Could not find smiley objectTypeID"
end
puts

# Fetch all smilies
puts "Fetching smilies from database..."
smilies =
  client.query(
    "SELECT smileyID, smileyCode, smileyTitle, smileyPath, categoryID
     FROM wcf3_smiley
     ORDER BY categoryID, showOrder, smileyID",
  )

puts "Found #{smilies.count} smilies"
puts
puts "=" * 80
puts "Starting import..."
puts "=" * 80
puts

# Track statistics
stats = { created: 0, skipped: 0, errors: 0 }

# Track used names to handle duplicates
used_names = Set.new
existing_emojis = CustomEmoji.pluck(:name).to_set
used_names.merge(existing_emojis)

smilies.each_with_index do |smiley, index|
  begin
    # Determine category/group
    category_name =
      if smiley["categoryID"].nil?
        "Default"
      elsif category_map[smiley["categoryID"]]
        category_map[smiley["categoryID"]]
      else
        "Default"
      end

    group = sanitize_category_name(category_name)

    # Sanitize emoji name from code
    emoji_name_from_code = sanitize_emoji_name(smiley["smileyCode"])

    # Determine final emoji name (handle duplicates)
    emoji_name = nil
    if emoji_name_from_code.present? && !used_names.include?(emoji_name_from_code)
      emoji_name = emoji_name_from_code
    else
      # Fallback to title
      emoji_name_from_title = sanitize_emoji_name(smiley["smileyTitle"])
      if emoji_name_from_title.present? && !used_names.include?(emoji_name_from_title)
        emoji_name = emoji_name_from_title
      else
        # Last resort: append ID
        emoji_name = "smiley_#{smiley["smileyID"]}"
      end
    end

    # Skip if still somehow duplicate
    if used_names.include?(emoji_name)
      puts "[#{index + 1}/#{smilies.count}] ⚠ Skipped duplicate: #{emoji_name} (#{smiley["smileyCode"]})"
      stats[:skipped] += 1
      next
    end

    # Mark name as used
    used_names.add(emoji_name)

    # Build full URL
    full_url = BASE_URL + smiley["smileyPath"]

    # Get filename from path
    filename = File.basename(smiley["smileyPath"])

    # Download to temp file
    print "[#{index + 1}/#{smilies.count}] Importing #{emoji_name} (#{group})... "

    tempfile = download_to_tempfile(full_url, filename)

    # Create upload
    upload = UploadCreator.new(tempfile, filename, type: "custom_emoji").create_for(system_user.id)

    if upload.persisted?
      # Create custom emoji
      custom_emoji =
        CustomEmoji.new(name: emoji_name, upload: upload, group: group, user: system_user)

      if custom_emoji.save
        puts "✓ Created (#{upload.original_filename})"
        stats[:created] += 1
      else
        puts "✗ Failed to save: #{custom_emoji.errors.full_messages.join(", ")}"
        stats[:errors] += 1
      end
    else
      puts "✗ Upload failed: #{upload.errors.full_messages.join(", ")}"
      stats[:errors] += 1
    end

    # Clean up tempfile
    tempfile.close
    tempfile.unlink
  rescue StandardError => e
    puts "✗ Error: #{e.message}"
    stats[:errors] += 1
  end
end

# Clear emoji cache
puts
puts "Clearing emoji cache..."
Emoji.clear_cache

puts
puts "=" * 80
puts "Import Complete!"
puts "=" * 80
puts "Created: #{stats[:created]}"
puts "Skipped: #{stats[:skipped]}"
puts "Errors: #{stats[:errors]}"
puts "=" * 80
puts
puts "Custom emojis are now available for use with :emoji_name: syntax"
puts "View them at: #{Discourse.base_url}/admin/customize/emojis"
puts
