## Overview

This is the importer for Woltlab content into discourse.

The main importer scripts:
- **migrate.rb** - Orchestrator that runs full migration (recommended)
- **import_contents.rb** - Imports users, categories, posts, likes
- **import_groups_and_permissions.rb** - Imports groups, memberships, category permissions

All scripts are configured through environment variables. Assume that DB_* and IMPORT are set in the environment when proposing commands to run.
Woltlab's database schema is available in woltlab-schema.sql for inspection.
We can connect to the Woltlab mysql database to introspect the existing data.
The woltlab database contains tables from a previous Woltlab version. They have a name starting with wbb1 or wcf1 and should be ignored.

Always run the pre-commit checks before attempting to commit.
