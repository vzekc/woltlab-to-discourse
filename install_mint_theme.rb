# frozen_string_literal: true

# Install and set Discourse Mint Theme as default
#
# This script installs the official Mint theme from GitHub and sets it as the
# default theme for all users.
#
# Usage:
#   bundle exec rails runner script/import_scripts/woltlab/install_mint_theme.rb

unless defined?(Rails)
  puts "ERROR: This script must be run through Rails runner"
  puts ""
  puts "Usage:"
  puts "  bundle exec rails runner script/import_scripts/woltlab/install_mint_theme.rb"
  puts ""
  exit 1
end

puts "=" * 80
puts "INSTALLING MINT THEME"
puts "=" * 80
puts ""

MINT_THEME_URL = "https://github.com/discourse/discourse-mint-theme"

# Check if Mint theme is already installed
existing_mint = Theme.find_by(name: "Mint")

if existing_mint
  puts "Mint theme already installed (ID: #{existing_mint.id})"
  puts ""
else
  puts "Installing Mint theme from #{MINT_THEME_URL}..."
  puts ""

  begin
    # Import the theme from GitHub
    theme = RemoteTheme.import_theme(MINT_THEME_URL)

    puts "✓ Theme installed successfully"
    puts "  Theme ID: #{theme.id}"
    puts "  Theme name: #{theme.name}"
    puts ""

    existing_mint = theme
  rescue StandardError => e
    puts "✗ Failed to install theme: #{e.message}"
    puts e.backtrace.first(5)
    exit 1
  end
end

# Set as default theme
puts "Setting Mint as default theme..."
SiteSetting.default_theme_id = existing_mint.id

# Make it user-selectable
existing_mint.update!(user_selectable: true)

puts "✓ Mint theme set as default"
puts ""

# Show current theme configuration
puts "=" * 80
puts "THEME CONFIGURATION"
puts "=" * 80
puts ""
puts "Default theme: #{Theme.find(SiteSetting.default_theme_id).name} (ID: #{SiteSetting.default_theme_id})"
puts "Mint theme ID: #{existing_mint.id}"
puts "User selectable: #{existing_mint.user_selectable}"
puts ""

# List all available themes
puts "All installed themes:"
Theme
  .where(component: false)
  .order(:name)
  .each do |t|
    is_default = (t.id == SiteSetting.default_theme_id)
    puts "  - #{t.name} (ID: #{t.id})#{is_default ? " [DEFAULT]" : ""}"
  end
puts ""

puts "=" * 80
puts "INSTALLATION COMPLETE"
puts "=" * 80
