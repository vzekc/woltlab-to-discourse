# WoltLab Burning Board 3 (WBB3) to Discourse Importer

This script imports users, categories, posts, topics, and attachments from WoltLab Burning Board 3 (WBB3) forum software into Discourse.

## Features

- **Users**: Import from `wcf3_user` table with banned user suspension and optional activity-based filtering
- **User Profiles**: Imports profile data (signatures, profile views, user titles, custom fields, avatars)
- **Trust Levels**: Automatic assignment based on WoltLab activity points (posts, threads, likes received)
  - TL0 (New User): 0-4 points (inactive users, lurkers)
  - TL1 (Basic User): 5-171 points (normal members, ~10th-74th percentile)
  - TL2 (Member): 172-1342 points (established contributors, ~75th-89th percentile)
  - TL3 (Regular): 1343+ points (power users, top 10%)
  - TL4 (Leader): Manually granted to moderators/admins
- **Password Migration**: Seamless password migration using WoltLab's double bcrypt hashes - users can log in with their existing passwords without reset
- **Categories**: 5-level WBB3 hierarchy mapped to Discourse structure
  - WBB3 Level 1 → Discourse tags (e.g., "Besucherecke", "Computerecke")
  - WBB3 Level 2 → Discourse top-level categories
  - WBB3 Level 3 → Discourse subcategories
  - WBB3 Level 4+ → Discourse tags + posts remapped to nearest Level 2/3 parent
- **Posts and Topics**: Full import with chronological ordering and automatic category remapping
- **Tags**: Automatically created from Level 1 and Level 4+ categories
- **Attachments**: Files and images from `wcf3_attachment` and `wcf3_file` tables
- **Custom Emojis**: Import WoltLab smilies as Discourse custom emojis with category grouping
- **Time filtering**: Option to import only recent data - filters both posts (by creation time) and users (by last activity)
- **Selective import**: Control what to import (users, categories, posts, likes) for testing and incremental imports

## Prerequisites

### 1. Database Access

Your WoltLab MySQL database must be accessible. You'll need:
- Database host, port, name
- Database username and **password** (required)

### 2. File System Access (Optional, for attachments)

If you want to import attachments, you need access to the WoltLab files directory, typically:
```
/path/to/woltlab/files/
```

This directory contains files stored as:
```
files/<hash[0..1]>/<hash[2..3]>/<fileID>-<hash>.<ext>
```

For example:
```
files/81/a3/231744-81a3c2c7012025522ab030e13ddd7842d259bf690d3b155a9124d245fff3c558.jpg
```

**Note:** The hash prefix is 4 characters split into two directories (`81/a3`), and the file extension is appended.

### 3. Ruby Gems

The importer requires the `mysql2` gem. Install it:
```bash
IMPORT=1 bundle install
```

### 4. Password Migration Plugin (Optional, Recommended)

To enable seamless password migration (users can log in with their WoltLab passwords without reset), install the `discourse-migratepassword` plugin:

```bash
cd /path/to/discourse
git clone https://github.com/communiteq/discourse-migratepassword.git plugins/discourse-migratepassword
```

Then rebuild Discourse:
```bash
# If using Docker:
./launcher rebuild app

# If using development environment:
bin/rails assets:precompile
# Restart your Discourse server
```

**Automatic Configuration:** The `migrate.rb` script automatically enables the plugin when you run the migration. You don't need to manually configure anything - just rebuild Discourse and run the migration.

**How It Works:**
- During import, WoltLab password hashes are stored in users' `import_pass` custom field
- On first login, the plugin validates the password against the WoltLab hash
- If successful, the password is converted to Discourse's native format
- The user continues seamlessly without knowing a migration occurred
- The old hash is removed after successful conversion

**Note:** If you skip this plugin, users will need to use the "Forgot Password" feature to set new passwords after migration.

### 5. Attachment Synchronization (Optional)

If you want to import avatars, cover photos, and post attachments, you need to sync the files from your WoltLab server.

**Automatic Sync (Recommended):**

The `migrate.rb` script automatically syncs attachments from `forum.classic-computing.de` with sensible defaults. It uses the same `IMPORT_SINCE` filter as the content import to sync only the files you need:

```bash
# Defaults (no need to set if migrating from forum.classic-computing.de):
# REMOTE_HOST="forum.classic-computing.de"
# REMOTE_BASE="/var/www/forum/html"
# LOCAL_PATH="./"

# Optional: sync only files needed for filtered import
export IMPORT_SINCE="12months"   # Sync files for posts/users from last 12 months

# Run the migration
bundle exec rails runner script/import_scripts/woltlab/migrate.rb
```

The sync script syncs files from three locations on the remote server to `./woltlabImports/`:
- **Avatars**: `images/avatars/{hash[0..1]}/{avatarID}-{hash}.{ext}` → `./woltlabImports/images/avatars/`
- **Cover Photos**: `images/coverPhotos/{hash[0..1]}/{userID}-{hash}.{ext}` → `./woltlabImports/images/coverPhotos/`
- **Post Attachments (images)**: `_data/public/files/{hash[0..1]}/{hash[2..3]}/{fileID}-{hash}.{ext}` → `./woltlabImports/_data/public/files/`
- **Post Attachments (non-images)**: `_data/private/files/{hash[0..1]}/{hash[2..3]}/{fileID}-{hash}.bin` → `./woltlabImports/_data/private/files/`

All paths on the remote are relative to `REMOTE_BASE` and synced to `LOCAL_PATH` (default: `./woltlabImports`).

**Override defaults (if migrating from different server):**

```bash
export REMOTE_HOST="your.woltlab-server.com"
export REMOTE_BASE="/var/www/woltlab"
export LOCAL_PATH="./"             # Optional, defaults to ./
export IMPORT_SINCE="12months"     # Optional, sync only recent files
```

**How it works:**
- Scans database for avatars, cover photos, and post attachments needed for import
- Generates a file list based on your import filters (e.g., IMPORT_SINCE)
- Uses rsync's `--files-from` option to efficiently sync only needed files in one command
- Incrementally syncs - only transfers files that don't exist locally or have changed

**Manual Sync:**

If you prefer to sync files separately:

```bash
# Sync all files
bundle exec rails runner script/import_scripts/woltlab/sync_attachments.rb

# Sync only files for filtered import
IMPORT_SINCE="12months" \
bundle exec rails runner script/import_scripts/woltlab/sync_attachments.rb
```

**Without rsync:**

If you can't use rsync, you can manually copy the `files/` directory from your WoltLab installation to your Discourse development environment.

### 6. Discourse Configuration (For Groups & Permissions Import)

**Automatic Configuration:** The migration script automatically adjusts Discourse's `max_username_length` setting if WoltLab group names exceed the current limit. No manual configuration is required.

WoltLab group names can be longer than Discourse's default 20-character limit. The import script will:
- Detect if any group names exceed the current `max_username_length`
- Automatically increase the setting to accommodate the longest group name
- Display which groups required the adjustment
- Continue with the migration

**Manual Configuration (Optional):**

If you prefer to set this manually before running the migration:

**Via Admin Panel:**
1. Log into Discourse as admin
2. Navigate to: `/admin/site_settings/category/users`
3. Search for: `max_username_length`
4. Change from `20` to `50` (or higher, based on your longest group name)
5. Click "Save"

**Via Rails Console:**
```bash
bundle exec rails c
SiteSetting.max_username_length = 50
exit
```

**Group Name Normalization:**

WoltLab group names may contain spaces and German special characters that Discourse doesn't allow. The importer automatically normalizes group names by:
- Transliterating German characters (ä→ae, ö→oe, ü→ue, ß→ss)
- Replacing spaces with underscores
- Removing invalid characters
- Storing the original WoltLab name in the `full_name` field

Examples:
- "Arbeitsgruppe Online" → "Arbeitsgruppe_Online"
- "Vereinsmitglieder_mit_größer_Galerie" → "Vereinsmitglieder_mit_groesser_Galerie"

This happens automatically - no configuration needed.

**Permission Inheritance:**

The migration script automatically handles WoltLab's permission inheritance. If a board has no explicit ACL entries, the script will walk up the parent board hierarchy to find inherited permissions and apply them to the Discourse category. This ensures that child boards (like "Kassenwart", "Mitgliederverwaltung" under "Vorstand") maintain the same restricted access as their parent boards.

For detailed information about permission migration, see [PERMISSIONS.md](PERMISSIONS.md).

## Environment Variables

All configuration is done via environment variables:

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_HOST` | MySQL database host | `127.0.0.1` or `localhost` |
| `DB_PORT` | MySQL database port | `3306` |
| `DB_NAME` | Database name | `forum` |
| `DB_USER` | Database username | `forum` |
| `DB_PASSWORD` | **Database password (REQUIRED)** | `your_password` |
| `IMPORT` | Enable import mode | `1` |
| `RAILS_ENV` | Rails environment | `development` |

**Important**: `DB_PASSWORD` must be set in the environment for the importer to work, even if your database has no password (use empty string).

### Optional Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `IMPORT_SINCE` | Filter import by date (applies to posts, users, and likes)<br>- **Posts**: created on or after this date<br>- **Users**: active (lastActivityTime) on or after this date<br>- **Likes**: created on or after this date | `7days`, `2weeks`, `6months`, `1year`, or Unix timestamp |
| `IMPORT_TYPES` | Control what to import (comma-separated list)<br>Valid values: `users`, `categories`, `posts`, `likes`<br>**Default: `users` only** (categories, posts, and likes are skipped by default) | `users,categories,posts,likes` (all)<br>`users` (only users - default)<br>`posts,likes` (posts and likes only) |
| `SKIP_FILES` | Skip all file imports (avatars, cover photos, attachments) for quick test runs<br>Default: files are imported if available | `1` (skip all files) |
| `TABLE_PREFIX` | WoltLab table prefix (default: `wbb3_`) | `wbb1_1_` for legacy installations |

### Performance Optimization Variables

For large databases (100,000+ posts), these environment variables significantly improve import speed:

| Variable | Description | Recommended Value |
|----------|-------------|-------------------|
| `DISCOURSE_DISABLE_SIDEKIQ` | Disable background job queuing during import | `1` |

**Performance Tips:**

1. **Disable Sidekiq**: Set `DISCOURSE_DISABLE_SIDEKIQ=1` to skip background job queuing
   - Improves speed by 20-30%
   - Jobs will be processed after import completes

2. **Incremental Imports**: Use `IMPORT_SINCE` for testing or incremental updates
   - Test with `IMPORT_SINCE=7days` before full import
   - Verify category mapping and attachment handling
   - Then run full import without `IMPORT_SINCE`

3. **File Import Strategy**: For very large databases with many files
   - Quick test run: Use `SKIP_FILES=1` to skip all file imports (avatars, cover photos, attachments)
   - Full import: Run without `SKIP_FILES` after syncing files with `sync_attachments.rb`

**Expected Performance:**
- Without optimization: ~500 posts/minute
- With optimizations: ~750-1,200 posts/minute
- For 562,000 posts: 8-12 hours with optimizations vs 18-20 hours without

## Usage

### Full Import (Recommended: Use migrate.rb)

The easiest way to run a complete migration is to use the orchestrator script, which automatically syncs files and runs all import steps:

```bash
bundle exec rails runner script/import_scripts/woltlab/migrate.rb
```

This will:
1. Sync files from the remote server (avatars, cover photos, attachments)
2. Import groups and permissions
3. Import users, categories, posts, and likes
4. Configure password migration

### Manual Import (Direct Content Import)

If you need more control or want to run specific steps manually:

```bash
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=forum \
DB_USER=forum \
DB_PASSWORD=your_password \
DISCOURSE_DISABLE_SIDEKIQ=1 \
RAILS_ENV=development \
IMPORT=1 \
bundle exec ruby script/import_scripts/woltlab/import_contents.rb
```

**Note**: For file imports (avatars, cover photos, attachments) to work, you must first sync files using `sync_attachments.rb` (see "Attachment Synchronization" section above). Files are imported from local directories (`./images/`, `./files/`) by default.

**Profile Import**: User profile import is enabled by default and includes:
- **About Me** text (WoltLab `aboutMe` → Discourse `bio_raw`)
- **Location** (WoltLab `location` → Discourse `location`)
- **Website** (WoltLab `homepage` → Discourse `website`)
- **Profile view counts** (WoltLab `profileHits` → Discourse `profile.views`)
- **User titles** (WoltLab `userTitle` → Discourse `user.title`)
- **Custom fields**: All WoltLab user options with proper German labels from `wcf3_language_item`
  - Standard fields: Birthday, Gender, Occupation, Hobbies, social media accounts
  - Custom fields: Lieblingscomputer, Mitgliedsnummer, E-Mail-Adresse, Videokanal, Adresse für Marktplatz, etc.
  - System settings (without labels) are automatically skipped
- **Avatars** (from local `./woltlabImports/images/avatars/` directory)
- **Cover photos** (from local `./woltlabImports/images/coverPhotos/` directory)

**Note**: User signatures (from `wcf3_user.signature`) are NOT imported as they are post-specific, not profile data. Avatars and cover photos require files to be synced first using `sync_attachments.rb` to `./woltlabImports/`.

### Selective Import (Import Specific Types Only)

**Default Behavior**: By default, only **users** are imported. Categories, posts, and likes are skipped unless explicitly requested via `IMPORT_TYPES`.

You can control what gets imported using the `IMPORT_TYPES` variable. This is useful for:
- Testing specific parts of the import
- Incremental imports (e.g., updating users separately from posts)
- Troubleshooting import issues

```bash
# Import only users (this is the default behavior)
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=forum \
DB_USER=forum \
DB_PASSWORD=your_password \
RAILS_ENV=development \
IMPORT=1 \
bundle exec ruby script/import_scripts/woltlab/import_contents.rb

# Import everything (users, categories, posts, and likes)
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=forum \
DB_USER=forum \
DB_PASSWORD=your_password \
IMPORT_TYPES=users,categories,posts,likes \
RAILS_ENV=development \
IMPORT=1 \
bundle exec ruby script/import_scripts/woltlab/import_contents.rb

# Import only posts and likes (requires users and categories already imported)
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=forum \
DB_USER=forum \
DB_PASSWORD=your_password \
IMPORT_TYPES=posts,likes \
RAILS_ENV=development \
IMPORT=1 \
bundle exec ruby script/import_scripts/woltlab/import_contents.rb

# Import users and categories only (no posts)
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=forum \
DB_USER=forum \
DB_PASSWORD=your_password \
IMPORT_TYPES=users,categories \
RAILS_ENV=development \
IMPORT=1 \
bundle exec ruby script/import_scripts/woltlab/import_contents.rb
```

**Valid types**: `users`, `categories`, `posts`, `likes`

**Important Notes**:
- If you import `posts` without first importing `users`, posts will be attributed to the system user
- If you import `posts` without first importing `categories`, the import may fail if category mappings don't exist
- If you import `likes` without first importing `posts`, no likes will be created

### Import Recent Data Only (Testing)

For testing, you can import only recent data to avoid processing the entire database. The `IMPORT_SINCE` filter applies to posts, users, and likes:

- **Posts**: Filters by post creation time (`p.time`)
- **Users**: Filters by last activity time (`lastActivityTime`)
- **Likes**: Filters by like creation time (`time`)

```bash
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=forum \
DB_USER=forum \
DB_PASSWORD=your_password \
IMPORT_SINCE=7days \
DISCOURSE_DISABLE_SIDEKIQ=1 \
RAILS_ENV=development \
IMPORT=1 \
bundle exec ruby script/import_scripts/woltlab/import_contents.rb
```

Supported formats for `IMPORT_SINCE`:
- `7days` - Last 7 days
- `2weeks` - Last 2 weeks
- `1month` - Last month
- `12months` - Last 12 months
- `1year` - Last year
- `1704067200` - Unix timestamp (January 1, 2024)

**Example**: Using `IMPORT_SINCE=12months` will import:
- All posts created in the last 12 months
- All users who were active (logged in or posted) in the last 12 months
- All likes created in the last 12 months

**Combining Options**: You can combine `IMPORT_TYPES` and `IMPORT_SINCE`:
```bash
# Import only users who were active in the last 6 months
IMPORT_TYPES=users IMPORT_SINCE=6months bundle exec ruby script/import_scripts/woltlab/import_contents.rb
```

## Attachment Conversion

When `FILES_DIR` is provided, the importer processes attachments from the `wcf3_attachment` and `wcf3_file` tables.

### How Attachments are Imported

1. **File Lookup**: For each post, the importer queries `wcf3_attachment` for attachments where `objectTypeID` = post type and `objectID` = post ID
   - Uses `className LIKE '%Attachment%'` to find the correct objectTypeID (224)
2. **File Location**: Files are located using the 4-character hash prefix structure:
   - `files/<hash[0..1]>/<hash[2..3]>/<fileID>-<hash>.<ext>`
3. **Upload to Discourse**: Files are uploaded using Discourse's upload system
4. **Inline Conversion**: WoltLab `<woltlab-metacode data-name="attach">` tags are parsed and converted to HTML img/anchor tags
5. **Post Content**: Inline attachments are shown in place, unused attachments are appended at the bottom

### Attachment Display

The importer preserves WoltLab's inline attachment placement by:

1. **Parsing inline tags**: `<woltlab-metacode data-name="attach" data-attributes="base64">` tags are decoded
2. **Converting to HTML**: WoltLab content is HTML, so attachments are converted to HTML tags
   - Images: `<img src="/uploads/path/file.jpg" alt="filename.jpg">`
   - Other files: `<a href="/uploads/path/file.pdf">document.pdf</a>`
3. **Appending unused attachments**: Any attachments not used inline are added at the bottom

**Example output:**

```html
<p>Here's the image inline:</p>

<img src="/uploads/default/original/1X/abc123.png" alt="screenshot.png">

<p>And here's some text after the image.</p>

<hr>
<p><strong>Attachments:</strong></p>

<p><a href="/uploads/default/original/1X/def456.pdf">manual.pdf</a> (1.2 MB)</p>
```

### Statistics

From a typical WoltLab installation:
- **Total attachments**: 230,858
- **Post attachments**: 173,264 (object type: `com.woltlab.wbb.post`)
- **Conversation attachments**: 40,747
- **Other types**: ~16,847

Only post attachments (`com.woltlab.wbb.post`) are imported.

## Custom Emoji Import

The importer includes a separate script to import WoltLab smilies as Discourse custom emojis.

### import_custom_emojis.rb

Imports all WoltLab smilies from the `wcf3_smiley` table as Discourse custom emojis, preserving category grouping.

```bash
IMPORT=1 \
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=forum \
DB_USER=forum \
DB_PASSWORD=$(cat /tmp/pw.txt) \
RAILS_ENV=development \
bundle exec rails runner "load 'script/import_scripts/woltlab/import_custom_emojis.rb'"
```

**Features:**
- Downloads smiley images from WoltLab server automatically
- Preserves WoltLab categories as Discourse emoji groups (e.g., `"bits&bytes"`, `"extras"`, `"party"`)
- Handles duplicate smiley codes by falling back to smiley title
- Sanitizes emoji names following Discourse conventions
- Creates upload records for all images
- Clears emoji cache automatically

**Configuration:**
- `BASE_URL`: Base URL for smiley images (default: `https://forum.classic-computing.de/`)
- All database connection variables (same as main importer)

**Output:**
- Shows progress for each emoji
- Reports created, skipped, and error counts
- Provides URL to view imported emojis in admin panel

**Example Results:**
From a typical WoltLab installation with 282 smilies:
- Created: 276 emojis
- Skipped: 3 duplicates
- Errors: 3 (temporary connection issues)
- Groups: `default`, `extras`, `liebe`, `hass`, `kommentar`, `party`, `bits&bytes`

**Usage in Posts:**
After import, emojis are available using `:emoji_name:` syntax (e.g., `:wacko:`, `:enterprise:`, `:amiga2:`)

**View Imported Emojis:**
Navigate to `/admin/customize/emojis` in your Discourse instance

## Utility Scripts

Several utility scripts are provided for diagnostics and cleanup:

### woltlab_analyze.rb

Analyzes and visualizes the WBB3 category hierarchy before import.

```bash
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=forum DB_USER=forum DB_PASSWORD=password \
ruby script/import_scripts/woltlab/woltlab_analyze.rb
```

**Output:**
- Shows all 5 levels of category hierarchy
- Displays category counts per level
- Visualizes parent-child relationships

### diagnose_attachments.rb

Diagnostic tool to examine attachment structure and file storage.

```bash
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=forum DB_USER=forum DB_PASSWORD=password \
ruby script/import_scripts/woltlab/diagnose_attachments.rb
```

**Shows:**
- Total attachment count
- Object types and their counts
- Sample attachments with file paths
- File storage structure

### cleanup_orphaned_topics.rb

Cleans up orphaned topics (topics without first posts) that may remain from failed imports.

```bash
RAILS_ENV=development bundle exec rails runner script/import_scripts/woltlab/cleanup_orphaned_topics.rb
```

**What it does:**
- Finds all topics with `posts_count > 0` but no post with `post_number = 1`
- Deletes these orphaned topics
- Shows progress for each deletion

**When to use:**
- After a failed import attempt
- When seeing errors about missing parent posts
- Before re-running the import

### cleanup_orphaned_category_fields.rb

Removes orphaned category custom field mappings.

```bash
RAILS_ENV=development bundle exec rails runner script/import_scripts/woltlab/cleanup_orphaned_category_fields.rb
```

**Purpose:**
- Cleans up `category_custom_fields` records that reference deleted categories
- Prevents "already imported" false positives

### cleanup_orphaned_user_fields.rb

Removes orphaned user custom field mappings.

```bash
RAILS_ENV=development bundle exec rails runner script/import_scripts/woltlab/cleanup_orphaned_user_fields.rb
```

**Purpose:**
- Cleans up `user_custom_fields` records that reference deleted users
- Cleans up orphaned `UserEmail` records

### reset_dev.sh

Complete development environment reset script. Removes all uploaded files and recreates the database from template.

```bash
# Run from the discourse root directory
script/import_scripts/woltlab/reset_dev.sh
```

**What it does:**
1. Deletes all uploads from `public/uploads/default/*`
2. Deletes all backups from `public/backups/*`
3. Deletes temp caches from `tmp/` directories
4. Drops the `discourse_development` database
5. Recreates it from the `discourse-template` template database

**Safety Features:**
- Shows clear warning about what will be deleted
- Requires explicit confirmation (y/N) before proceeding
- Shows progress for each cleanup step

**When to use:**
- Before re-running a complete import from scratch
- To clean up after multiple test imports
- To restore development database to pristine state

**Prerequisites:**
- Must have a `discourse-template` database created beforehand
- Run from the discourse root directory

## Category Mapping and Tags

WoltLab's 5-level category hierarchy is mapped to Discourse's 2-level structure with tags:

### How Categories are Mapped

1. **Level 1** (e.g., "Besucherecke", "Computerecke", "Infoecke"):
   - Created as Discourse **tags**
   - Applied to all topics in descendant categories

2. **Level 2** → Discourse top-level categories
   - Directly imported as Discourse categories
   - Topics get Level 1 tag applied

3. **Level 3** → Discourse subcategories
   - Imported as subcategories of Level 2 parents
   - Topics get Level 1 tag applied

4. **Level 4+** (e.g., "Showroom", "DEC Professional"):
   - Created as Discourse **tags**
   - Posts are **remapped** to nearest Level 2 or 3 parent category
   - Topics get both Level 1 tag AND Level 4+ tag applied

### Example Mapping

**WoltLab hierarchy:**
```
Computerecke (Level 1)
  └── Klassische Computer (Level 2)
      └── Sonstige (Level 3)
          └── Showroom (Level 4)
              └── DEC Professional (Level 5)
```

**Discourse result:**
- **Category**: "Klassische Computer" > "Sonstige" (Level 2 > Level 3)
- **Tags**: `computerecke` (Level 1), `showroom` (Level 4), `dec-professional` (Level 5)

Posts from "DEC Professional" (Level 5) appear in "Sonstige" (Level 3) with appropriate tags.

## Import Process

The import runs in this order:

1. **Users** (`wcf3_user`)
   - Maps WoltLab user IDs to Discourse user IDs
   - Suspends banned users
   - **Preserves admin/moderator roles**: Automatically grants Discourse admin status to WoltLab administrators (group 4) and moderator status to WoltLab moderators (group 5)
   - Can be filtered by `IMPORT_SINCE` (filters by `lastActivityTime`)
   - Stores mapping in `user_custom_fields` with `name='import_id'`
   - **Profile data** (always imported from `wcf3_user_option_value` and `wcf3_language_item`):
     - About Me text (`aboutMe` → `profile.bio_raw`)
     - Location (`location` → `profile.location`)
     - Website (`homepage` → `profile.website`)
     - Profile view counts (`profileHits` → `profile.views`)
     - User titles (`userTitle` → `user.title`)
     - Custom fields: All WoltLab user options with German labels (Lieblingscomputer, Birthday, Gender, etc.)
     - Avatars and cover photos (downloaded from WoltLab server if `AVATAR_BASE_URL` is set)

2. **Categories and Tags** (`wbb3_board`)
   - Creates Level 2 as Discourse top-level categories
   - Creates Level 3 as Discourse subcategories
   - Creates tags for Level 1 and Level 4+ categories
   - Builds mapping from ALL WBB3 categories to Discourse categories
   - Stores mapping in `category_custom_fields` with `name='import_id'`

3. **Posts and Topics** (`wbb3_post`, `wbb3_thread`)
   - Orders chronologically (`ORDER BY p.time`)
   - Uses category mapping to place posts in correct Discourse category
   - Applies appropriate tags based on original WBB3 category hierarchy
   - First post of thread creates topic
   - Subsequent posts are replies
   - Processes attachments if `FILES_DIR` is set
   - Can be filtered by `IMPORT_SINCE` (filters by `p.time`)
   - Stores mapping in `post_custom_fields` and `topic_custom_fields` with `name='import_id'`

4. **Likes** (`wcf3_like`)
   - Imports post likes from WoltLab
   - Can be filtered by `IMPORT_SINCE` (filters by `time`)
   - Skips likes for posts that weren't imported

## Transaction Safety

The importer uses database transactions to ensure atomicity:

- If a topic creation fails, the entire operation is rolled back
- No orphaned topics are left behind
- Safe to re-run after failures

## Troubleshooting

### "Skipping reply XXX - parent post YYY not found"

**Cause**: The parent topic has no first post (orphaned topic).

**Solution**: Run the cleanup script:
```bash
RAILS_ENV=development bundle exec rails runner script/import_scripts/woltlab/cleanup_orphaned_topics.rb
```

Alternatively, completely reset the development environment and start fresh:
```bash
script/import_scripts/woltlab/reset_dev.sh
```

Then re-run the import.

### "Attachment file not found: files/XX/YYY-ZZZ"

**Cause**: The `FILES_DIR` path is incorrect or files are missing.

**Solution**:
1. Verify `FILES_DIR` points to the correct location
2. Check file permissions
3. Ensure files exist in the expected structure

### Attachments Not Being Imported

**Symptoms**: Posts contain `<woltlab-metacode>` tags but no actual attachments appear. No diagnostic messages about attachments in log output.

**Cause**: Wrong `objectTypeID` being used. WoltLab has multiple object types with the same name `com.woltlab.wbb.post` (IDs: 213, 220, 224, 226, 229, etc.), but only one is used for attachments (224: `wbb\system\attachment\PostAttachmentObjectType`).

**Fix Applied**: Query now filters by `className LIKE '%Attachment%'` to find the correct objectTypeID:
```ruby
result = mysql_query(
  "SELECT objectTypeID FROM wcf3_object_type
   WHERE objectType = 'com.woltlab.wbb.post'
   AND className LIKE '%Attachment%'"
).first
```

### File Path Structure Issues

**Symptoms**: Files not found during import, even when `FILES_DIR` is set correctly.

**Cause**: The file path structure was incorrectly implemented. WoltLab uses a 4-character hash prefix split into two directories, not a 2-character prefix.

**Correct Structure**:
```
files/<hash[0..1]>/<hash[2..3]>/<fileID>-<hash>.<ext>
```

**Example**:
```
files/81/a3/231744-81a3c2c7012025522ab030e13ddd7842d259bf690d3b155a9124d245fff3c558.jpg
       ^^  ^^
       |   |
       |   hash characters 2-3
       hash characters 0-1
```

**Fix Applied**: Updated file path building to use correct structure with proper extension handling.

### Empty Filenames in Database

**Symptoms**: Attachments have empty `filename` field in database, causing missing file extensions.

**Cause**: Some WoltLab attachments have empty `filename` field but do have `fileExtension` field populated.

**Fix Applied**: Added fallback logic:
1. Try to get extension from `filename` field
2. If empty, use `fileExtension` field from `wcf3_file` table
3. Generate display filename as `attachment-<attachmentID>.<ext>` when original is empty

### Inline Images Not Displaying

**Symptoms**: All attachments appear at bottom of posts, images not shown inline as they were in WoltLab.

**Cause**: WoltLab uses special markup tags for inline attachments that need to be converted:
```html
<woltlab-metacode data-name="attach" data-attributes="base64-encoded-json">
```

The `data-attributes` contains Base64-encoded JSON: `[attachmentID, size, inline_flag]`

**Fix Applied**: The importer now:
1. Parses and decodes WoltLab inline attachment tags
2. Replaces them with HTML tags (since WoltLab content is HTML):
   - Images: `<img src="/uploads/path/file.jpg" alt="filename">`
   - Other files: `<a href="/uploads/path/file.pdf">filename</a>`
3. Only appends unused attachments at the bottom of the post

### Images Not Displaying

**Symptoms**: Images don't display in imported posts.

**Causes**:
1. The `isImage` field in the `wcf3_attachment` table is unreliable and often set to `0` even for JPG/PNG files
2. WoltLab stores content as HTML, not markdown

**Fix Applied**:
1. Image detection now uses file extension (`.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.webp`, `.svg`) instead of the `isImage` database field
2. Attachments are inserted as HTML `<img>` tags with full URLs (`upload.url`) instead of markdown with short URLs
3. This works seamlessly with WoltLab's HTML content format

### "Category XX not found"

**Cause**: Category wasn't imported (possibly filtered out by hierarchy level).

**Solution**: Check the category mapping in `woltlab_analyze.rb` output.

### Wrong Table Prefix / Categories Not Mapping

**Symptoms**: Import shows wrong number of categories (162 instead of 360), or categories exist in database but aren't detected.

**Cause**: Database has multiple table versions (`wbb1_1_board` with 162 categories vs `wbb3_board` with 360 categories). The default prefix is `wbb3_` to match the post/thread tables (`wbb3_post`, `wbb3_thread`).

**Solution**:
- If your installation uses `wbb1_1_*` tables, set `TABLE_PREFIX=wbb1_1_` environment variable
- If your installation has both, use `wbb3_` (the default) which matches the post data
- Diagnostic: Check which table has your posts with `SELECT COUNT(*) FROM wbb3_post` vs `SELECT COUNT(*) FROM wbb1_1_post`

### "User -1 not found"

**Cause**: A post references a user that wasn't imported.

**Solution**: The importer automatically falls back to system user or first admin.

## Database Schema Notes

### Tables Used

- **wcf3_user**: User accounts
- **wcf3_user_avatar**: User avatar information (for profile import)
- **wcf3_user_option**: User profile field definitions (for profile import)
- **wcf3_user_option_value**: User profile field values (for profile import)
- **wbb3_board**: Forum categories/boards
- **wbb3_post**: Post content
- **wbb3_thread**: Thread metadata
- **wcf3_attachment**: Attachment metadata
- **wcf3_file**: File information
- **wcf3_object_type**: Object type definitions

### Key Relationships

```
wbb3_post.threadID → wbb3_thread.threadID
wbb3_post.userID → wcf3_user.userID
wbb3_thread.boardID → wbb3_board.boardID
wbb3_thread.firstPostID → wbb3_post.postID (first post of thread)
wcf3_attachment.objectID → wbb3_post.postID (when objectTypeID = post type)
wcf3_attachment.fileID → wcf3_file.fileID
wcf3_user.avatarID → wcf3_user_avatar.avatarID (user profile avatar)
wcf3_user_option_value.userID → wcf3_user.userID (user profile fields)
wcf3_user_option.optionID → mapped to wcf3_user_option_value.userOption{N} columns
```

## Performance

Typical import speeds:
- **Posts**: ~60,000 items/min (without attachments)
- **Attachments**: Depends on file size and disk I/O

For a database with 562,000 posts:
- Without attachments: ~10-15 minutes
- With attachments (173,000 files): Several hours (depends on file sizes)

## License

This importer is part of Discourse and follows the same license.

## Support

For issues specific to this importer, check:
1. This README
2. The utility scripts for diagnostics
3. Discourse import documentation: https://meta.discourse.org/c/howto/importers
