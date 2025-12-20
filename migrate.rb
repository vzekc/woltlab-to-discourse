# frozen_string_literal: true

# WoltLab Complete Migration Script
#
# Orchestrates the full migration from WoltLab to Discourse:
# 1. Import content (users, categories, posts, likes)
# 2. Import groups and permissions
#
# Required environment variables:
#   WOLTLAB_OAUTH2_SECRET - OAuth2 client secret for WoltLab authentication
#
# Usage:
#   export WOLTLAB_OAUTH2_SECRET="your-secret-here"
#   bundle exec rails runner script/import_scripts/woltlab/migrate.rb

# Ensure this script is run through Rails
unless defined?(Rails)
  puts "ERROR: This script must be run through Rails runner"
  puts ""
  puts "Usage:"
  puts "  export WOLTLAB_OAUTH2_SECRET=\"your-secret-here\""
  puts "  bundle exec rails runner script/import_scripts/woltlab/migrate.rb"
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
puts "WOLTLAB COMPLETE MIGRATION TO DISCOURSE"
puts "=" * 80
puts ""
puts "This script will run the complete migration in sequence:"
puts "  1. Configure site settings (locale, email notifications)"
puts "  2. Configure password migration plugin"
puts "  3. Configure OAuth2 authentication"
puts "  4. Synchronize attachments from remote server"
puts "  5. Import users, categories, posts, and likes"
puts "  6. Import groups, group memberships, and category permissions"
puts "  7. Import 2FA (TOTP authenticator) settings"
puts "  8. Configure vzekc-verlosung plugin"
puts "  9. Install and set Mint theme"
puts "  10. Flush caches"
puts ""
puts "Note: Attachment sync and content import respect IMPORT_SINCE filter"
puts ""
puts "=" * 80
puts ""

# Track overall start time
overall_start = Time.now

# Step 0: Set default locale to German
puts "\n" + "=" * 80
puts "STEP 1: CONFIGURING SITE SETTINGS"
puts "=" * 80
puts ""

begin
  # Set default locale to German (fallback for users without browser language detection)
  if SiteSetting.default_locale != "de"
    SiteSetting.default_locale = "de"
    puts "✓ Default locale set to German (de)"
  else
    puts "✓ Default locale already set to German (de)"
  end

  # Allow users to set their own locale (must be enabled first)
  if SiteSetting.allow_user_locale
    puts "✓ User locale selection already enabled"
  else
    SiteSetting.allow_user_locale = true
    puts "✓ User locale selection enabled"
  end

  # Enable browser language detection (requires allow_user_locale to be enabled first)
  if SiteSetting.set_locale_from_accept_language_header
    puts "✓ Browser language detection already enabled"
  else
    SiteSetting.set_locale_from_accept_language_header = true
    puts "✓ Browser language detection enabled"
  end

  puts ""

  # Configure email notification defaults (opt-in rather than opt-out)
  puts "Configuring email notification defaults..."
  SiteSetting.default_email_digest_frequency = 0 # never
  SiteSetting.disable_digest_emails = true # disable digest emails site-wide
  SiteSetting.default_email_mailing_list_mode = false # disable mailing list mode
  puts "✓ Email notifications disabled by default (users can opt-in)"

  # Update existing users to disable email notifications
  updated_count =
    UserOption.where(
      "email_level != 2 OR email_messages_level != 2 OR email_digests = true OR mailing_list_mode = true",
    ).update_all(
      email_level: 2, # never
      email_messages_level: 2, # never
      email_digests: false, # no digest emails
      mailing_list_mode: false, # no mailing list mode
    )
  puts "✓ Disabled email notifications for #{updated_count} existing users" if updated_count > 0
rescue => e
  puts "⚠ Could not configure settings: #{e.message}"
end

puts ""

# Step 1: Enable password migration plugin
puts "\n" + "=" * 80
puts "STEP 2: CONFIGURING PASSWORD MIGRATION"
puts "=" * 80
puts ""

plugin_path = Rails.root.join("plugins", "discourse-migratepassword", "plugin.rb")
unless File.exist?(plugin_path)
  puts "✗ discourse-migratepassword plugin not found"
  exit 1
end

puts "✓ discourse-migratepassword plugin found"

# Check if the plugin setting is available (plugin must be loaded by Rails)
unless defined?(SiteSetting) && SiteSetting.respond_to?(:migratepassword_enabled)
  puts "✗ Plugin found but not loaded by Rails"
  exit 1
end

if SiteSetting.migratepassword_enabled
  puts "✓ Password migration already enabled"
else
  SiteSetting.migratepassword_enabled = true
  puts "✓ Password migration enabled"
end

# Set password policies
SiteSetting.min_password_length = 8
SiteSetting.migratepassword_allow_insecure_passwords = true

puts ""
puts "Users will be able to log in with their WoltLab passwords."
puts "Passwords will be automatically converted on first successful login."

# Step 3: Configure OAuth2 authentication
puts "\n" + "=" * 80
puts "STEP 3: CONFIGURING OAUTH2 AUTHENTICATION"
puts "=" * 80
puts ""

oauth_plugin_path = Rails.root.join("plugins", "discourse-oauth2-basic", "plugin.rb")
unless File.exist?(oauth_plugin_path)
  puts "✗ discourse-oauth2-basic plugin not found"
  exit 1
end

puts "✓ discourse-oauth2-basic plugin found"

# Check if the plugin setting is available (plugin must be loaded by Rails)
unless defined?(SiteSetting) && SiteSetting.respond_to?(:oauth2_enabled)
  puts "✗ Plugin found but not loaded by Rails"
  exit 1
end

# Check for required environment variable
if ENV["WOLTLAB_OAUTH2_SECRET"].blank?
  puts "✗ WOLTLAB_OAUTH2_SECRET environment variable not set"
  puts ""
  puts "The WoltLab OAuth2 client secret must be provided via environment variable for security."
  puts ""
  puts "Please set it before running this script:"
  puts ""
  puts "  export WOLTLAB_OAUTH2_SECRET=\"your-secret-here\""
  puts ""
  puts "Then run the migration again."
  puts ""
  exit 1
end

puts "✓ OAuth2 client secret loaded from environment variable"

# Configure OAuth2 settings for WoltLab integration
SiteSetting.oauth2_enabled = true
SiteSetting.oauth2_client_id = "discourse"
SiteSetting.oauth2_client_secret = ENV["WOLTLAB_OAUTH2_SECRET"]
SiteSetting.oauth2_authorize_url = "https://forum.classic-computing.de/index.php?oauth2-authorize/"
SiteSetting.oauth2_token_url = "https://forum.classic-computing.de/index.php?oauth2-token/"
SiteSetting.oauth2_token_url_method = "POST"
SiteSetting.oauth2_user_json_url = "https://forum.classic-computing.de/index.php?open-id-user-information/"
SiteSetting.oauth2_user_json_url_method = "GET"
SiteSetting.oauth2_scope = "openid profile email"
SiteSetting.oauth2_button_title = "Über das Woltlab-Forum anmelden"

# Configure user info mapping
SiteSetting.oauth2_callback_user_info_paths = "id"
SiteSetting.oauth2_json_user_id_path = "sub"
SiteSetting.oauth2_json_username_path = "nickname"
SiteSetting.oauth2_json_email_path = "email"
SiteSetting.oauth2_fetch_user_details = true

# Configure email reception
SiteSetting.reply_by_email_address = "reply+%{reply_key}@classic-computing.de.de"
SiteSetting.manual_polling_enabled = true
SiteSetting.reply_by_email_enabled = true

# Trust emails from OAuth2 provider as verified (WoltLab doesn't set email_verified field)
SiteSetting.oauth2_email_verified = true

# Allow users with 2FA to log in via OAuth2 without entering their 2FA code
# (trusting WoltLab as the authentication provider)
SiteSetting.enforce_second_factor_on_external_auth = false

# Enable debug mode (can be disabled in production)
SiteSetting.oauth2_debug_auth = true

puts "✓ OAuth2 configured for WoltLab integration"
puts ""
puts "Users will be able to log in using their WoltLab OAuth2 credentials."

# Step 4: Sync attachments from remote server (optional)
puts "\n" + "=" * 80
puts "STEP 4: SYNCHRONIZING ATTACHMENTS"
puts "=" * 80
puts ""

sync_start = Time.now
sync_duration = 0

begin
  require_relative "sync_attachments"
  AttachmentSynchronizer.new.execute
  sync_duration = Time.now - sync_start
  puts "\n✓ Attachment sync completed in #{format_duration(sync_duration)}"
rescue StandardError => e
  puts "\n⚠ Attachment sync failed: #{e.message}"
  puts "  Continuing with import anyway..."
  puts "  You can sync files manually later with:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/sync_attachments.rb"
end

# Step 5: Import content
puts "\n" + "=" * 80
puts "STEP 5: IMPORTING CONTENT (users, categories, posts, likes)"
puts "=" * 80
puts ""

content_start = Time.now

begin
  require_relative "import_contents"
  ImportScripts::Woltlab.new.perform
  content_duration = Time.now - content_start
  puts "\n✓ Content import completed in #{format_duration(content_duration)}"
rescue StandardError => e
  puts "\n✗ Content import failed: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

# Step 6: Import groups and permissions
puts "\n" + "=" * 80
puts "STEP 6: IMPORTING GROUPS AND PERMISSIONS"
puts "=" * 80
puts ""

permissions_start = Time.now

begin
  require_relative "import_groups_and_permissions"
  Rails.application.eager_load!
  PermissionMigrator.new.execute
  permissions_duration = Time.now - permissions_start
  puts "\n✓ Groups and permissions import completed in #{format_duration(permissions_duration)}"
rescue StandardError => e
  puts "\n✗ Groups and permissions import failed: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  puts "\nNote: Content was imported successfully. You can retry permissions separately:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/import_groups_and_permissions.rb"
  exit 1
end

# Step 7: Import 2FA settings
puts "\n" + "=" * 80
puts "STEP 7: IMPORTING 2FA SETTINGS"
puts "=" * 80
puts ""

twofa_start = Time.now
twofa_duration = 0

begin
  require_relative "import_2fa"
  Rails.application.eager_load!
  migrator = TwoFactorMigrator.new
  migrator.execute
  migrator.close
  twofa_duration = Time.now - twofa_start
  puts "\n✓ 2FA import completed in #{format_duration(twofa_duration)}"
rescue StandardError => e
  puts "\n⚠ 2FA import failed: #{e.message}"
  puts "  Continuing with migration anyway..."
  puts "  You can retry 2FA import separately:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/import_2fa.rb"
end

# Step 8: Configure vzekc-verlosung plugin
puts "\n" + "=" * 80
puts "STEP 8: CONFIGURING VZEKC-VERLOSUNG PLUGIN"
puts "=" * 80
puts ""

verlosung_start = Time.now
verlosung_duration = 0

begin
  # Find the "Spenden an den Verein" category (WoltLab board ID 40)
  cat_field = CategoryCustomField.find_by(name: "import_id", value: "40")
  spenden_category = cat_field&.category

  if spenden_category
    puts "✓ Found 'Spenden an den Verein' category (ID: #{spenden_category.id})"

    # Enable the vzekc-verlosung plugin
    if SiteSetting.respond_to?(:vzekc_verlosung_enabled)
      if SiteSetting.vzekc_verlosung_enabled
        puts "✓ vzekc-verlosung plugin already enabled"
      else
        SiteSetting.vzekc_verlosung_enabled = true
        puts "✓ vzekc-verlosung plugin enabled"
      end

      # Set the category for the plugin
      if SiteSetting.vzekc_verlosung_category_id != spenden_category.id
        SiteSetting.vzekc_verlosung_category_id = spenden_category.id
        puts "✓ vzekc-verlosung plugin configured for category '#{spenden_category.name}'"
      else
        puts "✓ vzekc-verlosung plugin already configured for category '#{spenden_category.name}'"
      end
    else
      puts "⚠ vzekc-verlosung plugin settings not available"
      puts "  Plugin may not be installed or loaded. Skipping configuration."
    end
  else
    puts "⚠ 'Spenden an den Verein' category not found"
    puts "  This may be because:"
    puts "    - The category was not imported (check IMPORT_SINCE filter)"
    puts "    - The category import failed"
    puts "  Skipping vzekc-verlosung configuration."
  end

  verlosung_duration = Time.now - verlosung_start
rescue StandardError => e
  puts "\n⚠ vzekc-verlosung configuration failed: #{e.message}"
  puts "  Continuing with migration anyway..."
end

# Step 9: Install and set Mint theme
puts "\n" + "=" * 80
puts "STEP 9: INSTALLING MINT THEME"
puts "=" * 80
puts ""

theme_start = Time.now
theme_duration = 0

MINT_THEME_URL = "https://github.com/discourse/discourse-mint-theme"

begin
  existing_mint = Theme.find_by(name: "Mint Theme")

  if existing_mint
    puts "✓ Mint theme already installed (ID: #{existing_mint.id})"
  else
    puts "Installing Mint theme from #{MINT_THEME_URL}..."
    theme = RemoteTheme.import_theme(MINT_THEME_URL)
    puts "✓ Theme installed successfully (ID: #{theme.id})"
    existing_mint = theme
  end

  # Set as default theme
  if SiteSetting.default_theme_id != existing_mint.id
    SiteSetting.default_theme_id = existing_mint.id
    puts "✓ Mint theme set as default"
  else
    puts "✓ Mint theme already set as default"
  end

  # Make it user-selectable
  unless existing_mint.user_selectable
    existing_mint.update!(user_selectable: true)
    puts "✓ Mint theme set as user selectable"
  end

  theme_duration = Time.now - theme_start
rescue StandardError => e
  puts "\n⚠ Theme installation failed: #{e.message}"
  puts "  Continuing with migration anyway..."
  puts "  You can install the theme manually later from:"
  puts "  #{MINT_THEME_URL}"
end

# Flush caches
puts "\n" + "=" * 80
puts "STEP 10: FLUSHING CACHES"
puts "=" * 80
puts ""

puts "Clearing Rails cache..."
Rails.cache.clear

puts "Clearing Discourse cache..."
Discourse.cache.clear

puts "Clearing query cache..."
ActiveRecord::Base.connection.clear_query_cache

puts "✓ Caches cleared"

# Summary
overall_duration = Time.now - overall_start

puts "\n" + "=" * 80
puts "MIGRATION COMPLETE"
puts "=" * 80
puts ""
puts "Summary:"
puts "  Default locale: German (de, fallback)"
puts "  Browser language detection: Enabled"
puts "  User locale selection: Enabled"
puts "  Email notifications: Disabled by default (opt-in)"
puts "  Password migration: Configured"
puts "  OAuth2 authentication: Configured"
puts "  Attachment sync: #{sync_duration > 0 ? format_duration(sync_duration) : "Failed or skipped"}"
puts "  Content import: #{format_duration(content_duration)}"
puts "  Permissions import: #{format_duration(permissions_duration)}"
puts "  2FA import: #{twofa_duration > 0 ? format_duration(twofa_duration) : "Failed or skipped"}"
puts "  vzekc-verlosung plugin: #{verlosung_duration > 0 ? format_duration(verlosung_duration) : "Failed or skipped"}"
puts "  Theme installation: #{theme_duration > 0 ? format_duration(theme_duration) : "Failed or skipped"}"
puts "  Total time: #{format_duration(overall_duration)}"
puts ""
puts "=" * 80
puts ""
puts "Next steps:"
puts "  1. Test user login with WoltLab password"
puts "  2. Test user login with WoltLab OAuth2"
puts "  3. Verify migrated data in Discourse admin panel"
puts "  4. Check category permissions are correctly set"
puts "  5. Test user group memberships"
puts "  6. Review imported content for any issues"
puts "  7. Verify Mint theme is active and looks correct"
puts ""
puts "=" * 80
