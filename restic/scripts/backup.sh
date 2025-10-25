#!/bin/sh
set -e

echo "==================================="
echo "Starting Restic Backup"
echo "Date: $(date)"
echo "==================================="

# Initialize repository if it doesn't exist
if ! restic snapshots > /dev/null 2>&1; then
    echo "Repository not found. Initializing..."
    restic init
    echo "Repository initialized successfully."
fi

# Read backup paths from config file
BACKUP_PATHS=""
if [ -f /config/backup-paths.txt ]; then
    while IFS= read -r line || [ -n "$line" ]
    do
        # Skip empty lines and comments
        case "$line" in
            ''|\#*) continue ;;
        esac
        BACKUP_PATHS="$BACKUP_PATHS $line"
    done < /config/backup-paths.txt
else
    echo "ERROR: /config/backup-paths.txt not found!"
    exit 1
fi

if [ -z "$BACKUP_PATHS" ]; then
    echo "ERROR: No backup paths specified in backup-paths.txt"
    exit 1
fi

echo "Backing up paths:"
echo "$BACKUP_PATHS" | tr ' ' '\n'
echo ""

# Build exclude arguments
EXCLUDE_ARGS=""
if [ -f /config/exclude-patterns.txt ]; then
    while IFS= read -r pattern || [ -n "$pattern" ]
    do
        # Skip empty lines and comments
        case "$pattern" in
            ''|\#*) continue ;;
        esac
        EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$pattern"
    done < /config/exclude-patterns.txt
fi

# Perform backup with compression and tags
restic backup \
    $BACKUP_PATHS \
    $EXCLUDE_ARGS \
    --tag automated \
    --tag daily \
    --host homeserver \
    --verbose

BACKUP_EXIT_CODE=$?

if [ $BACKUP_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "==================================="
    echo "Backup completed successfully!"
    echo "==================================="
    
    # Show latest snapshot
    echo ""
    echo "Latest snapshots:"
    restic snapshots --latest 3
else
    echo ""
    echo "==================================="
    echo "Backup FAILED with exit code: $BACKUP_EXIT_CODE"
    echo "==================================="
    exit $BACKUP_EXIT_CODE
fi

