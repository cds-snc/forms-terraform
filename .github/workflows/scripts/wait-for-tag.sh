#!/bin/bash

#
# Given a git tag name as an argument, this script will wait until the tag is available in the remote repository.
# The wait is based on the values of CHECK_INTERVAL and MAX_CHECKS.
# 
# Usage:
#   ./wait-for-tag.sh v1.2.3
#

set -euo pipefail
IFS=$'\n\t'

TAG_NAME="$1"
CHECK_INTERVAL=5
MAX_CHECKS=20

for ((i=1; i<=MAX_CHECKS; i++)); do
  git fetch --tags > /dev/null 2>&1
  if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "🎉 Tag $TAG_NAME exists!"
    exit 0
  fi
  echo "Tag $TAG_NAME not found. Checking again in $CHECK_INTERVAL seconds... (Attempt $i/$MAX_CHECKS)"
  sleep $CHECK_INTERVAL
done

echo "💀 Tag $TAG_NAME does not exist after $MAX_CHECKS attempts..."
exit 1