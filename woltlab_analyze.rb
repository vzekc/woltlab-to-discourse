# frozen_string_literal: true

# Quick diagnostic script to analyze WBB3 board hierarchy

require "mysql2"

DB_HOST = ENV["DB_HOST"] || "localhost"
DB_PORT = ENV["DB_PORT"] || "3306"
DB_NAME = ENV["DB_NAME"] || "forum"
DB_USER = ENV["DB_USER"] || "forum"
DB_PASSWORD = ENV["DB_PASSWORD"] || ""
TABLE_PREFIX = ENV["TABLE_PREFIX"] || "wbb1_1_"

begin
  client =
    Mysql2::Client.new(
      host: DB_HOST,
      port: DB_PORT,
      username: DB_USER,
      password: DB_PASSWORD,
      database: DB_NAME,
    )

  categories =
    client.query(
      "SELECT boardID, parentID, title FROM #{TABLE_PREFIX}board ORDER BY parentID, boardID",
    ).to_a

  puts "Total categories: #{categories.length}\n\n"

  # Group by parent
  by_parent = Hash.new { |h, k| h[k] = [] }
  categories.each { |cat| by_parent[cat["parentID"] || 0] << cat }

  # Recursive function to show hierarchy
  def show_tree(by_parent, parent_id, level = 0, max_level = 3)
    return if level > max_level
    children = by_parent[parent_id]
    return unless children && !children.empty?

    children.each do |cat|
      indent = "  " * level
      marker = level == 0 ? "▶" : "└─"
      puts "#{indent}#{marker} [#{cat["boardID"]}] #{cat["title"]}"
      show_tree(by_parent, cat["boardID"], level + 1, max_level)
    end
  end

  puts "HIERARCHY (max 4 levels):"
  puts "=" * 80
  show_tree(by_parent, 0)
  show_tree(by_parent, nil)

  # Count levels
  def count_levels(by_parent, board_id, current_level = 0)
    children = by_parent[board_id]
    return current_level unless children && !children.empty?

    children.map { |c| count_levels(by_parent, c["boardID"], current_level + 1) }.max
  end

  max_depth = [count_levels(by_parent, 0), count_levels(by_parent, nil)].compact.max
  puts "\n" + "=" * 80
  puts "Maximum hierarchy depth: #{max_depth + 1} levels"
  puts "Top-level categories (parentID = 0 or NULL): #{by_parent[0].length + by_parent[nil].length}"
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
