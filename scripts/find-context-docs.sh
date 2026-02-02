#!/bin/bash
# Find all context_doc/INDEX.md files from a path up to project root
# Usage: find-context-docs.sh [start_path]
# Output: List of paths to INDEX.md files, from nearest to root
set -euo pipefail

START_PATH="${1:-$(pwd)}"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Normalize paths (handle relative paths)
if [[ "$START_PATH" != /* ]]; then
    START_PATH="$(pwd)/$START_PATH"
fi
START_PATH=$(cd "$START_PATH" 2>/dev/null && pwd || echo "$START_PATH")
PROJECT_ROOT=$(cd "$PROJECT_ROOT" 2>/dev/null && pwd || echo "$PROJECT_ROOT")

# If start path is a file, use its directory
if [[ -f "$START_PATH" ]]; then
    START_PATH=$(dirname "$START_PATH")
fi

# Collect indices from start_path up to project_root
CURRENT="$START_PATH"
INDICES=()

while [[ "$CURRENT" == "$PROJECT_ROOT"* || "$CURRENT" == "$PROJECT_ROOT" ]]; do
    INDEX_FILE="$CURRENT/context_doc/INDEX.md"
    if [[ -f "$INDEX_FILE" ]]; then
        INDICES+=("$INDEX_FILE")
    fi

    # Stop if we've reached project root
    if [[ "$CURRENT" == "$PROJECT_ROOT" ]]; then
        break
    fi

    # Move up one directory
    PARENT=$(dirname "$CURRENT")
    if [[ "$PARENT" == "$CURRENT" ]]; then
        break  # Reached filesystem root
    fi
    CURRENT="$PARENT"
done

# Output paths (nearest first)
for idx in "${INDICES[@]}"; do
    echo "$idx"
done
