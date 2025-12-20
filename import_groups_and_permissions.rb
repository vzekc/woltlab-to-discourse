# frozen_string_literal: true

# WoltLab Permission Migration Script
#
# Migrates user groups and board permissions from WoltLab to Discourse
#
# Usage:
#   bundle exec rails runner script/import_scripts/woltlab/import_groups_and_permissions.rb

# Ensure this script is run through Rails
unless defined?(Rails)
  puts "ERROR: This script must be run through Rails runner"
  puts ""
  puts "Usage:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/import_groups_and_permissions.rb"
  puts ""
  exit 1
end

require_relative "import_contents"
require "mysql2"

class PermissionMigrator
  def initialize
    puts "=" * 80
    puts "WOLTLAB PERMISSION MIGRATION"
    puts "=" * 80

    @woltlab_db =
      Mysql2::Client.new(
        host: ImportScripts::Woltlab::DB_HOST,
        port: ImportScripts::Woltlab::DB_PORT,
        username: ImportScripts::Woltlab::DB_USER,
        password: ImportScripts::Woltlab::DB_PASSWORD,
        database: ImportScripts::Woltlab::DB_NAME,
      )

    # Preload translations for performance
    preload_translations
  end

  def execute
    validate_max_username_length
    build_board_hierarchy
    migrate_groups
    migrate_group_memberships
    migrate_category_permissions
  end

  def validate_max_username_length
    puts "\n" + "=" * 80
    puts "VALIDATING DISCOURSE CONFIGURATION"
    puts "=" * 80

    # Find longest group name in WoltLab
    result =
      @woltlab_db.query(
        "SELECT groupName, LENGTH(groupName) as name_length
         FROM wcf3_user_group
         WHERE groupID NOT IN (1, 2, 3, 4, 5, 9, 21)
         ORDER BY LENGTH(groupName) DESC
         LIMIT 1",
      ).first

    if result
      longest_name = result["groupName"]
      longest_length = result["name_length"]
      current_max = SiteSetting.max_username_length

      puts "\nLongest group name: '#{longest_name}' (#{longest_length} characters)"
      puts "Discourse max_username_length: #{current_max}"

      if longest_length > current_max
        # Automatically adjust the setting
        new_max = longest_length + 10
        puts "\n⚠ Adjusting max_username_length setting:"
        puts "  Current: #{current_max}"
        puts "  Required: #{new_max}"
        puts ""

        # Show groups that require the change
        long_groups =
          @woltlab_db.query(
            "SELECT groupName, LENGTH(groupName) as name_length
             FROM wcf3_user_group
             WHERE groupID NOT IN (1, 2, 3, 4, 5, 9, 21)
               AND LENGTH(groupName) > #{current_max}
             ORDER BY LENGTH(groupName) DESC",
          ).to_a

        puts "Groups requiring longer limit (#{long_groups.length} groups):"
        long_groups.each do |group|
          puts "  - #{group["groupName"]} (#{group["name_length"]} chars)"
        end
        puts ""

        # Set the new value
        SiteSetting.max_username_length = new_max
        puts "  ✓ Updated max_username_length to #{new_max}"
      else
        puts "  ✓ All group names fit within the current limit"
      end
    end
  end

  def build_board_hierarchy
    puts "\n" + "=" * 80
    puts "BUILDING BOARD HIERARCHY"
    puts "=" * 80

    # Query all boards to build parent-child relationship map
    boards =
      @woltlab_db.query(
        "SELECT boardID, title, parentID
         FROM wbb3_board
         ORDER BY boardID",
      ).to_a

    @board_hierarchy = {}
    @board_info = {}

    boards.each do |board|
      board_id = board["boardID"]
      parent_id = board["parentID"]
      title = board["title"]

      @board_hierarchy[board_id] = parent_id
      @board_info[board_id] = title
    end

    puts "Built hierarchy map for #{@board_hierarchy.length} boards"
  end

  def migrate_groups
    puts "\n" + "=" * 80
    puts "STEP 1: Migrating Groups"
    puts "=" * 80

    # Query WoltLab groups (excluding system groups 1-5, 9, 21)
    groups =
      @woltlab_db.query(
        "SELECT groupID, groupName, groupDescription
         FROM wcf3_user_group
         WHERE groupID NOT IN (1, 2, 3, 4, 5, 9, 21)
         ORDER BY groupID",
      ).to_a

    puts "Found #{groups.length} WoltLab groups to migrate"

    groups.each do |woltlab_group|
      group_id = woltlab_group["groupID"]
      original_name = woltlab_group["groupName"]
      description = woltlab_group["groupDescription"]

      # Translate language keys to German (for system groups like group 34)
      if original_name.start_with?("wcf.")
        translated = translate_language_key(original_name)
        if translated
          original_name = translated
        else
          puts "  ⚠ Warning: Could not translate language key '#{woltlab_group["groupName"]}' for group #{group_id}"
        end
      end

      # Normalize group name for Discourse
      # - Replace spaces with underscores
      # - Transliterate German umlauts (ö→o, ä→a, ü→u, ß→ss)
      # - Remove any remaining invalid characters
      normalized_name = normalize_group_name(original_name)

      # Check if group already exists (by normalized name)
      existing_group = Group.find_by(name: normalized_name)
      if existing_group
        puts "  ✓ Group '#{normalized_name}' already exists (ID: #{existing_group.id})"
        puts "    (original name: '#{original_name}')" if original_name != normalized_name
        store_group_mapping(group_id, existing_group.id)
        next
      end

      # Create Discourse group
      discourse_group =
        Group.create!(
          name: normalized_name,
          full_name: original_name, # Store original name
          bio_raw: description.to_s.presence || "Imported from WoltLab",
          visibility_level: Group.visibility_levels[:members], # Members can see group
          members_visibility_level: Group.visibility_levels[:members],
          mentionable_level: Group::ALIAS_LEVELS[:everyone],
        )

      # Store custom field for tracking
      discourse_group.custom_fields["woltlab_group_id"] = group_id
      discourse_group.save_custom_fields

      store_group_mapping(group_id, discourse_group.id)

      if original_name != normalized_name
        puts "  ✓ Created group '#{normalized_name}' (WoltLab ID: #{group_id}, Discourse ID: #{discourse_group.id})"
        puts "    (original name: '#{original_name}')"
      else
        puts "  ✓ Created group '#{normalized_name}' (WoltLab ID: #{group_id}, Discourse ID: #{discourse_group.id})"
      end
    end
  end

  def migrate_group_memberships
    sync_group_memberships(remove_stale: false)
  end

  def sync_group_memberships(remove_stale: true)
    puts "\n" + "=" * 80
    puts "SYNCING GROUP MEMBERSHIPS"
    puts "=" * 80
    puts "Mode: #{remove_stale ? "Full sync (add + remove)" : "Add only"}"

    # Ensure group mapping is built (needed for standalone sync)
    build_group_mapping_from_custom_fields if @group_mapping.nil? || @group_mapping.empty?

    # Build a lookup of import_id -> discourse_user_id for efficiency
    puts "\nBuilding user import ID lookup..."
    user_import_map = {}
    UserCustomField
      .where(name: "import_id")
      .find_each { |ucf| user_import_map[ucf.value.to_i] = ucf.user_id }
    puts "Found #{user_import_map.size} imported users"

    # Query all Woltlab memberships (excluding system groups)
    woltlab_memberships =
      @woltlab_db.query(
        "SELECT userID, groupID
         FROM wcf3_user_to_group
         WHERE groupID NOT IN (1, 2, 3, 4, 5, 9, 21)
         ORDER BY groupID, userID",
      ).to_a

    puts "Found #{woltlab_memberships.length} group memberships in Woltlab"

    # Build expected memberships: { discourse_group_id => Set[discourse_user_ids] }
    expected_memberships = Hash.new { |h, k| h[k] = Set.new }
    skipped_users = 0
    skipped_groups = 0

    woltlab_memberships.each do |membership|
      woltlab_user_id = membership["userID"]
      woltlab_group_id = membership["groupID"]

      discourse_user_id = user_import_map[woltlab_user_id]
      discourse_group_id = @group_mapping[woltlab_group_id]

      unless discourse_user_id
        skipped_users += 1
        next
      end

      unless discourse_group_id
        skipped_groups += 1
        next
      end

      expected_memberships[discourse_group_id].add(discourse_user_id)
    end

    puts "Skipped #{skipped_users} memberships (user not imported)"
    puts "Skipped #{skipped_groups} memberships (group not mapped)"

    added_count = 0
    removed_count = 0
    unchanged_count = 0

    # Process each migrated group
    @group_mapping.each_value do |discourse_group_id|
      discourse_group = Group.find_by(id: discourse_group_id)
      next unless discourse_group

      expected_user_ids = expected_memberships[discourse_group_id]
      current_user_ids = Set.new(discourse_group.group_users.pluck(:user_id))

      # Add missing memberships
      users_to_add = expected_user_ids - current_user_ids
      users_to_add.each do |user_id|
        user = User.find_by(id: user_id)
        next unless user
        discourse_group.add(user)
        added_count += 1
      end

      # Remove stale memberships (only for imported users)
      if remove_stale
        # Only remove users who were imported from Woltlab (have import_id)
        imported_current_user_ids = current_user_ids & Set.new(user_import_map.values)
        users_to_remove = imported_current_user_ids - expected_user_ids

        users_to_remove.each do |user_id|
          user = User.find_by(id: user_id)
          next unless user
          discourse_group.remove(user)
          removed_count += 1
        end
      end

      unchanged_count += (current_user_ids & expected_user_ids).size
    end

    puts "\n" + "-" * 40
    puts "Sync Results:"
    puts "  ✓ Added: #{added_count} memberships"
    puts "  ✓ Removed: #{removed_count} memberships" if remove_stale
    puts "  ✓ Unchanged: #{unchanged_count} memberships"
    puts "-" * 40
  end

  def build_group_mapping_from_custom_fields
    puts "Building group mapping from custom fields..."
    @group_mapping = {}

    GroupCustomField
      .where(name: "woltlab_group_id")
      .find_each do |gcf|
        woltlab_id = gcf.value.to_i
        @group_mapping[woltlab_id] = gcf.group_id
      end

    puts "Found #{@group_mapping.size} mapped groups"
  end

  def get_inherited_permissions(board_id)
    # Walk up the parent chain to find ACL permissions
    current_board = board_id
    visited = Set.new

    while current_board && !visited.include?(current_board)
      visited.add(current_board)

      # Check if this board has explicit ACL entries (using preloaded data)
      permissions = @acl_permissions_by_board[current_board]

      # If we found permissions, return them with the source board
      return { permissions: permissions, inherited_from: current_board } if permissions&.any?

      # Move to parent board
      current_board = @board_hierarchy[current_board]
    end

    # No permissions found in hierarchy
    nil
  end

  def apply_permissions_to_category(discourse_category, group_perms, source_info)
    discourse_category_id = discourse_category.id

    # Analyze permissions to determine Discourse access level
    group_perms.each do |woltlab_group_id, perms|
      group_name = perms["groupName"]

      # Translate language keys to German (for system groups)
      if group_name.start_with?("wcf.")
        translated = translate_language_key(group_name)
        group_name = translated if translated
      end

      # Skip system groups
      next if [1, 2, 3, 4, 5, 9, 21].include?(woltlab_group_id)

      can_view = perms["canViewBoard"] == 1 && perms["canEnterBoard"] == 1
      can_read = perms["canReadThread"] == 1
      can_reply = perms["canReplyThread"] == 1
      can_create = perms["canStartThread"] == 1

      if can_view && can_read
        # Determine permission level
        permission_type =
          if can_create && can_reply
            CategoryGroup.permission_types[:full]
          elsif can_reply
            CategoryGroup.permission_types[:create_post]
          else
            CategoryGroup.permission_types[:readonly]
          end

        # Find Discourse group
        discourse_group_id = @group_mapping[woltlab_group_id]
        next unless discourse_group_id

        discourse_group = Group.find_by(id: discourse_group_id)
        next unless discourse_group

        # Check if permission already exists
        existing_perm =
          CategoryGroup.find_by(category_id: discourse_category_id, group_id: discourse_group_id)

        if existing_perm
          # Update if permission type changed
          if existing_perm.permission_type != permission_type
            old_type = existing_perm.permission_type
            existing_perm.update!(permission_type: permission_type)
            puts "    ✓ Updated group '#{group_name}' to #{permission_type_name(permission_type)} access (was #{permission_type_name(old_type)}) #{source_info}"
          else
            puts "    ✓ Permission already correct for group '#{group_name}' #{source_info}"
          end
        else
          # Create category permission
          CategoryGroup.create!(
            category_id: discourse_category_id,
            group_id: discourse_group_id,
            permission_type: permission_type,
          )
          puts "    ✓ Added group '#{group_name}' with #{permission_type_name(permission_type)} access #{source_info}"
        end
      elsif !can_view
        # Group is explicitly denied - ensure they don't have access
        discourse_group_id = @group_mapping[woltlab_group_id]
        next unless discourse_group_id

        # Remove any existing permissions
        CategoryGroup.where(
          category_id: discourse_category_id,
          group_id: discourse_group_id,
        ).destroy_all
        puts "    ✓ Removed access for group '#{group_name}' (denied in WoltLab) #{source_info}"
      end
    end

    # Important: Check if category should be private (restricted access)
    # If everyone/guests are denied, remove the default "everyone" permission
    default_group_denied =
      group_perms[1] && group_perms[1]["canViewBoard"] == 0 && group_perms[1]["canEnterBoard"] == 0

    if default_group_denied
      # Remove "everyone" group permission to make category private
      # Use Group::AUTO_GROUPS[:everyone] to get the correct group ID (works regardless of locale)
      everyone_group_id = Group::AUTO_GROUPS[:everyone]
      everyone_group = Group.find_by(id: everyone_group_id)

      if everyone_group
        CategoryGroup.where(
          category_id: discourse_category_id,
          group_id: everyone_group.id,
        ).destroy_all

        # Set read_restricted flag to actually enforce permissions
        discourse_category.update!(read_restricted: true) unless discourse_category.read_restricted
        puts "    ✓ Made category private (removed 'everyone' access) #{source_info}"
      end
    end
  end

  def migrate_category_permissions
    puts "\n" + "=" * 80
    puts "STEP 3: Migrating Category Permissions"
    puts "=" * 80

    # Preload all ACL permissions to avoid N+1 queries during inheritance walk
    puts "\nPreloading all ACL permissions..."
    all_acl_permissions =
      @woltlab_db.query(
        "SELECT a.objectID, a.groupID, g.groupName, a.optionValue, o.optionName
         FROM wcf3_acl_option_to_group a
         JOIN wcf3_acl_option o ON a.optionID = o.optionID
         JOIN wcf3_user_group g ON a.groupID = g.groupID
         WHERE o.optionName IN ('canViewBoard', 'canEnterBoard', 'canReadThread', 'canStartThread', 'canReplyThread')
         ORDER BY a.objectID, a.groupID, o.optionName",
      ).to_a

    # Group permissions by board ID for fast lookup
    @acl_permissions_by_board = Hash.new { |h, k| h[k] = [] }
    all_acl_permissions.each { |perm| @acl_permissions_by_board[perm["objectID"]] << perm }
    puts "Preloaded #{all_acl_permissions.length} ACL entries for #{@acl_permissions_by_board.keys.length} boards"

    # Step 3a: Process boards with explicit ACL permissions
    puts "\n" + "-" * 80
    puts "STEP 3a: Processing boards with explicit ACL permissions"
    puts "-" * 80

    boards_with_acls =
      @woltlab_db.query(
        "SELECT DISTINCT a.objectID as boardID, b.title
         FROM wcf3_acl_option_to_group a
         JOIN wbb3_board b ON a.objectID = b.boardID
         JOIN wcf3_acl_option o ON a.optionID = o.optionID
         WHERE o.optionName IN ('canViewBoard', 'canEnterBoard')
         ORDER BY a.objectID",
      ).to_a

    explicit_acl_board_ids = boards_with_acls.map { |b| b["boardID"] }
    puts "Found #{boards_with_acls.length} boards with explicit ACL permissions"

    boards_with_acls.each do |board|
      board_id = board["boardID"]
      board_title = board["title"]

      # Find corresponding Discourse category
      discourse_category_id = category_id_from_imported_id(board_id)
      unless discourse_category_id
        puts "  ⚠ Skipping board '#{board_title}' (ID: #{board_id}) - not imported to Discourse"
        next
      end

      discourse_category = Category.find_by(id: discourse_category_id)
      unless discourse_category
        puts "  ⚠ Skipping board '#{board_title}' (ID: #{board_id}) - category not found"
        next
      end

      puts "\n  Processing category '#{discourse_category.name}' (WoltLab board #{board_id})"

      # Get ACL permissions for this board (from preloaded data)
      permissions = @acl_permissions_by_board[board_id] || []

      # Group permissions by groupID
      group_perms = Hash.new { |h, k| h[k] = {} }
      permissions.each do |perm|
        group_perms[perm["groupID"]][perm["optionName"]] = perm["optionValue"]
        group_perms[perm["groupID"]]["groupName"] = perm["groupName"]
      end

      # Apply permissions using helper method
      apply_permissions_to_category(discourse_category, group_perms, "")
    end

    # Step 3b: Process boards with inherited permissions
    puts "\n" + "-" * 80
    puts "STEP 3b: Processing boards with inherited permissions"
    puts "-" * 80

    # Get all imported categories
    all_imported_categories =
      CategoryCustomField
        .where(name: "import_id")
        .pluck(:category_id, :value)
        .map { |cat_id, board_id| [cat_id, board_id.to_i] }

    inherited_count = 0
    skipped_count = 0

    all_imported_categories.each do |discourse_category_id, board_id|
      # Skip boards that have explicit ACLs (already processed)
      next if explicit_acl_board_ids.include?(board_id)

      # Check if this board has inherited permissions
      inherited = get_inherited_permissions(board_id)
      next unless inherited

      inherited_from = inherited[:inherited_from]
      permissions = inherited[:permissions]

      discourse_category = Category.find_by(id: discourse_category_id)
      unless discourse_category
        skipped_count += 1
        next
      end

      board_title = @board_info[board_id] || "Unknown"
      parent_title = @board_info[inherited_from] || "Unknown"

      puts "\n  Processing category '#{discourse_category.name}' (WoltLab board #{board_id})"
      puts "    Inheriting permissions from parent board #{inherited_from} ('#{parent_title}')"

      # Group permissions by groupID
      group_perms = Hash.new { |h, k| h[k] = {} }
      permissions.each do |perm|
        group_perms[perm["groupID"]][perm["optionName"]] = perm["optionValue"]
        group_perms[perm["groupID"]]["groupName"] = perm["groupName"]
      end

      # Apply inherited permissions
      source_info = "(inherited from board #{inherited_from})"
      apply_permissions_to_category(discourse_category, group_perms, source_info)
      inherited_count += 1
    end

    puts "\n" + "-" * 80
    puts "Processed #{inherited_count} categories with inherited permissions"
    puts "Skipped #{skipped_count} categories (not found in Discourse)"
    puts "-" * 80

    puts "\n" + "=" * 80
    puts "PERMISSION MIGRATION COMPLETE"
    puts "=" * 80
    puts "Summary:"
    puts "  - Explicit ACL boards: #{boards_with_acls.length}"
    puts "  - Inherited permission boards: #{inherited_count}"
    puts "  - Total boards with permissions: #{boards_with_acls.length + inherited_count}"
    puts "=" * 80
  end

  private

  def preload_translations
    # Get German language ID
    lang_result =
      @woltlab_db.query(
        "SELECT languageID FROM wcf3_language WHERE languageCode = 'de' LIMIT 1",
      ).first
    return unless lang_result

    lang_id = lang_result["languageID"]

    # Preload all translations for group names (wcf.* language keys)
    translations =
      @woltlab_db.query(
        "SELECT languageItem, languageItemValue
         FROM wcf3_language_item
         WHERE languageID = #{lang_id}
           AND (languageItem LIKE 'wcf.acp.group.group%'
                OR languageItem LIKE 'wcf.user.group.%')",
      ).to_a

    @translation_cache = {}
    translations.each { |t| @translation_cache[t["languageItem"]] = t["languageItemValue"] }

    puts "Preloaded #{@translation_cache.size} group name translations"
  end

  def translate_language_key(language_key)
    # Use preloaded translations (instant hash lookup)
    @translation_cache[language_key]
  end

  def normalize_group_name(name)
    # Step 1: Transliterate German special characters
    normalized = name.dup
    normalized.gsub!("ä", "ae")
    normalized.gsub!("ö", "oe")
    normalized.gsub!("ü", "ue")
    normalized.gsub!("Ä", "Ae")
    normalized.gsub!("Ö", "Oe")
    normalized.gsub!("Ü", "Ue")
    normalized.gsub!("ß", "ss")

    # Step 2: Replace spaces with underscores
    normalized.gsub!(" ", "_")

    # Step 3: Remove any characters that aren't allowed
    # Discourse allows: letters, numbers, dashes, dots, underscores
    normalized.gsub!(/[^\w.-]/, "")

    # Step 4: Ensure it doesn't start/end with special chars
    normalized.gsub!(/^[^a-zA-Z0-9_]+/, "")
    normalized.gsub!(/[^a-zA-Z0-9]+$/, "")

    # Step 5: Remove consecutive special characters
    normalized.gsub!(/[-_.]{2,}/, "_")

    # Step 6: Use User.normalize_username for final cleanup
    User.normalize_username(normalized)
  end

  def store_group_mapping(woltlab_id, discourse_id)
    @group_mapping ||= {}
    @group_mapping[woltlab_id] = discourse_id
  end

  def user_id_from_imported_id(woltlab_user_id)
    user_field = UserCustomField.find_by(name: "import_id", value: woltlab_user_id.to_s)
    user_field&.user_id
  end

  def category_id_from_imported_id(woltlab_board_id)
    cat_field = CategoryCustomField.find_by(name: "import_id", value: woltlab_board_id.to_s)
    cat_field&.category_id
  end

  def permission_type_name(type)
    case type
    when CategoryGroup.permission_types[:full]
      "full"
    when CategoryGroup.permission_types[:create_post]
      "create/reply"
    when CategoryGroup.permission_types[:readonly]
      "read-only"
    else
      "unknown"
    end
  end
end

# Only auto-execute if this script is run directly, not when required by another script
if __FILE__ == $PROGRAM_NAME
  Rails.application.eager_load!
  migrator = PermissionMigrator.new

  # Check for command line arguments
  case ARGV[0]
  when "sync-memberships"
    # Sync group memberships only (add + remove stale)
    migrator.sync_group_memberships(remove_stale: true)
  when "add-memberships"
    # Add missing memberships only (no removals)
    migrator.sync_group_memberships(remove_stale: false)
  when "groups-only"
    # Migrate groups and memberships, skip category permissions
    migrator.validate_max_username_length
    migrator.migrate_groups
    migrator.migrate_group_memberships
  else
    # Full migration (default)
    migrator.execute
  end
end
