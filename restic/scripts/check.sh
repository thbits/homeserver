#!/bin/sh
set -e

echo "==================================="
echo "Starting Restic Integrity Check"
echo "Date: $(date)"
echo "==================================="

echo "Checking repository consistency..."
restic check --verbose

CHECK_EXIT_CODE=$?

if [ $CHECK_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "==================================="
    echo "Repository check passed!"
    echo "==================================="
else
    echo ""
    echo "==================================="
    echo "Repository check FAILED with exit code: $CHECK_EXIT_CODE"
    echo "==================================="
    exit $CHECK_EXIT_CODE
fi

echo ""
echo "Repository Statistics:"
restic stats

