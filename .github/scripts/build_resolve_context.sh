#!/bin/bash
set -euo pipefail
CONFIG="$1"

if [ ! -f "$CONFIG"  ]; then
  echo "::warning::Config file not found: $CONFIG, assuming dev"
fi

echo "CONFIG_FILE=$CONFIG" >> "$GITHUB_OUTPUT"

IS_DEV=true


if [ "$IS_DEV" = true ]; then
  echo "IS_PRERELEASE=true" >> "$GITHUB_OUTPUT"
  echo "TITLE_SUFFIX= (Pre-release)" >> "$GITHUB_OUTPUT"
  echo "ARCHIVE_TAG=beta" >> "$GITHUB_OUTPUT"
else
  echo "IS_PRERELEASE=false" >> "$GITHUB_OUTPUT"
  echo "TITLE_SUFFIX=" >> "$GITHUB_OUTPUT"
  echo "ARCHIVE_TAG=stable" >> "$GITHUB_OUTPUT"
fi
