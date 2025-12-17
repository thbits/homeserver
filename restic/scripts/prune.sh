#!/bin/sh
set -e

echo "==================================="
echo "Starting Restic Prune"
echo "Date: $(date)"
echo "==================================="

# Apply retention policy and remove old snapshots
echo "Applying retention policy..."
restic forget \
    --tag automated \
    --group-by host,tags \
    --keep-daily 7 \
    --keep-weekly 6 \
    --keep-monthly 0 \
    --keep-yearly 0 \
    --prune \
    --verbose

echo ""
echo "==================================="
echo "Pruning old data..."
echo "==================================="

# Remove unreferenced data
restic prune --verbose

echo ""
echo "==================================="
echo "Repository Statistics:"
echo "==================================="
restic stats

echo ""
echo "Remaining snapshots:"
restic snapshots

echo ""
echo "==================================="
echo "Prune completed successfully!"
echo "==================================="

