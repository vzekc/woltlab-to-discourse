# frozen_string_literal: true

# WoltLab 2FA Migration Script
#
# Migrates TOTP (Time-based One-Time Password) settings from WoltLab to Discourse
#
# What gets migrated:
# - TOTP secrets (authenticator app configurations)
# - Device names
# - Fresh backup codes are generated for each user
#
# What does NOT get migrated:
# - Old backup codes (they're one-way hashed and cannot be decrypted)
#
# Usage:
#   bundle exec rails runner script/import_scripts/woltlab/import_2fa.rb

# Ensure this script is run through Rails
unless defined?(Rails)
  puts "ERROR: This script must be run through Rails runner"
  puts ""
  puts "Usage:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/import_2fa.rb"
  puts ""
  exit 1
end

require_relative "import_contents"
require "mysql2"
require "rotp"

class TwoFactorMigrator
  def initialize
    puts "=" * 80
    puts "WOLTLAB 2FA MIGRATION"
    puts "=" * 80
    puts ""
    puts "This script migrates TOTP (authenticator app) settings from WoltLab to Discourse."
    puts "Users will be able to continue using their existing authenticator apps."
    puts ""
    puts "Note: Backup codes will be regenerated (old WoltLab codes will not work)."
    puts "=" * 80
    puts ""

    @woltlab_db =
      Mysql2::Client.new(
        host: ImportScripts::Woltlab::DB_HOST,
        port: ImportScripts::Woltlab::DB_PORT,
        username: ImportScripts::Woltlab::DB_USER,
        password: ImportScripts::Woltlab::DB_PASSWORD,
        database: ImportScripts::Woltlab::DB_NAME,
      )

    @stats = { migrated: 0, skipped_no_user: 0, skipped_already_exists: 0, failed: 0 }
  end

  def execute
    migrate_totp_settings
    print_summary
  end

  def migrate_totp_settings
    puts "STEP 1: Migrating TOTP Settings"
    puts "=" * 80
    puts ""

    # Get all users with TOTP enabled from WoltLab
    totp_users =
      @woltlab_db.query(
        "SELECT DISTINCT u.userID, u.username, u.email
         FROM wcf3_user u
         JOIN wcf3_user_multifactor mf ON u.userID = mf.userID
         JOIN wcf3_object_type ot ON mf.objectTypeID = ot.objectTypeID
         WHERE ot.objectType = 'com.woltlab.wcf.multifactor.totp'
           AND u.multifactorActive = 1
         ORDER BY u.userID",
      ).to_a

    puts "Found #{totp_users.length} users with TOTP enabled in WoltLab"
    puts ""

    totp_users.each_with_index do |woltlab_user, index|
      woltlab_user_id = woltlab_user["userID"]
      username = woltlab_user["username"]

      # Progress indicator
      if (index + 1) % 10 == 0 || index == 0
        puts "Processing user #{index + 1}/#{totp_users.length}: #{username}"
      end

      # Find corresponding Discourse user
      discourse_user = find_discourse_user(woltlab_user_id)
      unless discourse_user
        @stats[:skipped_no_user] += 1
        puts "  ⚠ Skipped #{username} - user not found in Discourse" if (index + 1) % 10 == 0
        next
      end

      # Check if user already has TOTP in Discourse
      if discourse_user.totp_enabled?
        @stats[:skipped_already_exists] += 1
        puts "  ℹ Skipped #{username} - already has TOTP in Discourse"
        next
      end

      # Get TOTP devices for this user
      totp_devices =
        @woltlab_db.query(
          "SELECT t.setupID, t.deviceID, t.deviceName, t.secret, t.createTime
           FROM wcf3_user_multifactor_totp t
           JOIN wcf3_user_multifactor mf ON t.setupID = mf.setupID
           WHERE mf.userID = #{woltlab_user_id}
           ORDER BY t.createTime ASC",
        ).to_a

      if totp_devices.empty?
        @stats[:skipped_no_user] += 1
        next
      end

      # Process each TOTP device (users can have multiple devices)
      totp_devices.each do |device|
        begin
          migrate_totp_device(discourse_user, device, username)
        rescue StandardError => e
          @stats[:failed] += 1
          puts "  ✗ Failed to migrate TOTP for #{username}: #{e.message}"
          puts "    #{e.backtrace.first}"
        end
      end
    end

    puts ""
    puts "TOTP migration completed"
  end

  def migrate_totp_device(discourse_user, device, username)
    device_name = device["deviceName"] || "Imported TOTP Device"
    secret_binary = device["secret"]

    # WoltLab stores TOTP secrets as raw binary (16 bytes)
    # We need to Base32-encode them for Discourse/ROTP
    base32_secret = ROTP::Base32.encode(secret_binary)

    # Verify the secret is valid by creating a TOTP object
    totp = ROTP::TOTP.new(base32_secret, issuer: SiteSetting.title)

    # Create UserSecondFactor record for TOTP
    second_factor =
      UserSecondFactor.create!(
        user_id: discourse_user.id,
        method: UserSecondFactor.methods[:totp],
        data: base32_secret,
        enabled: true,
        name: device_name,
        created_at: Time.at(device["createTime"]),
      )

    # Generate backup codes for the user (if they don't have any)
    if discourse_user.user_second_factors.backup_codes.empty?
      backup_codes = discourse_user.generate_backup_codes
      puts "  ✓ Migrated TOTP for #{username} (#{device_name})"
      puts "    Generated #{backup_codes.length} new backup codes"
    else
      puts "  ✓ Migrated TOTP for #{username} (#{device_name})"
    end

    @stats[:migrated] += 1
  end

  def find_discourse_user(woltlab_user_id)
    user_field = UserCustomField.find_by(name: "import_id", value: woltlab_user_id.to_s)
    return nil unless user_field

    User.find_by(id: user_field.user_id)
  end

  def print_summary
    puts ""
    puts "=" * 80
    puts "2FA MIGRATION SUMMARY"
    puts "=" * 80
    puts ""
    puts "Results:"
    puts "  ✓ Successfully migrated: #{@stats[:migrated]}"
    puts "  ⚠ Skipped (user not in Discourse): #{@stats[:skipped_no_user]}"
    puts "  ℹ Skipped (already has 2FA): #{@stats[:skipped_already_exists]}"
    puts "  ✗ Failed: #{@stats[:failed]}"
    puts ""
    puts "Total users processed: #{@stats.values.sum}"
    puts ""

    if @stats[:migrated] > 0
      puts "IMPORTANT: Users with migrated 2FA"
      puts "-" * 80
      puts "✓ Can continue using their existing authenticator apps"
      puts "✓ Their TOTP codes will work immediately"
      puts "⚠ Old WoltLab backup codes will NOT work"
      puts "⚠ New backup codes have been generated"
      puts ""
      puts "ACTION REQUIRED:"
      puts "- Notify users to view and save their new backup codes"
      puts "- Users can access backup codes at: /my/preferences/security"
      puts ""
    end

    puts "=" * 80
  end

  def close
    @woltlab_db.close if @woltlab_db
  end
end

# Only auto-execute if this script is run directly, not when required by another script
if __FILE__ == $PROGRAM_NAME
  Rails.application.eager_load!
  migrator = TwoFactorMigrator.new
  begin
    migrator.execute
  ensure
    migrator.close
  end
end
