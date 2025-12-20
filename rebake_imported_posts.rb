# frozen_string_literal: true

# Rebake all imported posts that contain upload:// references
# This is useful when posts were imported but images aren't displaying

puts "Finding all imported posts with upload references..."

# Get all post IDs that have import_id custom field
imported_post_ids = PostCustomField.where(name: "import_id").pluck(:post_id).uniq

# Find posts with upload references among imported posts
posts_with_uploads = Post.where(id: imported_post_ids).where("raw LIKE ?", "%upload://%")

total_count = posts_with_uploads.count
puts "Found #{total_count} posts with upload references"

if total_count == 0
  puts "No posts to rebake"
  exit
end

puts "\nRebaking posts..."

rebaked = 0
posts_with_uploads.find_each do |post|
  print "."
  post.rebake!
  rebaked += 1

  puts " #{rebaked}/#{total_count}" if rebaked % 100 == 0
end

puts "\n\nDone! Rebaked #{rebaked} posts"
