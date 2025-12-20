# frozen_string_literal: true

# List attachment files from recent posts for selective copying
#
# Usage:
#   DB_HOST=127.0.0.1 DB_PORT=3306 DB_USER=forum DB_PASSWORD=pass \
#   MONTHS=1 ruby script/import_scripts/list_recent_attachments.rb
#
# Output files:
#   - attachment_files.txt: List of file paths (one per line)
#   - rsync_commands.sh: Shell script with rsync commands
#   - tar_command.sh: Shell script to create a tar archive

require "mysql2"

DB_HOST = ENV["DB_HOST"] || "localhost"
DB_PORT = ENV["DB_PORT"] || "3306"
DB_NAME = ENV["DB_NAME"] || "forum"
DB_USER = ENV["DB_USER"] || "forum"
DB_PASSWORD = ENV["DB_PASSWORD"] || ""
MONTHS = (ENV["MONTHS"] || "1").to_i

puts "=" * 80
puts "RECENT ATTACHMENT FILE LISTER"
puts "=" * 80
puts ""
puts "Configuration:"
puts "  Database: #{DB_HOST}:#{DB_PORT}/#{DB_NAME}"
puts "  Time range: Last #{MONTHS} month(s)"
puts ""

client =
  Mysql2::Client.new(
    host: DB_HOST,
    port: DB_PORT,
    username: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME,
  )

# Calculate timestamp for N months ago
months_ago = Time.now.to_i - (MONTHS * 30 * 24 * 60 * 60)
puts "Posts since: #{Time.at(months_ago).strftime("%Y-%m-%d %H:%M:%S")}"
puts ""

# Count recent posts
puts "Finding recent posts..."
recent_posts_count =
  client.query(
    "SELECT COUNT(*) as count FROM wbb3_post p
     INNER JOIN wbb3_thread t ON p.threadID = t.threadID
     WHERE p.isDeleted = 0 AND t.isDeleted = 0 AND p.time >= #{months_ago}",
  ).first[
    "count"
  ]
puts "  Found #{recent_posts_count} posts in the last #{MONTHS} month(s)"

# Get all attachments uploaded recently
puts ""
puts "Finding attachments uploaded in the last #{MONTHS} month(s)..."
attachments =
  client.query(
    "SELECT DISTINCT a.attachmentID, a.objectID as postID, a.filename,
            a.filesize, a.fileID, a.uploadTime, f.fileHash, f.fileSize as actualFileSize,
            f.fileExtension
     FROM wcf3_attachment a
     INNER JOIN wcf3_file f ON a.fileID = f.fileID
     WHERE a.uploadTime >= #{months_ago}
     ORDER BY a.uploadTime DESC",
  ).to_a

puts "  Found #{attachments.length} attachments"

if attachments.empty?
  puts ""
  puts "No attachments found. Nothing to copy."
  exit 0
end

# Calculate total size
total_size = attachments.sum { |a| a["actualFileSize"] || 0 }
total_size_mb = (total_size / 1024.0 / 1024.0).round(2)
puts "  Total size: #{total_size_mb} MB"
puts ""

# Generate file paths
file_paths = []
attachments.each do |att|
  next unless att["fileID"] && att["fileHash"]

  # WoltLab stores files as: files/<hash[0..1]>/<hash[2..3]>/<fileID>-<hash>.<ext>
  hash_dir1 = att["fileHash"][0..1]
  hash_dir2 = att["fileHash"][2..3]

  # Get extension from filename first, fallback to fileExtension field
  extension = File.extname(att["filename"]).delete_prefix(".")
  extension = att["fileExtension"] if extension.empty? && att["fileExtension"]

  # Build the file path
  filename = "#{att["fileID"]}-#{att["fileHash"]}"
  filename += ".#{extension}" unless extension.to_s.empty?

  file_path = "files/#{hash_dir1}/#{hash_dir2}/#{filename}"
  file_paths << file_path
end

# Write file list
puts "Writing output files..."
File.open("attachment_files.txt", "w") { |f| file_paths.each { |path| f.puts path } }
puts "  ✓ attachment_files.txt (#{file_paths.length} files)"

# Generate rsync command script
File.open("rsync_commands.sh", "w") do |f|
  f.puts "#!/bin/bash"
  f.puts "# Rsync commands to copy recent attachment files"
  f.puts "# Generated: #{Time.now}"
  f.puts "# Files: #{file_paths.length}"
  f.puts "# Total size: #{total_size_mb} MB"
  f.puts ""
  f.puts "# Set these variables before running:"
  f.puts 'REMOTE_HOST="your.server.com"'
  f.puts 'REMOTE_PATH="/path/to/woltlab/files"'
  f.puts 'LOCAL_PATH="./woltlab_files"'
  f.puts ""
  f.puts 'echo "Creating local directory structure..."'
  f.puts 'mkdir -p "$LOCAL_PATH"'
  f.puts ""
  f.puts 'echo "Copying files from $REMOTE_HOST..."'
  f.puts ""

  # Group by directory for efficiency
  files_by_dir = file_paths.group_by { |path| File.dirname(path) }
  files_by_dir.each do |dir, files|
    f.puts "# Directory: #{dir} (#{files.length} files)"
    f.puts "mkdir -p \"$LOCAL_PATH/#{dir}\""
    files.each do |file|
      f.puts "rsync -avz \"$REMOTE_HOST:$REMOTE_PATH/#{file}\" \"$LOCAL_PATH/#{dir}/\""
    end
    f.puts ""
  end

  f.puts 'echo "Done! Files copied to $LOCAL_PATH"'
end
File.chmod(0755, "rsync_commands.sh")
puts "  ✓ rsync_commands.sh (executable)"

# Generate tar command
File.open("tar_command.sh", "w") do |f|
  f.puts "#!/bin/bash"
  f.puts "# Create tar archive of recent attachment files"
  f.puts "# Generated: #{Time.now}"
  f.puts "# Files: #{file_paths.length}"
  f.puts "# Total size: #{total_size_mb} MB"
  f.puts ""
  f.puts "# Run this on the server where the files are located"
  f.puts 'FILES_DIR="/path/to/woltlab/files"'
  f.puts 'OUTPUT_FILE="woltlab_recent_attachments.tar.gz"'
  f.puts ""
  f.puts 'echo "Creating tar archive..."'
  f.puts ""
  f.puts "cd \"$FILES_DIR\" && tar czf \"$OUTPUT_FILE\" \\"
  file_paths.each_with_index do |path, idx|
    suffix = idx < file_paths.length - 1 ? " \\" : ""
    f.puts "  \"#{path}\"#{suffix}"
  end
  f.puts ""
  f.puts 'echo "Done! Archive created: $FILES_DIR/$OUTPUT_FILE"'
  f.puts 'echo "Download with: scp user@server:$FILES_DIR/$OUTPUT_FILE ."'
  f.puts 'echo "Extract with: tar xzf $OUTPUT_FILE"'
end
File.chmod(0755, "tar_command.sh")
puts "  ✓ tar_command.sh (executable)"

# Generate statistics by file type
puts ""
puts "Statistics by file type:"
file_types = attachments.group_by { |a| File.extname(a["filename"]).downcase }
file_types
  .sort_by { |_, files| -files.length }
  .first(10)
  .each do |ext, files|
    size_mb = (files.sum { |f| f["actualFileSize"] || 0 } / 1024.0 / 1024.0).round(2)
    ext_display = ext.empty? ? "(no extension)" : ext
    puts "  #{ext_display}: #{files.length} files (#{size_mb} MB)"
  end

puts ""
puts "=" * 80
puts "SUMMARY"
puts "=" * 80
puts "  Recent posts (last #{MONTHS} month(s)): #{recent_posts_count}"
puts "  Attachments to copy: #{file_paths.length}"
puts "  Total size: #{total_size_mb} MB"
puts ""
puts "Next steps:"
puts "  1. Review attachment_files.txt for the list of files"
puts "  2. Use rsync_commands.sh for selective file copying (edit REMOTE_HOST first)"
puts "  3. Or use tar_command.sh on the server to create an archive"
puts ""
puts "Note:"
puts "  If your WoltLab files are in 'public/files/' instead of 'files/',"
puts "  you'll need to adjust the paths in the scripts accordingly."
puts ""
puts "For tar method:"
puts "  1. Copy tar_command.sh to the server"
puts "  2. Edit FILES_DIR in the script (e.g., /path/to/woltlab/public/files)"
puts "  3. Run: ./tar_command.sh"
puts "  4. Download the .tar.gz file"
puts "  5. Extract: tar xzf woltlab_recent_attachments.tar.gz"
puts "=" * 80
