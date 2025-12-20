# frozen_string_literal: true

# WoltLab Burning Board 3 (WBB3) Importer
#
# Hierarchy mapping:
#   WBB3 Level 1 (5 categories) -> Custom field "wbb3_level1_category" on all categories
#   WBB3 Level 2 -> Discourse top-level categories
#   WBB3 Level 3 -> Discourse subcategories
#   WBB3 Level 4+ -> Stored in custom field "wbb3_deep_path"

# Ensure this script is run through Rails
unless defined?(Rails)
  puts "ERROR: This script must be run through Rails runner"
  puts ""
  puts "Usage:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/import_contents.rb"
  puts ""
  exit 1
end

require "mysql2"
require "base64"
require "json"
require_relative "../base"

# Shared helper module for date filtering
module DateFilterHelper
  # Parse IMPORT_SINCE value into Unix timestamp
  # Supports formats like "12months", "6months", "1year", "2weeks", "7days"
  # Also supports direct Unix timestamps
  #
  # @param value [String] The date filter value to parse
  # @return [Integer, nil] Unix timestamp or nil if invalid/empty
  def parse_import_since(value)
    return nil if value.nil? || value.empty?

    # Support formats like "12months", "6months", "1year", "2weeks", "7days"
    if value =~ /^(\d+)(day|days|week|weeks|month|months|year|years)$/i
      amount = $1.to_i
      unit = $2.downcase

      seconds =
        case unit
        when /^day/
          amount * 24 * 60 * 60
        when /^week/
          amount * 7 * 24 * 60 * 60
        when /^month/
          amount * 30 * 24 * 60 * 60
        when /^year/
          amount * 12 * 30 * 24 * 60 * 60
        end

      timestamp = Time.now.to_i - seconds
      return timestamp
    end

    # Support Unix timestamp
    return value.to_i if value =~ /^\d+$/

    puts "Warning: Invalid IMPORT_SINCE format '#{value}'. Expected format: '7days', '2weeks', '12months' or Unix timestamp"
    nil
  end
end

class ImportScripts::Woltlab < ImportScripts::Base
  include DateFilterHelper
  BATCH_SIZE = 1000

  DB_HOST = ENV["DB_HOST"] || "127.0.0.1"
  DB_PORT = ENV["DB_PORT"] || "3306"
  DB_NAME = ENV["DB_NAME"] || "forum"
  DB_USER = ENV["DB_USER"] || "forum"
  DB_PASSWORD = ENV["DB_PASSWORD"] || ""
  TABLE_PREFIX = ENV["TABLE_PREFIX"] || "wbb3_"

  # Optional: Only import posts since this timestamp (Unix timestamp)
  # Example: IMPORT_SINCE=12months (imports last 12 months)
  # Example: IMPORT_SINCE=1609459200 (imports since specific Unix timestamp)
  IMPORT_SINCE = ENV["IMPORT_SINCE"]

  # Path to WoltLab files directory (synced by sync_attachments.rb)
  FILES_DIR = "./woltlabImports/_data/public/files"

  # Optional: Control what to import (comma-separated list)
  # Example: IMPORT_TYPES=users,categories,posts,likes
  # Example: IMPORT_TYPES=users (only import users)
  # Example: IMPORT_TYPES=posts,likes (only import posts and likes)
  # Default: users only (categories, posts, and likes are skipped by default)
  IMPORT_TYPES = ENV["IMPORT_TYPES"]

  # Skip file imports (avatars, cover photos, attachments) for quick check runs
  # Set SKIP_FILES=1 to disable all file imports and speed up migration
  # Useful for testing the import process without waiting for file transfers
  SKIP_FILES = ENV["SKIP_FILES"] == "1"

  # Update existing users with changes from WoltLab instead of skipping them
  # Enabled by default - set UPDATE_EXISTING_USERS=0 to disable
  # Useful for syncing changes after initial import
  UPDATE_EXISTING_USERS = ENV["UPDATE_EXISTING_USERS"] != "0"

  def initialize
    super()
    # Disable BBCode conversion temporarily to debug post creation issues
    @bbcode_to_md = false

    puts "Connecting to MySQL database..."
    @client =
      Mysql2::Client.new(
        host: DB_HOST,
        port: DB_PORT,
        username: DB_USER,
        password: DB_PASSWORD,
        database: DB_NAME,
      )

    puts "loading post mappings..."
    @post_number_map = {}
    Post
      .pluck(:id, :post_number)
      .each { |post_id, post_number| @post_number_map[post_id] = post_number }

    # Parse IMPORT_SINCE option (applies to both posts and users)
    @import_since_timestamp = parse_import_since(IMPORT_SINCE)
    if @import_since_timestamp
      filter_date = Time.at(@import_since_timestamp).strftime("%Y-%m-%d %H:%M:%S")
      puts "Filtering: Importing data since #{filter_date} (Unix timestamp: #{@import_since_timestamp})"
      puts "  - Posts: created on or after this date"
      puts "  - Users: active (lastActivityTime) on or after this date"
    end

    # Parse IMPORT_TYPES option to control what gets imported
    if IMPORT_TYPES && !IMPORT_TYPES.empty?
      types = IMPORT_TYPES.downcase.split(",").map(&:strip)
      @import_users = types.include?("users")
      @import_categories = types.include?("categories")
      @import_posts = types.include?("posts")
      @import_likes = types.include?("likes")
    else
      # Default: import only users (skip categories, posts, and likes)
      @import_users = true
      @import_categories = false
      @import_posts = false
      @import_likes = false
    end

    puts "\nImport Types:"
    puts "  Users: #{@import_users ? "YES" : "no"}"
    puts "  Categories: #{@import_categories ? "YES" : "no"}"
    puts "  Posts: #{@import_posts ? "YES" : "no"}"
    puts "  Likes: #{@import_likes ? "YES" : "no"}"
    puts "  Update existing users: #{UPDATE_EXISTING_USERS ? "YES" : "no (skip existing)"}"

    # Profile import configuration (always enabled)
    @import_profiles = true
    puts "\nProfile Import:"
    puts "  Profiles: YES (signatures, profile views, titles, custom fields)"

    # Load user option mappings
    @user_option_map = load_user_option_mappings
    puts "  Loaded #{@user_option_map.size} user option mappings"

    # Create User Field definitions for profile visibility
    create_user_fields_from_options

    # Load mapping from field names to UserField IDs
    @user_field_id_map = load_user_field_id_mapping

    # Load board titles and descriptions (for German tag names and category descriptions)
    @board_titles = load_board_titles
    @board_descriptions = load_board_descriptions

    # Avatar and cover photo import (from local files synced by sync_attachments.rb)
    if SKIP_FILES
      puts "  Avatars & Cover Photos: SKIPPED (SKIP_FILES=1)"
      @import_avatars = false
    elsif File.directory?("./woltlabImports/images/avatars") &&
          File.directory?("./woltlabImports/images/coverPhotos")
      puts "  Avatars & Cover Photos: YES (from ./woltlabImports/images/)"
      @import_avatars = true
    else
      puts "  Avatars & Cover Photos: no (./woltlabImports/images/ directories not found - run sync_attachments.rb first)"
      @import_avatars = false
    end

    # Attachment import (from local files synced by sync_attachments.rb)
    if SKIP_FILES
      puts "  Attachments: SKIPPED (SKIP_FILES=1)"
      @import_attachments = false
    elsif File.directory?(FILES_DIR)
      puts "  Attachments: YES (from #{FILES_DIR})"
      @import_attachments = true
    else
      puts "  Attachments: no (#{FILES_DIR} not found - run sync_attachments.rb first)"
      @import_attachments = false
    end

    # Get post attachment object type ID
    if @import_attachments
      # Find the specific object type used for post attachments
      # There are multiple objectTypes with name 'com.woltlab.wbb.post',
      # but only one is used for attachments (className contains 'Attachment')
      result =
        mysql_query(
          "SELECT objectTypeID FROM wcf3_object_type
           WHERE objectType = 'com.woltlab.wbb.post'
           AND className LIKE '%Attachment%'",
        ).first
      if result
        @post_attachment_object_type_id = result["objectTypeID"]
        puts "Post attachment object type ID: #{@post_attachment_object_type_id}"
      else
        puts "Warning: Could not find post attachment object type. Attachments will not be imported."
        @import_attachments = false
      end
    end
  rescue StandardError => e
    puts "=" * 50
    puts e.message
    puts <<~TEXT
      Cannot connect to database.

      Hostname: #{DB_HOST}
      Port: #{DB_PORT}
      Username: #{DB_USER}
      Password: #{DB_PASSWORD}
      Database: #{DB_NAME}
      Table Prefix: #{TABLE_PREFIX}

      Edit the script or set these environment variables:

      export DB_HOST="localhost"
      export DB_PORT="3306"
      export DB_NAME="wbb3"
      export DB_USER="root"
      export DB_PASSWORD=""
      export TABLE_PREFIX="wbb3_"

      Exiting.
    TEXT
    exit 1
  end

  def mysql_query(sql)
    @client.query(sql, cache_rows: false)
  end

  def load_user_option_mappings
    puts "\nLoading user option mappings..."

    # Get German language ID
    lang_result =
      mysql_query("SELECT languageID FROM wcf3_language WHERE languageCode = 'de' LIMIT 1").first
    lang_id = lang_result ? lang_result["languageID"] : 1

    # Load all user options
    options = mysql_query("SELECT optionID, optionName FROM wcf3_user_option").to_a
    mapping = {}

    options.each do |opt|
      option_id = opt["optionID"]
      option_name = opt["optionName"]

      # Try to get German label from language table
      label_query =
        mysql_query(
          "SELECT languageItemValue FROM wcf3_language_item
                                 WHERE languageItem = 'wcf.user.option.#{option_name}'
                                 AND languageID = #{lang_id} LIMIT 1",
        ).first

      if label_query && label_query["languageItemValue"].to_s.strip.length > 0
        # Use German label if available
        mapping[option_id] = label_query["languageItemValue"]
      else
        # Fall back to option name
        mapping[option_id] = option_name
      end
    end

    mapping
  end

  def calculate_trust_level(activity_points)
    # Map WoltLab activity points to Discourse trust levels
    # Based on percentile distribution:
    #   TL0: 0-4 points (0-10th percentile)
    #   TL1: 5-171 points (10th-74th percentile)
    #   TL2: 172-1342 points (75th-89th percentile)
    #   TL3: 1343+ points (90th+ percentile)
    #   TL4: Manually granted to moderators/admins
    case activity_points
    when 0...5
      0 # TL0 (New User) - lurkers, inactive
    when 5...172
      1 # TL1 (Basic User) - normal members
    when 172...1343
      2 # TL2 (Member) - established contributors
    else
      3 # TL3 (Regular) - power users, top 10%
    end
  end

  def load_board_titles
    # Load German titles for boards from language table
    puts "\nLoading board titles..."

    # Get German language ID
    lang_result =
      mysql_query("SELECT languageID FROM wcf3_language WHERE languageCode = 'de' LIMIT 1").first
    lang_id = lang_result ? lang_result["languageID"] : 1

    # Load all board title translations
    titles = {}
    results =
      mysql_query(
        "SELECT languageItem, languageItemValue FROM wcf3_language_item
         WHERE languageItem LIKE 'wbb.board.%'
         AND (languageItem NOT LIKE '%.description')
         AND languageID = #{lang_id}",
      ).to_a

    results.each do |row|
      # Store mapping from internal name to German title
      titles[row["languageItem"]] = row["languageItemValue"]
    end

    puts "  Loaded #{titles.size} board title translations"
    titles
  end

  def load_board_descriptions
    puts "Loading board descriptions..."

    # Get German language ID
    lang_result =
      mysql_query("SELECT languageID FROM wcf3_language WHERE languageCode = 'de' LIMIT 1").first
    lang_id = lang_result ? lang_result["languageID"] : 1

    # Load all board description translations
    descriptions = {}
    results =
      mysql_query(
        "SELECT languageItem, languageItemValue FROM wcf3_language_item
         WHERE languageItem LIKE 'wbb.board.%.description'
         AND languageID = #{lang_id}",
      ).to_a

    results.each do |row|
      # Store mapping from internal name to German description
      descriptions[row["languageItem"]] = row["languageItemValue"]
    end

    puts "  Loaded #{descriptions.size} board description translations"
    descriptions
  end

  def get_board_title(internal_title)
    # Convert WoltLab internal board name to German title
    # If title starts with "wbb.", look it up in the language table
    if internal_title.start_with?("wbb.") && @board_titles && @board_titles[internal_title]
      @board_titles[internal_title]
    else
      internal_title
    end
  end

  def get_board_description(internal_description)
    # Convert WoltLab internal board description to German text
    # If description starts with "wbb.", look it up in the language table
    return nil if internal_description.nil? || internal_description.empty?

    if internal_description.start_with?("wbb.") && @board_descriptions &&
         @board_descriptions[internal_description]
      @board_descriptions[internal_description]
    else
      internal_description
    end
  end

  def transliterate_german(text)
    # Transliterate German umlauts for URL-safe tag names
    text
      .gsub("ä", "ae")
      .gsub("ö", "oe")
      .gsub("ü", "ue")
      .gsub("ß", "ss")
      .gsub("Ä", "Ae")
      .gsub("Ö", "Oe")
      .gsub("Ü", "Ue")
  end

  def slugify_for_tag(title)
    # Convert title to URL-safe tag name with German transliteration
    transliterate_german(title)
      .downcase
      .strip
      .gsub(/[^a-z0-9\-_]/, "-")
      .gsub(/-+/, "-")
      .gsub(/^-|-$/, "")
  end

  def create_user_fields_from_options
    puts "\nCreating User Field definitions for profile visibility..."

    # Get German language ID
    lang_result =
      mysql_query("SELECT languageID FROM wcf3_language WHERE languageCode = 'de' LIMIT 1").first
    lang_id = lang_result ? lang_result["languageID"] : 1

    # Query user options with visibility settings
    options =
      mysql_query(
        "SELECT optionID, optionName, categoryName, visible, editable, searchable
         FROM wcf3_user_option",
      ).to_a

    # Categories that should be visible on profiles (skip system settings)
    visible_categories = %w[profile.personal profile.contact profile.messenger]

    created_count = 0
    skipped_count = 0

    options.each do |opt|
      option_id = opt["optionID"]
      option_name = opt["optionName"]
      category = opt["categoryName"]

      # Skip directly mapped fields (handled separately)
      next if [1, 5, 9].include?(option_id) # aboutMe, location, homepage

      # Only process fields in visible categories
      next if visible_categories.exclude?(category)

      # Get German label
      label_query =
        mysql_query(
          "SELECT languageItemValue FROM wcf3_language_item
           WHERE languageItem = 'wcf.user.option.#{option_name}'
           AND languageID = #{lang_id} LIMIT 1",
        ).first

      next unless label_query && label_query["languageItemValue"].to_s.strip.length > 0

      field_name = label_query["languageItemValue"]

      # Check if field already exists
      existing = UserField.find_by(name: field_name)
      if existing
        skipped_count += 1
        next
      end

      # Map WoltLab visibility flags to Discourse settings
      # visible=1 means shown on profile, visible=0 means internal/private
      show_on_profile = opt["visible"] == 1
      is_editable = opt["editable"] == 1
      is_searchable = opt["searchable"] == 1

      # Create UserField (removed deprecated 'required' attribute)
      UserField.create!(
        name: field_name,
        description: "Imported from WoltLab (#{option_name})",
        field_type: "text",
        editable: is_editable,
        show_on_profile: show_on_profile,
        show_on_user_card: false, # WoltLab doesn't have user cards
        searchable: is_searchable,
      )

      created_count += 1
      visibility_info = []
      visibility_info << "public" if show_on_profile
      visibility_info << "private" unless show_on_profile
      visibility_info << "editable" if is_editable
      visibility_info << "searchable" if is_searchable
      puts "  ✓ Created User Field: #{field_name} (#{visibility_info.join(", ")})"
    rescue StandardError => e
      puts "  ⚠ Failed to create field '#{field_name}': #{e.message}"
    end

    puts "Created #{created_count} User Fields, skipped #{skipped_count} existing"
  end

  def load_user_field_id_mapping
    # Create mapping from field names to UserField IDs for storing values
    mapping = {}
    UserField.all.each { |field| mapping[field.name] = field.id }
    puts "  Loaded #{mapping.size} UserField ID mappings"
    mapping
  end

  def normalize_custom_field_name(woltlab_name)
    # Convert WoltLab field names to more readable Discourse custom field names
    name_map = {
      "birthday" => "Birthday",
      "birthdayShowYear" => "Show Birth Year",
      "gender" => "Gender",
      "occupation" => "Occupation",
      "hobbies" => "Hobbies",
      "skype" => "Skype",
      "facebook" => "Facebook",
      "twitter" => "Twitter",
    }

    # Return mapped name if it exists, otherwise convert camelCase to Title Case
    name_map[woltlab_name] ||
      woltlab_name.gsub(/([A-Z])/, ' \1').strip.split.map(&:capitalize).join(" ")
  end

  def import_avatar(user, avatar_data)
    return unless @import_avatars
    return if avatar_data.nil? || avatar_data["avatarID"].nil?

    avatar_id = avatar_data["avatarID"]
    file_hash = avatar_data["fileHash"]
    extension = avatar_data["avatarExtension"]

    return if file_hash.nil? || extension.nil?

    # Build local file path: ./woltlabImports/images/avatars/{hash[0..1]}/{avatarID}-{hash}.{ext}
    hash_prefix = file_hash[0..1]
    filename = "#{avatar_id}-#{file_hash}.#{extension}"
    avatar_path = File.join("./woltlabImports/images/avatars", hash_prefix, filename)

    unless File.exist?(avatar_path)
      puts "  ⚠ Avatar file not found for #{user.username}: #{avatar_path}"
      return
    end

    begin
      # Use the base importer's avatar upload helper which properly handles permissions
      @uploader.create_avatar(user, avatar_path)
      puts "  ✓ Imported avatar for #{user.username}"
    rescue StandardError => e
      puts "  ⚠ Error importing avatar for #{user.username}: #{e.message}"
    end
  end

  def import_cover_photo(user, cover_data)
    return unless @import_avatars # Use same flag as avatars
    return if cover_data.nil? || cover_data["coverPhotoHash"].nil?

    user_id = cover_data["userID"]
    file_hash = cover_data["coverPhotoHash"]
    extension = cover_data["coverPhotoExtension"]

    return if file_hash.nil? || extension.nil? || extension.empty?

    # Build local file path: ./woltlabImports/images/coverPhotos/{hash[0..1]}/{userID}-{hash}.{ext}
    hash_prefix = file_hash[0..1]
    filename = "#{user_id}-#{file_hash}.#{extension}"
    cover_path = File.join("./woltlabImports/images/coverPhotos", hash_prefix, filename)

    unless File.exist?(cover_path)
      puts "  ⚠ Cover photo file not found for #{user.username}: #{cover_path}"
      return
    end

    begin
      # Upload cover photo using base importer's upload helper
      upload = @uploader.create_upload(user.id, cover_path, filename)

      if upload.present? && upload.persisted?
        # Set profile background
        profile = user.user_profile
        profile.profile_background_upload_id = upload.id
        profile.save!
        puts "  ✓ Imported cover photo for #{user.username}"
      else
        puts "  ⚠ Failed to upload cover photo for #{user.username}"
      end
    rescue StandardError => e
      puts "  ⚠ Error importing cover photo for #{user.username}: #{e.message}"
    end
  end

  def preload_attachments(time_filter)
    return unless @import_attachments

    puts "\nPreloading attachments into memory..."
    start_time = Time.now

    # Build query to load all attachments for posts in the import window
    query = <<-SQL
      SELECT a.attachmentID, a.objectID, a.filename, a.filesize, a.fileType,
             a.isImage, a.showOrder, a.fileID, f.fileHash, f.mimeType, f.fileExtension,
             f.filename AS file_filename
      FROM wcf3_attachment a
      LEFT JOIN wcf3_file f ON a.fileID = f.fileID
      INNER JOIN wbb3_post p ON a.objectID = p.postID
      INNER JOIN wbb3_thread t ON p.threadID = t.threadID
      WHERE a.objectTypeID = #{@post_attachment_object_type_id}
        AND p.isDeleted = 0
        AND t.isDeleted = 0
        #{time_filter}
      ORDER BY a.objectID, a.showOrder, a.attachmentID
    SQL

    results = mysql_query(query).to_a

    # Group attachments by post ID
    @attachments_by_post = Hash.new { |h, k| h[k] = [] }
    results.each do |attachment|
      post_id = attachment.delete("objectID")
      @attachments_by_post[post_id] << attachment
    end

    elapsed = Time.now - start_time
    puts "  Loaded #{results.size} attachments for #{@attachments_by_post.size} posts in #{elapsed.round(2)}s"

    if @attachments_by_post.size > 0
      avg_per_post = (results.size.to_f / @attachments_by_post.size).round(1)
      puts "  Average #{avg_per_post} attachments per post"

      # Show distribution
      max_attachments = @attachments_by_post.values.map(&:size).max
      if max_attachments > 10
        posts_with_many = @attachments_by_post.count { |_, v| v.size > 10 }
        puts "  Posts with >10 attachments: #{posts_with_many}"
      end
    end
  end

  def get_attachments_for_post(post_id)
    return [] unless @import_attachments
    return [] unless @attachments_by_post

    @attachments_by_post[post_id] || []
  end

  def preload_orphaned_topic_data
    puts "\nPreloading topic data for orphan detection..."
    start_time = Time.now

    # Load all imported topics with their first post status
    @topic_data_cache = {}

    # Get all topic custom fields with import_id
    topic_fields = TopicCustomField.where(name: "import_id").pluck(:value, :topic_id).to_h

    return if topic_fields.empty?

    # Get all topics that exist
    existing_topic_ids = Topic.where(id: topic_fields.values).pluck(:id).to_set

    # Get all first posts for these topics
    first_posts = Post.where(topic_id: topic_fields.values, post_number: 1).pluck(:topic_id).to_set

    # Build cache: import_id -> { topic_id: X, has_first_post: bool }
    topic_fields.each do |import_id, topic_id|
      @topic_data_cache[import_id] = {
        topic_id: topic_id,
        topic_exists: existing_topic_ids.include?(topic_id),
        has_first_post: first_posts.include?(topic_id),
      }
    end

    elapsed = Time.now - start_time
    orphaned_count = @topic_data_cache.count { |_, v| v[:topic_exists] && !v[:has_first_post] }
    puts "  Cached #{@topic_data_cache.size} topics in #{elapsed.round(2)}s"
    if orphaned_count > 0
      puts "  Found #{orphaned_count} orphaned topics (topic exists but no first post)"
    end
  end

  def check_orphaned_topic(import_id)
    return nil unless @topic_data_cache

    data = @topic_data_cache[import_id.to_s]
    return nil unless data

    if data[:topic_exists] && data[:has_first_post]
      # Topic and post both exist, skip
      { action: :skip, topic_id: data[:topic_id] }
    elsif data[:topic_exists] && !data[:has_first_post]
      # Orphaned topic - needs deletion
      { action: :delete_orphan, topic_id: data[:topic_id] }
    else
      # Topic was deleted or custom field exists but topic doesn't
      nil
    end
  end

  def upload_attachment(attachment, user_id, post_id = nil)
    return nil unless attachment["fileID"] && attachment["fileHash"]

    # Build file path: files/<hash[0..1]>/<hash[2..3]>/<fileID>-<hash>.<ext>
    hash_dir1 = attachment["fileHash"][0..1]
    hash_dir2 = attachment["fileHash"][2..3]

    # WoltLab storage uses fileExtension (often .bin for non-images) to locate file on disk
    disk_extension = attachment["fileExtension"]

    # Build server-side filename for locating file on disk
    disk_filename = "#{attachment["fileID"]}-#{attachment["fileHash"]}"
    disk_filename += ".#{disk_extension}" unless disk_extension.to_s.empty?

    # WoltLab stores files in different directories based on type:
    # - Images (image/*): woltlabImports/_data/public/files (web-accessible)
    # - Non-images: woltlabImports/_data/private/files (access-controlled)
    is_image = attachment["mimeType"]&.start_with?("image/")
    base_dir =
      is_image ? "./woltlabImports/_data/public/files" : "./woltlabImports/_data/private/files"
    file_path = File.join(base_dir, hash_dir1, hash_dir2, disk_filename)

    # Get the actual filename for upload to Discourse
    # Prefer file_filename (from wcf3_file.filename) which has real extension (.zip, .pdf)
    # over filename (from wcf3_attachment.filename) which is often empty
    display_filename = attachment["file_filename"].to_s.strip
    display_filename = attachment["filename"].to_s.strip if display_filename.empty?

    # If still empty, generate one using the real extension from the filename or MIME type
    if display_filename.empty?
      # Try to get extension from MIME type
      real_extension =
        case attachment["mimeType"]
        when "application/pdf"
          "pdf"
        when "application/zip"
          "zip"
        when "text/plain"
          "txt"
        else
          disk_extension
        end
      display_filename = "attachment-#{attachment["attachmentID"]}.#{real_extension}"
    end

    unless File.exist?(file_path)
      if post_id
        puts "    ⚠ Attachment file not found: #{file_path} (post #{post_id}, attachmentID #{attachment["attachmentID"]})"
      else
        puts "    ⚠ Attachment file not found: #{file_path} (attachmentID #{attachment["attachmentID"]})"
      end
      return nil
    end

    # Upload to Discourse
    upload = create_upload(user_id, file_path, display_filename)

    if upload.nil? || !upload.persisted?
      puts "    ⚠ Failed to upload attachment: #{display_filename}"
      return nil
    end

    upload
  rescue StandardError => e
    puts "    ⚠ Error uploading attachment #{display_filename}: #{e.message}"
    nil
  end

  def process_attachments(post_id, user_id, raw_content)
    attachments = get_attachments_for_post(post_id)
    return raw_content if attachments.empty?

    # Upload all attachments and create ID mapping
    uploads_by_id = {}
    missing_attachments = []

    attachments.each do |attachment|
      upload = upload_attachment(attachment, user_id, post_id)

      if upload
        # Detect if it's an image by MIME type or extension (isImage field is unreliable)
        is_image = false
        if upload.original_filename
          ext = File.extname(upload.original_filename).downcase
          is_image = %w[.jpg .jpeg .png .gif .bmp .webp .svg].include?(ext)
        end

        uploads_by_id[attachment["attachmentID"]] = {
          upload: upload,
          filename: upload.original_filename,
          is_image: is_image,
          used_inline: false,
        }
      else
        # Track missing attachments to display them with a note
        # Use actual filename from file table
        display_filename = attachment["file_filename"].to_s.strip
        display_filename = attachment["filename"].to_s.strip if display_filename.empty?
        if display_filename.empty?
          display_filename = "attachment-#{attachment["attachmentID"]}"
          extension = attachment["fileExtension"]
          display_filename += ".#{extension}" unless extension.to_s.empty?
        end

        missing_attachments << {
          filename: display_filename,
          mime_type: attachment["mimeType"],
          filesize: attachment["filesize"],
        }
      end
    end

    # Replace WoltLab inline attachment tags with HTML img tags
    # Tags look like: <woltlab-metacode data-name="attach" data-attributes="WzI1MzcxMSwibm9uZSIsdHJ1ZV0=">
    # The data-attributes is base64-encoded JSON: [attachmentID, size, inline_flag]
    # WoltLab content is HTML, so we use HTML img tags with upload.url (not markdown with short_url)
    raw_content =
      raw_content.gsub(
        /<woltlab-metacode[^>]*data-name="attach"[^>]*data-attributes="([^"]+)"[^>]*>/,
      ) do
        begin
          # Decode base64 attributes: [attachmentID, size, inline_flag]
          decoded = Base64.decode64($1)
          parsed = JSON.parse(decoded)
          attachment_id = parsed[0]

          if upload_data = uploads_by_id[attachment_id]
            upload_data[:used_inline] = true
            # Replace with HTML img tag for images, markdown link for non-images
            if upload_data[:is_image]
              "<img src=\"#{upload_data[:upload].url}\" alt=\"#{upload_data[:filename]}\">"
            else
              # Use markdown format with short_url for proper Content-Disposition headers
              "[#{upload_data[:filename]}](#{upload_data[:upload].short_url})"
            end
          else
            # Keep original tag if attachment not found
            $&
          end
        rescue StandardError => e
          puts "  ⚠ Error parsing attachment tag: #{e.message}"
          $& # Keep original tag on error
        end
      end

    # Append remaining attachments (not used inline) at bottom
    unused_attachments = uploads_by_id.values.reject { |data| data[:used_inline] }
    unless unused_attachments.empty?
      raw_content += "\n\n---\n**Attachments:**\n\n"
      unused_attachments.each do |data|
        if data[:is_image]
          # Images: use HTML img tag
          raw_content += "<p><img src=\"#{data[:upload].url}\" alt=\"#{data[:filename]}\"></p>\n\n"
        else
          # Non-images: use markdown link with short_url for proper download headers
          raw_content +=
            "- [#{data[:filename]}](#{data[:upload].short_url}) (#{number_to_human_size(data[:upload].filesize)})\n"
        end
      end
    end

    raw_content
  end

  def number_to_human_size(size)
    return "0 Bytes" if size == 0

    units = %w[Bytes KB MB GB]
    exp = (Math.log(size) / Math.log(1024)).to_i
    exp = [exp, units.length - 1].min

    "%.1f %s" % [size / (1024.0**exp), units[exp]]
  end

  def created_post(post)
    @post_number_map[post.id] = post.post_number
    super
  end

  def execute
    flush_categories if ENV["FLUSH_CATEGORIES"]

    # Import based on configured types
    import_users if @import_users
    import_categories if @import_categories
    import_posts if @import_posts
    import_likes if @import_likes

    # Show warning if posts were imported but users/categories were skipped
    if @import_posts && (!@import_users || !@import_categories)
      puts "\n" + "=" * 80
      puts "⚠️  WARNING"
      puts "=" * 80
      if !@import_users
        puts "Posts were imported but users were skipped."
        puts "Posts will be attributed to system user or first admin."
      end
      if !@import_categories
        puts "Posts were imported but categories were skipped."
        puts "This may cause errors if category mappings don't exist."
      end
      puts "=" * 80
    end
  end

  def flush_categories
    puts "\n" + "=" * 80
    puts "FLUSHING EXISTING CATEGORIES"
    puts "=" * 80

    # Get all categories that have an import_id (were imported)
    imported_categories =
      Category.joins(
        "LEFT JOIN category_custom_fields ON category_custom_fields.category_id = categories.id AND category_custom_fields.name = 'import_id'",
      ).where("category_custom_fields.value IS NOT NULL")

    count = imported_categories.count
    puts "Found #{count} imported categories to delete..."

    if count > 0
      # Delete in reverse order (children first)
      imported_categories
        .order("categories.id DESC")
        .each do |cat|
          print "  Deleting category #{cat.id}: #{cat.name}..."
          cat.destroy!
          puts " ✓"
        end
    end

    # Clear the lookup cache
    @lookup.categories.clear

    puts "Flushed #{count} categories"
    puts "=" * 80
  end

  def update_user_from_woltlab(discourse_user, woltlab_user)
    # Apply all WoltLab user data to a Discourse user
    # Used for both new user creation and updating existing users

    # Set password hash for migration (must be done after user creation)
    discourse_user.custom_fields["import_pass"] = woltlab_user["password"] if woltlab_user[
      "password"
    ].present?

    # Handle banned users
    if woltlab_user["banned"] == 1
      discourse_user.suspended_till = 200.years.from_now
      discourse_user.suspended_at = Time.zone.now
      discourse_user.save!
    end

    # Set admin/moderator flags based on WoltLab group membership
    user_groups =
      if woltlab_user["groupIDs"].present?
        woltlab_user["groupIDs"].split(",").map(&:to_i)
      else
        []
      end

    # Group 4 = Administrators
    if user_groups.include?(4) && !discourse_user.admin
      discourse_user.admin = true
      discourse_user.save!
      puts "  → Set admin flag for #{discourse_user.username}"
    end

    # Group 5 = Moderators
    if user_groups.include?(5) && !discourse_user.moderator
      discourse_user.moderator = true
      discourse_user.save!
      puts "  → Set moderator flag for #{discourse_user.username}"
    end

    # Set trust level based on activity points
    activity_points = woltlab_user["activityPoints"] || 0
    trust_level = calculate_trust_level(activity_points)
    if discourse_user.trust_level != trust_level
      discourse_user.trust_level = trust_level
      discourse_user.save!
    end

    # Import profile data if enabled
    if @import_profiles
      profile = discourse_user.user_profile

      # Import About Me text (userOption1 = aboutMe)
      if woltlab_user["userOption1"].present?
        about_me = woltlab_user["userOption1"]
        # Truncate to 3000 characters (Discourse bio_raw limit)
        if about_me.length > 3000
          about_me = about_me[0...2997] + "..."
          puts "  ⚠ Truncated About Me for #{discourse_user.username} (#{woltlab_user["userOption1"].length} -> 3000 chars)"
        end
        profile.bio_raw = about_me
      end

      # Import location (userOption5)
      profile.location = woltlab_user["userOption5"] if woltlab_user["userOption5"].present?

      # Import website (userOption9)
      if woltlab_user["userOption9"].present?
        website = woltlab_user["userOption9"].strip
        unless website =~ %r{\Ahttps?://\z}i
          profile.website = website if website =~ %r{\Ahttps?://}i
        end
      end

      # Import profile views
      profile.views = woltlab_user["profileHits"].to_i if woltlab_user["profileHits"]

      # Set user title
      discourse_user.title = woltlab_user["userTitle"] if woltlab_user["userTitle"].present?

      # Import custom user fields from userOption values
      (1..46).each do |i|
        next if [1, 5, 9].include?(i) # Skip directly mapped fields

        option_value = woltlab_user["userOption#{i}"]
        next if option_value.nil? || option_value.to_s.strip.empty?

        option_name = @user_option_map[i]
        next unless option_name
        next if option_name.start_with?("option") && option_name =~ /^option\d+$/

        discourse_user.custom_fields[option_name] = option_value

        if @user_field_id_map && @user_field_id_map[option_name]
          discourse_user.set_user_field(@user_field_id_map[option_name], option_value)
        end
      end

      # Batch save all profile and user changes together
      begin
        profile.save! if profile.changed?
        discourse_user.save_custom_fields unless discourse_user.custom_fields_clean?
        discourse_user.save! if discourse_user.changed?
      rescue ActiveRecord::RecordInvalid => e
        puts "  ⚠ Error updating profile for #{discourse_user.username}: #{e.message}"
      end

      # Import avatar if enabled
      if @import_avatars
        import_avatar(
          discourse_user,
          {
            "avatarID" => woltlab_user["avatarID"],
            "fileHash" => woltlab_user["fileHash"],
            "avatarExtension" => woltlab_user["avatarExtension"],
          },
        )

        import_cover_photo(
          discourse_user,
          {
            "userID" => woltlab_user["userID"],
            "coverPhotoHash" => woltlab_user["coverPhotoHash"],
            "coverPhotoExtension" => woltlab_user["coverPhotoExtension"],
          },
        )
      end
    end

    # Always save import_pass custom field (even when not importing full profiles)
    discourse_user.save_custom_fields unless discourse_user.custom_fields_clean?

    # Confirm email tokens so users can log in immediately
    discourse_user.email_tokens.update_all(confirmed: true)
  end

  def import_users
    puts "", "=" * 80
    puts "IMPORTING USERS"
    puts "=" * 80

    # Build time filter clause for users (filter by lastActivityTime)
    user_time_filter = ""
    if @import_since_timestamp
      user_time_filter = " WHERE lastActivityTime >= #{@import_since_timestamp}"
    end

    total_count =
      mysql_query("SELECT COUNT(*) AS count FROM wcf3_user#{user_time_filter}").first["count"]
    puts "\nTotal users in source: #{total_count}"
    if @import_since_timestamp
      filter_date = Time.at(@import_since_timestamp).strftime("%Y-%m-%d %H:%M:%S")
      puts "Filtered by lastActivityTime >= #{filter_date}"
    end

    batches(BATCH_SIZE) do |offset|
      # Build SELECT clause - include profile fields if profile import is enabled
      select_fields =
        "u.userID, u.username, u.email, u.password, u.registrationDate, u.banned,
         u.banReason, u.lastActivityTime, u.registrationIpAddress, u.wbbPosts,
         u.activityPoints,
         GROUP_CONCAT(DISTINCT utg.groupID) AS groupIDs"

      if @import_profiles
        select_fields +=
          ",
         u.signature, u.profileHits, u.userTitle, u.avatarID,
         u.coverPhotoHash, u.coverPhotoExtension,
         a.fileHash, a.avatarExtension,
         uov.userOption1, uov.userOption2, uov.userOption3, uov.userOption4, uov.userOption5,
         uov.userOption6, uov.userOption7, uov.userOption8, uov.userOption9, uov.userOption10,
         uov.userOption11, uov.userOption12, uov.userOption13, uov.userOption14, uov.userOption15,
         uov.userOption16, uov.userOption17, uov.userOption18, uov.userOption19, uov.userOption20,
         uov.userOption21, uov.userOption22, uov.userOption23, uov.userOption24, uov.userOption25,
         uov.userOption26, uov.userOption27, uov.userOption28, uov.userOption29, uov.userOption30,
         uov.userOption31, uov.userOption32, uov.userOption33, uov.userOption34, uov.userOption35,
         uov.userOption36, uov.userOption37, uov.userOption38, uov.userOption40,
         uov.userOption41, uov.userOption42, uov.userOption43, uov.userOption44, uov.userOption45,
         uov.userOption46"
      end

      # Build FROM/JOIN clause
      from_clause = "FROM wcf3_user u"
      from_clause += "\n        LEFT JOIN wcf3_user_to_group utg ON u.userID = utg.userID"
      if @import_profiles
        from_clause +=
          "
        LEFT JOIN wcf3_user_avatar a ON u.avatarID = a.avatarID
        LEFT JOIN wcf3_user_option_value uov ON u.userID = uov.userID"
      end

      results =
        mysql_query(
          "SELECT #{select_fields}
           #{from_clause}
           #{user_time_filter.gsub("WHERE", "WHERE u.")}
           GROUP BY u.userID
           ORDER BY u.userID ASC
           LIMIT #{BATCH_SIZE}
           OFFSET #{offset}",
        )

      break if results.size < 1

      # Skip batch if all users exist (unless UPDATE_EXISTING_USERS is enabled)
      unless UPDATE_EXISTING_USERS
        next if all_records_exist?(:users, results.map { |u| u["userID"].to_i })
      end

      batch_start = Time.now
      user_count = 0

      create_users(results, total: total_count, offset: offset) do |user|
        user_count += 1

        # Check if user already exists (when UPDATE_EXISTING_USERS is enabled)
        existing_user_id = user_id_from_imported_user_id(user["userID"])
        if existing_user_id && UPDATE_EXISTING_USERS
          # Update existing user
          existing_user = User.find_by(id: existing_user_id)
          if existing_user
            puts "  ↻ Updating existing user: #{existing_user.username}"
            update_user_from_woltlab(existing_user, user)
            next # Skip create_users for this user
          end
        end

        result = {
          id: user["userID"],
          email: user["email"],
          username: user["username"],
          created_at: Time.zone.at(user["registrationDate"]),
          last_seen_at: user["lastActivityTime"] > 0 ? Time.zone.at(user["lastActivityTime"]) : nil,
          registration_ip_address: user["registrationIpAddress"],
          active: true,
          approved: true,
          post_create_action:
            proc do |newuser|
              # Use the extracted helper method for new users
              update_user_from_woltlab(newuser, user)
            end,
        }
        result
      end

      batch_time = Time.now - batch_start
      if user_count > 0
        avg_time = (batch_time / user_count * 1000).round
        puts "  📊 Batch complete: #{user_count} users in #{(batch_time * 1000).round}ms (avg #{avg_time}ms/user)"
      end
    end

    puts "\n" + "=" * 80
    puts "USER IMPORT COMPLETE"
    puts "=" * 80
  end

  def import_categories
    puts "", "=" * 80
    puts "IMPORTING CATEGORIES"
    puts "=" * 80

    categories =
      mysql_query(
        "SELECT boardID, parentID, title, description FROM #{TABLE_PREFIX}board ORDER BY boardID",
      ).to_a

    puts "\nTotal categories in source: #{categories.length}"

    # Build hierarchy
    category_map = {}
    children_by_parent = Hash.new { |h, k| h[k] = [] }
    categories.each do |cat|
      category_map[cat["boardID"]] = cat
      children_by_parent[cat["parentID"] || 0] << cat
    end

    # WBB3 Level 1 (will become Discourse tags)
    wbb3_level1 = categories.select { |c| c["parentID"].nil? || c["parentID"] == 0 }
    puts "\nWBB3 Level 1 (#{wbb3_level1.length} - will become Discourse tags):"
    wbb3_level1.each { |c| puts "  [#{c["boardID"]}] #{get_board_title(c["title"])}" }

    # WBB3 Level 2 -> Discourse top-level
    wbb3_level2 = []
    wbb3_level1.each { |l1| wbb3_level2.concat(children_by_parent[l1["boardID"]]) }
    puts "\nWBB3 Level 2 (#{wbb3_level2.length} - will become Discourse top-level categories)"

    # Prepare top-level categories with level 1 info
    discourse_top_level = []
    wbb3_level2.each do |cat|
      level1_parent = category_map[cat["parentID"]]
      discourse_top_level << {
        wbb3_id: cat["boardID"],
        name: get_board_title(cat["title"]),
        description: get_board_description(cat["description"]),
        level1_name: get_board_title(level1_parent["title"]),
      }
    end

    # WBB3 Level 3+ -> Discourse subcategories (level 3) + custom fields (level 4+)
    discourse_subcategories = []
    wbb3_level2.each do |l2_cat|
      level1_parent = category_map[l2_cat["parentID"]]
      process_children(
        children_by_parent,
        category_map,
        l2_cat["boardID"],
        l2_cat["boardID"],
        get_board_title(level1_parent["title"]),
        discourse_subcategories,
      )
    end

    puts "\nDiscourse hierarchy to create:"
    puts "  Top-level categories (from WBB3 level 2): #{discourse_top_level.length}"
    puts "  Subcategories (from WBB3 level 3): #{discourse_subcategories.length}"

    # STEP 1: Create top-level categories
    puts "\n" + "=" * 80
    puts "STEP 1: Creating #{discourse_top_level.length} top-level categories"
    puts "=" * 80

    # Debug: Check if any already exist in lookup
    puts "\nDebug: Checking lookup for first few categories..."
    discourse_top_level
      .take(5)
      .each do |cat|
        existing_id = category_id_from_imported_category_id(cat[:wbb3_id])
        if existing_id
          puts "  WBB3[#{cat[:wbb3_id]}] already mapped to Discourse[#{existing_id}]"
          existing_cat = Category.find_by(id: existing_id)
          if existing_cat
            puts "    Category exists: '#{existing_cat.name}'"
          else
            puts "    Category DOES NOT EXIST (orphaned mapping!)"
          end
        else
          puts "  WBB3[#{cat[:wbb3_id]}] not in lookup (will create)"
        end
      end
    puts ""

    create_categories(discourse_top_level) do |cat|
      {
        id: cat[:wbb3_id],
        name: cat[:name].to_s.strip,
        description: cat[:description].to_s.strip,
        post_create_action:
          proc do |category|
            category.custom_fields["wbb3_level1_category"] = cat[:level1_name]
            category.save_custom_fields
            puts "  ✓ Created top-level: WBB3[#{cat[:wbb3_id]}] -> Discourse[#{category.id}] '#{category.name}' (tagged: #{cat[:level1_name]})"
          end,
      }
    end

    # Clear caches
    puts "\nClearing caches..."
    ActiveRecord::Base.connection.clear_query_cache
    Category.reset_column_information

    # STEP 2: Create subcategories
    puts "\n" + "=" * 80
    puts "STEP 2: Creating #{discourse_subcategories.length} subcategories"
    puts "=" * 80

    create_categories(discourse_subcategories) do |cat|
      parent_discourse_id = category_id_from_imported_category_id(cat[:parent_wbb3_id])

      unless parent_discourse_id
        puts "  ⚠ Skip WBB3[#{cat[:wbb3_id]}] - parent WBB3[#{cat[:parent_wbb3_id]}] not mapped"
        next
      end

      parent_category = Category.unscoped.find_by(id: parent_discourse_id)
      unless parent_category
        puts "  ⚠ Skip WBB3[#{cat[:wbb3_id]}] - parent Discourse[#{parent_discourse_id}] not in DB"
        next
      end

      {
        id: cat[:wbb3_id],
        name: cat[:name].to_s.strip,
        description: cat[:description].to_s.strip,
        parent_category_id: parent_discourse_id,
        post_create_action:
          proc do |category|
            category.custom_fields["wbb3_level1_category"] = cat[:level1_name]
            if cat[:deep_path]&.any?
              category.custom_fields["wbb3_deep_path"] = cat[:deep_path].join(" > ")
            end
            category.save_custom_fields
            deep_info = cat[:deep_path]&.any? ? " (deep: #{cat[:deep_path].join(" > ")})" : ""
            puts "  ✓ Created subcategory: WBB3[#{cat[:wbb3_id]}] -> Discourse[#{category.id}] '#{category.name}'#{deep_info}"
          end,
      }
    end

    # STEP 3: Create tags and build category mapping for Level 1, 4, 5
    puts "\n" + "=" * 80
    puts "STEP 3: Creating tags and category mapping"
    puts "=" * 80

    # Initialize mapping hash and tag lists
    @wbb3_category_to_discourse = {}
    @wbb3_category_tags = {}
    level1_tags = []
    deep_category_tags = []

    # Create Level 1 tags
    wbb3_level1.each do |l1_cat|
      german_title = get_board_title(l1_cat["title"])
      tag_name = slugify_for_tag(german_title)
      level1_tags << { name: tag_name, description: get_board_description(l1_cat["description"]) }
    end

    # Map Level 2 categories (already imported as Discourse categories)
    wbb3_level2.each do |l2_cat|
      discourse_cat_id = category_id_from_imported_category_id(l2_cat["boardID"])
      if discourse_cat_id
        @wbb3_category_to_discourse[l2_cat["boardID"]] = { category_id: discourse_cat_id, tags: [] }
        # Add Level 1 tag
        level1_parent = category_map[l2_cat["parentID"]]
        if level1_parent
          german_title = get_board_title(level1_parent["title"])
          l1_tag = slugify_for_tag(german_title)
          @wbb3_category_to_discourse[l2_cat["boardID"]][:tags] << l1_tag
        end
      end
    end

    # Map Level 3 categories (already imported as Discourse subcategories)
    discourse_subcategories.each do |subcat|
      discourse_cat_id = category_id_from_imported_category_id(subcat[:wbb3_id])
      next unless discourse_cat_id

      @wbb3_category_to_discourse[subcat[:wbb3_id]] = { category_id: discourse_cat_id, tags: [] }

      # Add Level 1 tag
      l1_tag = slugify_for_tag(subcat[:level1_name])
      @wbb3_category_to_discourse[subcat[:wbb3_id]][:tags] << l1_tag

      # Map ALL Level 4+ categories (children of this Level 3) to this parent
      # Recursively find all deep categories
      map_deep_categories(
        children_by_parent,
        category_map,
        subcat[:wbb3_id],
        discourse_cat_id,
        l1_tag,
        deep_category_tags,
      )
    end

    # Also map Level 4+ children of Level 2 categories (that don't have Level 3)
    wbb3_level2.each do |l2_cat|
      discourse_cat_id = category_id_from_imported_category_id(l2_cat["boardID"])
      next unless discourse_cat_id

      level1_parent = category_map[l2_cat["parentID"]]
      next unless level1_parent

      german_title = get_board_title(level1_parent["title"])
      l1_tag = slugify_for_tag(german_title)

      # Find children that aren't already in discourse_subcategories
      l2_children = children_by_parent[l2_cat["boardID"]]
      l3_ids =
        discourse_subcategories
          .select { |s| s[:parent_wbb3_id] == l2_cat["boardID"] }
          .map { |s| s[:wbb3_id] }

      l2_children&.each do |child|
        # Only process if this child wasn't imported as a Level 3 category
        next if l3_ids.include?(child["boardID"])

        german_title = get_board_title(child["title"])
        tag_name = slugify_for_tag(german_title)
        deep_category_tags << tag_name

        @wbb3_category_to_discourse[child["boardID"]] = {
          category_id: discourse_cat_id,
          tags: [l1_tag, tag_name],
        }

        # Recursively map deeper children
        map_deep_categories(
          children_by_parent,
          category_map,
          child["boardID"],
          discourse_cat_id,
          l1_tag,
          deep_category_tags,
        )
      end
    end

    # Create tags in Discourse
    puts "\nCreating #{level1_tags.length} Level 1 tags..."
    level1_tags.each do |tag_info|
      Tag.find_or_create_by(name: tag_info[:name])
      puts "  ✓ Tag: #{tag_info[:name]}"
    end

    puts "\nCreating #{deep_category_tags.uniq.length} deep category tags (Level 4+)..."
    deep_category_tags.uniq.each do |tag_name|
      Tag.find_or_create_by(name: tag_name)
      puts "  ✓ Tag: #{tag_name}"
    end

    puts "\n" + "=" * 80
    puts "CATEGORY IMPORT COMPLETE"
    puts "=" * 80
    puts "Created #{discourse_top_level.length} top-level + #{discourse_subcategories.length} subcategories"
    puts "Created #{level1_tags.length} Level 1 tags + #{deep_category_tags.uniq.length} deep category tags"
    puts "Mapped #{@wbb3_category_to_discourse.length} WBB3 categories to Discourse categories"
  end

  # Map deep (Level 4+) categories to their nearest Level 2/3 parent
  def map_deep_categories(
    children_by_parent,
    category_map,
    parent_wbb3_id,
    discourse_cat_id,
    level1_tag,
    tag_list
  )
    children = children_by_parent[parent_wbb3_id]
    return unless children&.any?

    children.each do |child|
      # Create tag for this deep category
      german_title = get_board_title(child["title"])
      tag_name = slugify_for_tag(german_title)
      tag_list << tag_name

      # Map this deep category to the parent Discourse category
      @wbb3_category_to_discourse[child["boardID"]] = {
        category_id: discourse_cat_id,
        tags: [level1_tag, tag_name],
      }

      # Recursively process children
      map_deep_categories(
        children_by_parent,
        category_map,
        child["boardID"],
        discourse_cat_id,
        level1_tag,
        tag_list,
      )
    end
  end

  # Process level 3 children as subcategories, collect level 4+ as custom field
  def process_children(
    children_by_parent,
    category_map,
    parent_wbb3_id,
    top_level_wbb3_id,
    level1_name,
    result_array
  )
    children = children_by_parent[parent_wbb3_id]
    return unless children&.any?

    children.each do |child|
      # Level 3 becomes Discourse subcategory
      deep_path = []
      collect_deep_children(children_by_parent, child["boardID"], deep_path)

      result_array << {
        wbb3_id: child["boardID"],
        name: get_board_title(child["title"]),
        description: get_board_description(child["description"]),
        parent_wbb3_id: top_level_wbb3_id,
        level1_name: level1_name,
        deep_path: deep_path,
      }
    end
  end

  # Collect all children from level 4+ for the deep path
  def collect_deep_children(children_by_parent, parent_id, path_array)
    children = children_by_parent[parent_id]
    return unless children&.any?

    children.each do |child|
      path_array << get_board_title(child["title"])
      collect_deep_children(children_by_parent, child["boardID"], path_array)
    end
  end

  def convert_woltlab_quotes(raw)
    # Convert WoltLab quote tags to Discourse HTML quote format
    # Format: <woltlab-quote data-author="Username" data-link="url"><p>content</p></woltlab-quote>
    # Target: <aside class="quote" data-post="X" data-topic="Y">...</aside>
    #
    # Process nested quotes from innermost to outermost by repeatedly converting
    # quotes that don't contain any other quotes

    # Keep converting until no more woltlab-quote tags remain
    max_iterations = 10 # Prevent infinite loops
    iteration = 0

    while raw.include?("<woltlab-quote") && iteration < max_iterations
      iteration += 1
      converted = false

      # Find and convert innermost quotes (quotes that don't contain other quotes)
      raw =
        raw.gsub(%r{<woltlab-quote([^>]*)>((?:(?!<woltlab-quote).)*?)</woltlab-quote>}m) do
          attributes = $1
          content = $2
          converted = true

          # Extract author from data-author attribute
          author = nil
          author = $1 if attributes =~ /data-author="([^"]*)"/

          # Extract WoltLab postID from data-link
          # Format: https://forum.classic-computing.de/forum/index.php?...&postID=575716#post575716
          woltlab_post_id = nil
          woltlab_post_id = $1.to_i if attributes =~ /data-link="[^"]*postID=(\d+)/

          # Look up the Discourse post for this WoltLab post
          discourse_post_number = nil
          discourse_topic_id = nil

          if woltlab_post_id
            discourse_post_id = post_id_from_imported_post_id(woltlab_post_id)
            if discourse_post_id
              topic_info = topic_lookup_from_imported_post_id(woltlab_post_id)
              if topic_info
                discourse_topic_id = topic_info[:topic_id]
                discourse_post_number = topic_info[:post_number]
              end
            end
          end

          # Build Discourse quote HTML (matching native format)
          if author && !author.empty? && discourse_post_number && discourse_topic_id
            # Full quote with post reference
            <<~HTML.strip
              <aside class="quote no-group" data-username="#{author}" data-post="#{discourse_post_number}" data-topic="#{discourse_topic_id}">
                <div class="title">
                  <div class="quote-controls"></div>
                  #{author}:
                </div>
                <blockquote>
                  #{content}
                </blockquote>
              </aside>
            HTML
          elsif author && !author.empty?
            # Quote with just username (post not found or not imported yet)
            <<~HTML.strip
              <aside class="quote no-group" data-username="#{author}">
                <div class="title">
                  <div class="quote-controls"></div>
                  #{author}:
                </div>
                <blockquote>
                  #{content}
                </blockquote>
              </aside>
            HTML
          else
            # Quote without attribution
            <<~HTML.strip
              <aside class="quote no-group">
                <div class="title">
                  <div class="quote-controls"></div>
                </div>
                <blockquote>
                  #{content}
                </blockquote>
              </aside>
            HTML
          end
        end

      # If no conversions were made, break to prevent infinite loop
      break unless converted
    end

    raw
  end

  def normalize_raw!(raw)
    return "<missing>" if raw.blank?

    # Convert WoltLab quotes to blockquotes
    raw = convert_woltlab_quotes(raw)

    # Clean up BBCode remnants
    raw.gsub!(/\[color=[#a-z0-9]+\]/i, "")
    raw.gsub!(%r{\[/color\]}i, "")
    raw.gsub!(%r{\[signature\].+\[/signature\]}im, "")
    raw
  end

  def import_posts
    puts "", "=" * 80
    puts "IMPORTING POSTS AND TOPICS"
    puts "=" * 80

    # Build time filter clause
    time_filter = ""
    time_filter = " AND p.time >= #{@import_since_timestamp}" if @import_since_timestamp

    # Preload data into memory for faster lookups
    preload_attachments(time_filter)
    preload_orphaned_topic_data

    # Cache User objects to avoid repeated DB lookups
    @user_cache = {}

    total_count =
      mysql_query(
        "SELECT COUNT(*) AS count FROM wbb3_post p
         INNER JOIN wbb3_thread t ON p.threadID = t.threadID
         WHERE p.isDeleted = 0 AND t.isDeleted = 0#{time_filter}",
      ).first[
        "count"
      ]
    puts "\nTotal posts to import: #{total_count}"

    batches(BATCH_SIZE) do |offset|
      results =
        mysql_query(
          "SELECT p.postID, p.threadID, p.userID, p.username, p.subject,
                  p.message, p.time, p.ipAddress, p.attachments,
                  t.topic AS thread_title, t.boardID, t.firstPostID,
                  t.isClosed, t.isSticky, t.isDeleted AS thread_deleted
           FROM wbb3_post p
           INNER JOIN wbb3_thread t ON p.threadID = t.threadID
           WHERE p.isDeleted = 0 AND t.isDeleted = 0#{time_filter}
           ORDER BY p.time
           LIMIT #{BATCH_SIZE}
           OFFSET #{offset}",
        )

      break if results.size < 1

      next if all_records_exist?(:posts, results.map { |p| p["postID"].to_i })

      create_posts(results, total: total_count, offset: offset) do |post|
        user_id = user_id_from_imported_user_id(post["userID"])

        # If user not found, use system user or first admin as fallback
        unless user_id
          system_user = Discourse.system_user || User.where(admin: true).first
          if system_user
            user_id = system_user.id
          else
            puts "  ⚠ Skipping post #{post["postID"]} - no valid user found"
            next
          end
        end

        # Use category mapping (supports Level 4+ remapping)
        mapping = @wbb3_category_to_discourse[post["boardID"]]
        unless mapping
          puts "  ⚠ Skipping post #{post["postID"]} - category #{post["boardID"]} not mapped"
          next
        end

        category_id = mapping[:category_id]
        post_tags = mapping[:tags] || []

        # Clean and validate message
        raw_message = normalize_raw!(post["message"].to_s)
        if raw_message.blank? || raw_message == "<missing>"
          puts "  ⚠ Skipping post #{post["postID"]} - empty message"
          next
        end

        # Ensure minimum post length (Discourse default is 20 characters)
        # Add placeholder text if too short to preserve the post
        if raw_message.length < 20
          raw_message = raw_message + "\n\n" + ("." * (20 - raw_message.length))
        end

        # Process attachments if enabled
        if @import_attachments
          raw_message = process_attachments(post["postID"], user_id, raw_message)
        end

        mapped = {
          id: post["postID"],
          user_id: user_id,
          raw: raw_message,
          created_at: Time.zone.at(post["time"]),
          skip_guardian: true,
        }

        # First post of thread creates a topic
        if post["postID"] == post["firstPostID"]
          # Check if a topic with this import_id already exists (using cached data)
          topic_check = check_orphaned_topic(post["postID"])
          if topic_check
            if topic_check[:action] == :skip
              # Topic and post both exist, skip
              next
            elsif topic_check[:action] == :delete_orphan
              # Orphaned topic - delete it and retry
              existing_topic = Topic.find_by(id: topic_check[:topic_id])
              if existing_topic
                puts "  ⚠ Deleting orphaned topic #{existing_topic.id} (import_id: #{post["postID"]}) - will retry"
                existing_topic.destroy!
              end
            end
          end

          title =
            post["thread_title"].to_s.strip.presence || post["subject"].to_s.strip.presence ||
              "Untitled Topic"

          # Ensure title isn't too long and meets minimum requirements
          title = title[0..254] if title.length > 255

          # Skip if title is too short (Discourse requires minimum length)
          if title.length < 1
            puts "  ⚠ Skipping post #{post["postID"]} - title too short"
            next
          end

          mapped[:category] = category_id
          mapped[:title] = title
          mapped[:tags] = post_tags if post_tags.any?
          mapped[:pinned_at] = mapped[:created_at] if post["isSticky"] == 1
          # Don't close the topic during import - we need to add replies first
          # mapped[:closed] = true if post["isClosed"] == 1
        else
          # Subsequent posts are replies
          parent = topic_lookup_from_imported_post_id(post["firstPostID"])
          if parent
            mapped[:topic_id] = parent[:topic_id]
          else
            puts "  ⚠ Skipping reply #{post["postID"]} - parent post #{post["firstPostID"]} not found"
            next
          end
        end

        mapped
      end
    end

    puts "\n" + "=" * 80
    puts "POST IMPORT COMPLETE"
    puts "=" * 80
  end

  def import_likes
    puts "", "=" * 80
    puts "IMPORTING LIKES"
    puts "=" * 80

    # Find the objectTypeID for post likes
    post_type_result =
      mysql_query(
        "SELECT objectTypeID FROM wcf3_object_type
         WHERE objectType = 'com.woltlab.wbb.likeablePost'
         LIMIT 1",
      ).first

    unless post_type_result
      puts "  ⚠ Could not find post like objectTypeID, skipping likes import"
      return
    end

    post_object_type_id = post_type_result["objectTypeID"]
    puts "Post like objectTypeID: #{post_object_type_id}"

    # Build time filter clause for likes
    time_filter = ""
    if @import_since_timestamp
      time_filter = " AND time >= #{@import_since_timestamp}"
      filter_date = Time.at(@import_since_timestamp).strftime("%Y-%m-%d %H:%M:%S")
      puts "Filtering likes since #{filter_date}"
    end

    # Count total likes for posts (likeValue = 1 means "like", not "dislike")
    total_count =
      mysql_query(
        "SELECT COUNT(*) AS count
         FROM wcf3_like
         WHERE objectTypeID = #{post_object_type_id}
         AND likeValue = 1#{time_filter}",
      ).first[
        "count"
      ]
    puts "Total post likes to import: #{total_count}"

    return if total_count == 0

    created = 0
    skipped = 0

    batches(BATCH_SIZE) do |offset|
      likes =
        mysql_query(
          "SELECT likeID, objectID as postID, userID, time
           FROM wcf3_like
           WHERE objectTypeID = #{post_object_type_id}
           AND likeValue = 1#{time_filter}
           ORDER BY likeID
           LIMIT #{BATCH_SIZE}
           OFFSET #{offset}",
        )

      break if likes.size < 1

      # Preload all users and posts for this batch to avoid N+1 queries
      like_data =
        likes
          .map do |like|
            {
              user_id: user_id_from_imported_user_id(like["userID"]),
              post_id: post_id_from_imported_post_id(like["postID"]),
              time: like["time"],
            }
          end
          .compact

      # Batch load users and posts
      user_ids = like_data.map { |l| l[:user_id] }.compact.uniq
      post_ids = like_data.map { |l| l[:post_id] }.compact.uniq

      users_by_id = User.where(id: user_ids).index_by(&:id)
      posts_by_id = Post.where(id: post_ids).index_by(&:id)

      # Create likes using preloaded objects
      like_data.each do |data|
        begin
          unless data[:user_id] && data[:post_id]
            skipped += 1
            next
          end

          user = users_by_id[data[:user_id]]
          post = posts_by_id[data[:post_id]]

          if user && post
            # Create the like using PostActionCreator
            PostActionCreator.create(user, post, :like, created_at: Time.zone.at(data[:time]))
            created += 1
          else
            skipped += 1
          end
        rescue StandardError => e
          # Skip duplicate likes or other errors
          skipped += 1
          puts "  ⚠ Error creating like: #{e.message}" if offset == 0 # Only show errors in first batch
        end
      end

      print_status(created + skipped, total_count, get_start_time("likes"))
    end

    puts "\n\nLikes import complete!"
    puts "  Created: #{created}"
    puts "  Skipped: #{skipped}"
    puts "=" * 80
  end
end

# Only auto-execute if this script is run directly, not when required by another script
ImportScripts::Woltlab.new.perform if __FILE__ == $PROGRAM_NAME
