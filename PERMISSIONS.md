# WoltLab to Discourse Permission Migration

## Overview

This document describes how to migrate user groups and board permissions from WoltLab Burning Board to Discourse.

**Admin/Moderator Roles:** WoltLab administrators (group 4) and moderators (group 5) are automatically granted the corresponding admin and moderator flags in Discourse during user import. No manual role assignment is needed.

## WoltLab Permission Model

WoltLab uses an Access Control List (ACL) system:

### Tables
- **`wcf3_user_group`**: Stores groups
- **`wcf3_user_to_group`**: User-to-group membership
- **`wcf3_acl_option`**: Available permissions (e.g., `canViewBoard`, `canEnterBoard`)
- **`wcf3_acl_option_to_group`**: Group permissions for specific boards
- **`wcf3_acl_option_to_user`**: User-specific permissions (overrides)

### Permission Structure
- **objectID**: The board/category ID
- **groupID**: The group being granted/denied permission
- **optionName**: The permission type (e.g., `canViewBoard`, `canStartThread`)
- **optionValue**: `1` = allowed, `0` = denied

### Example: Vorstand Board Permissions

```sql
-- Vorstand group (ID 7) can access Vorstand boards
SELECT a.objectID as boardID, b.title, o.optionName, g.groupName, a.optionValue
FROM wcf3_acl_option_to_group a
JOIN wcf3_acl_option o ON a.optionID = o.optionID
JOIN wcf3_user_group g ON a.groupID = g.groupID
JOIN wbb3_board b ON a.objectID = b.boardID
WHERE b.title LIKE '%Vorstand%'
  AND o.optionName IN ('canViewBoard', 'canEnterBoard');
```

**Result:**
- Group 1 (guests): `optionValue = 0` (denied)
- Group 7 (Vorstand): `optionValue = 1` (allowed)

## Discourse Permission Model

Discourse uses a simpler group-based permission system:

### Tables
- **`groups`**: Stores groups
- **`group_users`**: User-to-group membership
- **`category_groups`**: Category permissions for groups

### Permission Levels
Defined in `CategoryGroup.permission_types`:
- **`full` (0)**: Full access (create topics, reply, moderate)
- **`create_post` (1)**: Create topics and reply
- **`readonly` (2)**: Read-only access
- **`private` (default)**: No access unless explicitly granted

### Making a Category Private
To restrict a category to specific groups:
1. Remove the `everyone` group permission
2. Add specific group(s) with desired permission level

## Migration Strategy

### Step 1: Migrate Groups

Query WoltLab groups (excluding system groups):

```ruby
groups = @woltlab_db.query(
  "SELECT groupID, groupName, groupDescription
   FROM wcf3_user_group
   WHERE groupID NOT IN (1, 2, 3, 4, 5, 9, 21)
   ORDER BY groupID"
)
```

**System Groups (Excluded):**
- **Group 1**: Guests - default permissions in Discourse
- **Group 2**: Users - default permissions in Discourse
- **Group 3**: Registered users - default permissions in Discourse
- **Group 4**: Administrators - mapped to Discourse `admin` flag during user import
- **Group 5**: Moderators - mapped to Discourse `moderator` flag during user import
- **Group 9, 21**: System groups - not needed in Discourse

These groups are excluded from the group migration because Discourse handles them differently (built-in groups or user flags rather than custom groups).

**Group Name Normalization:**

WoltLab group names may contain characters that Discourse doesn't allow (spaces, special characters). The importer automatically normalizes group names:

1. **Transliterates German characters:** ä→ae, ö→oe, ü→ue, ß→ss
2. **Replaces spaces** with underscores
3. **Removes invalid characters** (only letters, numbers, dashes, dots, underscores allowed)
4. **Stores original name** in the `full_name` field

**Examples:**
- "Arbeitsgruppe LOAD-Magazin" → "Arbeitsgruppe_LOAD-Magazin"
- "Vereinsmitglieder_mit_größer_Galerie" → "Vereinsmitglieder_mit_groesser_Galerie"

Create corresponding Discourse groups:

```ruby
Group.create!(
  name: normalized_name,           # Discourse-compatible name
  full_name: original_name,        # Original WoltLab name
  bio_raw: description,
  visibility_level: Group.visibility_levels[:members]
)
```

### Step 2: Migrate Group Memberships

Query WoltLab memberships:

```sql
SELECT userID, groupID
FROM wcf3_user_to_group
WHERE groupID NOT IN (1, 2, 3, 4, 5, 9, 21)
```

Add users to Discourse groups:

```ruby
discourse_group.add(discourse_user)
```

### Step 3: Migrate Category Permissions

For each board with ACL permissions:

1. **Query permissions:**
   ```sql
   SELECT a.groupID, o.optionName, a.optionValue
   FROM wcf3_acl_option_to_group a
   JOIN wcf3_acl_option o ON a.optionID = o.optionID
   WHERE a.objectID = <boardID>
     AND o.optionName IN ('canViewBoard', 'canEnterBoard', 'canReadThread',
                          'canStartThread', 'canReplyThread')
   ```

2. **Determine Discourse permission level:**
   - If `canViewBoard=1` AND `canEnterBoard=1` AND `canReadThread=1`:
     - If `canStartThread=1` AND `canReplyThread=1`: **full**
     - Else if `canReplyThread=1`: **create_post**
     - Else: **readonly**
   - If `canViewBoard=0` OR `canEnterBoard=0`: **Remove** any existing permission

3. **Create CategoryGroup permission:**
   ```ruby
   CategoryGroup.create!(
     category_id: discourse_category_id,
     group_id: discourse_group_id,
     permission_type: CategoryGroup.permission_types[:full]
   )
   ```

4. **Make category private if needed:**
   - If guests (group 1) have `canViewBoard=0`, remove `everyone` group permission

### Permission Inheritance

**Important:** WoltLab supports permission inheritance, where child boards without explicit ACL entries inherit permissions from their parent boards. The migration script automatically handles this.

**How it works:**

1. **Boards with explicit ACLs** are processed first (as described above)
2. **Boards without explicit ACLs** are then checked for inherited permissions:
   - The script walks up the parent board hierarchy
   - Finds the first ancestor with explicit ACL permissions
   - Applies those permissions to the child category in Discourse

**Example:**

```
WoltLab structure:
  Board 7: "Vorstand" (has explicit ACL: guests denied, Vorstand group allowed)
    ├─ Board 27: "Kassenwart" (no explicit ACL)
    ├─ Board 199: "Mitgliederverwaltung" (no explicit ACL)
    └─ Board 254: "Protokolle" (no explicit ACL)

Discourse result:
  - Category "Vorstand": Private, only Vorstand group has access (explicit)
  - Category "Kassenwart": Private, only Vorstand group has access (inherited from board 7)
  - Category "Mitgliederverwaltung": Private, only Vorstand group has access (inherited from board 7)
  - Category "Protokolle": Private, only Vorstand group has access (inherited from board 7)
```

**Migration output:**
```
STEP 3a: Processing boards with explicit ACL permissions
  Processing category 'Vorstand' (WoltLab board 7)
    ✓ Added group 'Vorstand' with full access
    ✓ Made category private (removed 'everyone' access)

STEP 3b: Processing boards with inherited permissions
  Processing category 'Mitgliederverwaltung' (WoltLab board 199)
    Inheriting permissions from parent board 7 ('Vorstand')
    ✓ Added group 'Vorstand' with full access (inherited from board 7)
    ✓ Made category private (removed 'everyone' access) (inherited from board 7)
```

**Statistics:**

In a typical VzEkC forum migration, approximately:
- **30-40 boards** have explicit ACL entries
- **80-90 boards** inherit permissions from parent boards
- This ensures all restricted content remains properly secured

## Usage

### Prerequisites

1. **Import users and categories first:**
   ```bash
   IMPORT_TYPES=users,categories bundle exec ruby script/import_scripts/woltlab/import_contents.rb
   ```
   Note: Since the default is now to import only users, you must explicitly specify `IMPORT_TYPES=users,categories` to import categories. Alternatively, run the full `migrate.rb` script which handles everything.

2. **Discourse group name length (automatic):**

   WoltLab group names can exceed Discourse's default 20-character limit. The migration script **automatically detects and adjusts** the `max_username_length` setting if needed. No manual configuration is required.

   The script will:
   - Check if any WoltLab group names exceed the current limit
   - Automatically increase `max_username_length` to accommodate them
   - Display which groups required the adjustment
   - Continue with the migration

   **Manual pre-configuration (optional):** If you prefer to set this before running the migration, you can do so via Admin Panel (`/admin/site_settings/category/users` → search for `max_username_length`) or Rails Console (`SiteSetting.max_username_length = 50`).

3. **Verify environment variables:**
   ```bash
   export DB_HOST="127.0.0.1"
   export DB_PORT="3306"
   export DB_NAME="forum"
   export DB_USER="forum"
   export DB_PASSWORD="your_password"
   ```

### Run Migration

**Recommended: Run complete migration**
```bash
cd /path/to/discourse
bundle exec rails runner script/import_scripts/woltlab/migrate.rb
```
This runs both content import and permission migration in sequence.

**Or run permissions separately (advanced):**

⚠️ **IMPORTANT:** You can ONLY run permissions separately if you have already run the content import at least once. The permissions script requires the `import_id` custom fields created by the content import to map WoltLab IDs to Discourse IDs.

```bash
cd /path/to/discourse
bundle exec rails runner script/import_scripts/woltlab/import_groups_and_permissions.rb
```

This is useful when:
- You've already imported content and want to re-run just the permissions
- You need to update group permissions after the initial migration
- You're testing permission migration separately

### Example: Vorstand Board

**WoltLab ACL:**
- Board 7: "Vorstand"
- Group 1 (guests): `canViewBoard=0`, `canEnterBoard=0` (denied)
- Group 7 (Vorstand): `canViewBoard=1`, `canEnterBoard=1`, `canStartThread=1`, `canReplyThread=1` (allowed)

**Discourse Result:**
- Category "Vorstand" becomes private (everyone access removed)
- Group "Vorstand" gets **full** permission
- Only Vorstand group members can see/access the category

## Verification

### Check Groups

```ruby
# Rails console
Group.where("custom_fields @> ?", {woltlab_group_id: 7}.to_json)
```

### Check Category Permissions

```ruby
# Find Vorstand category
category = Category.find_by(name: "Vorstand")

# List all group permissions
CategoryGroup.where(category_id: category.id).each do |cg|
  group = Group.find(cg.group_id)
  puts "#{group.name}: #{cg.permission_type}"
end
```

### Check User Group Membership

```ruby
user = User.find_by(username: "username")
user.groups.pluck(:name)
```

## Boards Migrated (Example)

Based on Vorstand permissions found in the database:

| Board ID | Board Title | Restricted Groups |
|----------|-------------|-------------------|
| 7 | Vorstand | Vorstand (7) |
| 211 | Vorstand & Administration | Vorstand (7) |
| 212 | Vorstand & Schiedsgericht | Vorstand (7) |
| 304 | intern (Michael+Vorstand) | Vorstand (7), group 4 |
| 357 | Vorstand & Datenschutz | Vorstand (7), Datenschutzbeauftragter (25) |
| 411 | Vorstand + Veranstaltungselektrik | Vorstand (7) |
| 414 | Vorstandstelcos | Vorstand (7) |

## Troubleshooting

### "Validation failed: Name must be no more than 20 characters"

**Cause:** WoltLab group names exceed Discourse's `max_username_length` setting.

**Solution:**

The import script will automatically detect this issue and provide detailed instructions. If you see this error:

1. **Via Admin Panel (Recommended):**
   - Go to `/admin/site_settings/category/users`
   - Search for `max_username_length`
   - Increase from `20` to `50` (or higher based on error message)
   - Save and re-run import

2. **Via Rails Console:**
   ```bash
   bundle exec rails c
   SiteSetting.max_username_length = 50
   exit
   ```

The error message will list all groups that exceed the current limit and suggest an appropriate value.

### "Validation failed: Name must only include numbers, letters, dashes, dots, and underscores"

**Cause:** WoltLab group names contain characters that Discourse doesn't allow (usually spaces or special characters).

**Solution:**

This is now handled automatically! The importer normalizes group names by:
- Transliterating German characters (ä→ae, ö→oe, ü→ue, ß→ss)
- Replacing spaces with underscores
- Removing invalid characters
- Storing the original name in the `full_name` field

**Examples of normalization:**
- "Arbeitsgruppe Online" → "Arbeitsgruppe_Online"
- "Vereinsmitglieder_mit_größer_Galerie" → "Vereinsmitglieder_mit_groesser_Galerie"
- "8Bit-Wiki Administratoren" → "8Bit-Wiki_Administratoren"

No action needed - the import will proceed automatically with normalized names.

### Groups Not Found

If the script reports groups not found:

```bash
# Check if groups were created in import
bundle exec rails runner "puts Group.pluck(:name)"

# Check custom fields
bundle exec rails runner "puts Group.joins(:custom_fields).where(\"group_custom_fields.name = 'woltlab_group_id'\").count"
```

### Category Permissions Not Applied

If permissions aren't applied:

```bash
# Check if category exists
bundle exec rails runner "puts Category.find_by(name: 'Vorstand')&.id"

# Check import_id custom field
bundle exec rails runner "puts CategoryCustomField.find_by(name: 'import_id', value: '7')&.category_id"
```

### Users Not in Groups

If users aren't added to groups:

```bash
# Check user import_id
bundle exec rails runner "puts UserCustomField.where(name: 'import_id').count"

# Check group_users
bundle exec rails runner "puts GroupUser.joins(:group).where(groups: {name: 'Vorstand'}).count"
```

## Notes

- **System groups** (IDs 1-5, 9, 21) are not migrated as they're WoltLab-specific
- **Individual user permissions** (`wcf3_acl_option_to_user`) are not yet supported
- **Moderator permissions** (`wbb3_board_moderator`) should be migrated separately using Discourse's moderator system
- Categories without explicit ACLs maintain default Discourse permissions (visible to all)

## Next Steps

After migration:

1. **Verify permissions** by logging in as a Vorstand member
2. **Test category visibility** with a non-member account
3. **Adjust permissions** in Discourse admin if needed
4. **Document** any custom permission requirements for admins
