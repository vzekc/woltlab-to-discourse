#!/bin/bash
# Complete development environment reset
# Removes all uploaded files and recreates database from template

echo "========================================="
echo "DISCOURSE DEVELOPMENT RESET"
echo "========================================="
echo ""
echo "This will:"
echo "  - Delete all uploads"
echo "  - Delete all backups"
echo "  - Delete all temp files"
echo "  - Drop and recreate discourse_development database"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "Removing uploads..."
rm -rf public/uploads/default/*

echo "Removing backups..."
rm -rf public/backups/*

echo "Removing temp caches..."
rm -rf tmp/avatar_proxy tmp/stylesheet-cache tmp/javascript-cache tmp/cache

echo "Dropping database..."
dropdb discourse_development

echo "Creating database from template..."
createdb -T discourse-template discourse_development

echo ""
echo "Running database migrations..."
bin/rails db:migrate

echo ""
echo "========================================="
echo "RESET COMPLETE"
echo "========================================="
