# frozen_string_literal: true

# Efficient attachment synchronization from WoltLab server
#
# This script scans the database for all files needed for import
# (avatars, cover photos, post attachments) and syncs them efficiently
# using rsync's --files-from option.
#
# Usage:
#   bundle exec rails runner script/import_scripts/woltlab/sync_attachments.rb
#
# Environment variables:
#   REMOTE_HOST - SSH host for rsync (default: "forum.classic-computing.de")
#   REMOTE_BASE - Base path on remote server (default: "/var/www/forum/html")
#   LOCAL_PATH - Local path to store files (default: "./woltlabImports")
#   IMPORT_SINCE - Only sync files needed for filtered import (e.g., "12months", "6months")
#                  Uses same format as content import
#   IMPORT_TYPES - Control what files to sync (matches import_contents.rb)
#                  Default: only avatars and cover photos (posts not imported by default)
#                  Set to include "posts" to also sync post attachments
#
# Syncs files from three locations under REMOTE_BASE to LOCAL_PATH/woltlabImports:
#   - images/avatars/{hash[0..1]}/{avatarID}-{hash}.{ext}
#   - images/coverPhotos/{hash[0..1]}/{userID}-{hash}.{ext}
#   - _data/public/files/{hash[0..1]}/{hash[2..3]}/{fileID}-{hash}.{ext}
#   - _data/private/files/{hash[0..1]}/{hash[2..3]}/{fileID}-{hash}.bin

# Ensure this script is run through Rails
unless defined?(Rails)
  puts "ERROR: This script must be run through Rails runner"
  puts ""
  puts "Usage:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/sync_attachments.rb"
  puts ""
  exit 1
end

require_relative "import_contents"
require "mysql2"
require "fileutils"

class AttachmentSynchronizer
  include DateFilterHelper

  attr_reader :woltlab_db

  def initialize
    @woltlab_db =
      Mysql2::Client.new(
        host: ImportScripts::Woltlab::DB_HOST,
        port: ImportScripts::Woltlab::DB_PORT,
        username: ImportScripts::Woltlab::DB_USER,
        password: ImportScripts::Woltlab::DB_PASSWORD,
        database: ImportScripts::Woltlab::DB_NAME,
      )

    @remote_host = ENV["REMOTE_HOST"] || "forum.classic-computing.de"
    @remote_base = ENV["REMOTE_BASE"] || "/var/www/forum/html"
    @local_path = ENV["LOCAL_PATH"] || "./woltlabImports"

    # Parse IMPORT_SINCE option (same as content import)
    @import_since_timestamp = parse_import_since(ENV["IMPORT_SINCE"])

    # Parse IMPORT_TYPES to determine what to sync
    # Default matches import_contents.rb: only users (skip posts)
    import_types_env = ENV["IMPORT_TYPES"]
    if import_types_env && !import_types_env.empty?
      types = import_types_env.downcase.split(",").map(&:strip)
      @sync_posts = types.include?("posts")
    else
      # Default: don't sync post attachments (posts not imported by default)
      @sync_posts = false
    end
  end

  def execute
    puts "=" * 80
    puts "WOLTLAB ATTACHMENT SYNCHRONIZATION"
    puts "=" * 80
    puts ""

    validate_configuration
    file_list = scan_database
    sync_files(file_list)

    puts ""
    puts "=" * 80
    puts "Synchronization complete!"
    puts "  Files synced: #{file_list.length}"
    puts "  Local path: #{@local_path}"
    puts "=" * 80
  end

  private

  def validate_configuration
    puts "Configuration:"
    puts "  Remote: #{@remote_host}:#{@remote_base}"
    puts "  Local: #{@local_path}"
    if @import_since_timestamp
      filter_date = Time.at(@import_since_timestamp).strftime("%Y-%m-%d %H:%M:%S")
      puts "  Time filter: Since #{filter_date} (IMPORT_SINCE=#{ENV["IMPORT_SINCE"]})"
    else
      puts "  Time filter: All files (no IMPORT_SINCE set)"
    end
    puts ""
    puts "Sync configuration:"
    puts "  Avatars: YES"
    puts "  Cover photos: YES"
    puts "  Post attachments: #{@sync_posts ? "YES" : "no (posts not in IMPORT_TYPES)"}"
    puts ""
  end

  def scan_database
    puts "Scanning database for required files..."
    puts ""

    file_hashes = Set.new
    time_filter = build_time_filter

    # 1. Avatar files
    puts "  → Scanning avatars..."
    avatar_count = scan_avatars(file_hashes, time_filter)
    puts "    Found #{avatar_count} avatar files"

    # 2. Cover photos
    puts "  → Scanning cover photos..."
    cover_count = scan_cover_photos(file_hashes, time_filter)
    puts "    Found #{cover_count} cover photo files"

    # 3. Post attachments (only if posts are being imported)
    attachment_count = 0
    if @sync_posts
      puts "  → Scanning post attachments..."
      attachment_count = scan_post_attachments(file_hashes, time_filter)
      puts "    Found #{attachment_count} attachment files"
    else
      puts "  → Skipping post attachments (posts not in IMPORT_TYPES)"
    end

    puts ""
    puts "  Total unique files: #{file_hashes.length}"
    puts ""

    # Convert file hashes to file paths
    file_hashes.to_a.compact
  end

  def build_time_filter
    if @import_since_timestamp
      filter_date = Time.at(@import_since_timestamp).strftime("%Y-%m-%d %H:%M:%S")
      puts "  Filtering by time: >= #{filter_date}"
      puts ""
      @import_since_timestamp
    else
      puts "  No time filter - syncing all files"
      puts ""
      nil
    end
  end

  def scan_avatars(file_hashes, time_filter)
    query = <<-SQL
      SELECT DISTINCT a.avatarID, a.fileHash, a.avatarExtension as fileExtension
      FROM wcf3_user_avatar a
    SQL

    if time_filter
      query += " JOIN wcf3_user u ON a.userID = u.userID WHERE u.lastActivityTime >= #{time_filter}"
    end

    results = @woltlab_db.query(query).to_a
    results.each { |row| file_hashes.add(build_avatar_path(row)) }
    results.length
  end

  def scan_cover_photos(file_hashes, time_filter)
    query = <<-SQL
      SELECT DISTINCT u.userID, u.coverPhotoHash as fileHash, u.coverPhotoExtension as fileExtension
      FROM wcf3_user u
      WHERE u.coverPhotoHash IS NOT NULL AND u.coverPhotoHash != ''
    SQL

    query += " AND u.lastActivityTime >= #{time_filter}" if time_filter

    results = @woltlab_db.query(query).to_a
    results.each do |row|
      file_path = build_cover_photo_path(row)
      file_hashes.add(file_path) if file_path
    end
    results.length
  end

  def scan_post_attachments(file_hashes, time_filter)
    query = <<-SQL
      SELECT DISTINCT f.fileID, f.fileHash, f.fileExtension, f.mimeType
      FROM wcf3_attachment a
      JOIN wcf3_file f ON a.fileID = f.fileID
      JOIN wbb3_post p ON a.objectID = p.postID
      JOIN wbb3_thread t ON p.threadID = t.threadID
      WHERE a.objectTypeID = (
        SELECT objectTypeID FROM wcf3_object_type
        WHERE objectType = 'com.woltlab.wbb.post'
        AND className LIKE '%Attachment%'
        LIMIT 1
      )
      AND p.isDeleted = 0
      AND t.isDeleted = 0
    SQL

    query += " AND p.time >= #{time_filter}" if time_filter

    results = @woltlab_db.query(query).to_a
    results.each { |row| file_hashes.add(build_file_path(row)) }
    results.length
  end

  def build_avatar_path(row)
    return nil unless row["fileHash"] && row["avatarID"]

    hash = row["fileHash"]
    avatar_id = row["avatarID"]
    extension = row["fileExtension"]

    # Avatars: woltlabImports/images/avatars/{hash[0..1]}/{avatarID}-{hash}.{ext}
    hash_prefix = hash[0..1]
    filename = "#{avatar_id}-#{hash}"
    filename += ".#{extension}" if extension && !extension.empty?

    "images/avatars/#{hash_prefix}/#{filename}"
  end

  def build_cover_photo_path(row)
    return nil unless row["fileHash"] && row["userID"]

    hash = row["fileHash"]
    user_id = row["userID"]
    extension = row["fileExtension"]

    # Cover photos: woltlabImports/images/coverPhotos/{hash[0..1]}/{userID}-{hash}.{ext}
    hash_prefix = hash[0..1]
    filename = "#{user_id}-#{hash}"
    filename += ".#{extension}" if extension && !extension.empty?

    "images/coverPhotos/#{hash_prefix}/#{filename}"
  end

  def build_file_path(row)
    return nil unless row["fileHash"] && row["fileID"]

    hash = row["fileHash"]
    file_id = row["fileID"]
    extension = row["fileExtension"]
    mime_type = row["mimeType"]

    # WoltLab stores files in different directories based on type:
    # - Images (image/*): woltlabImports/_data/public/files (web-accessible)
    # - Non-images: woltlabImports/_data/private/files (access-controlled via download handler)
    is_image = mime_type&.start_with?("image/")
    base_dir = is_image ? "_data/public/files" : "_data/private/files"

    hash_dir1 = hash[0..1]
    hash_dir2 = hash[2..3]
    filename = "#{file_id}-#{hash}"
    filename += ".#{extension}" if extension && !extension.empty?

    "#{base_dir}/#{hash_dir1}/#{hash_dir2}/#{filename}"
  end

  def sync_files(file_list)
    return if file_list.empty?

    # Write file list to temp file
    file_list_path = "#{@local_path}/file_list.txt"
    FileUtils.mkdir_p(@local_path)

    File.open(file_list_path, "w") { |f| file_list.each { |path| f.puts path } }
    puts "Generated file list: #{file_list_path}"
    puts ""

    # Use rsync with --files-from for efficient sync
    puts "Syncing #{file_list.length} files from #{@remote_host}..."
    puts ""

    remote_source = "#{@remote_host}:#{@remote_base}/"

    cmd = [
      "rsync",
      "-az",
      "--stats",
      "--files-from=#{file_list_path}",
      remote_source,
      "#{@local_path}/",
    ].join(" ")

    puts "Transferring files..."
    success = system(cmd)
    exit_code = $?.exitstatus
    puts ""

    # Exit code 0 = success
    # Exit code 23 = partial transfer (some files missing on server - expected for .bin files)
    # Exit code 24 = partial transfer (vanished source files - also acceptable)
    unless success || [23, 24].include?(exit_code)
      puts ""
      puts "⚠ rsync failed with exit code #{exit_code}"
      puts ""
      puts "Make sure:"
      puts "  1. You have SSH access to #{@remote_host}"
      puts "  2. The remote base path #{@remote_base} is correct"
      puts "  3. rsync is installed on both local and remote systems"
      puts ""
      exit 1
    end

    if exit_code == 23
      puts "Note: Some files were not found on server (exit code 23)."
      puts "This is expected for .bin files (failed WoltLab uploads)."
      puts ""
    end
  end
end

# Only auto-execute if this script is run directly
AttachmentSynchronizer.new.execute if __FILE__ == $PROGRAM_NAME
