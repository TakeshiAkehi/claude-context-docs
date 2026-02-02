#!/bin/bash
# SessionStart hook: Load document indices for context-aware retrieval
# Supports monorepo: loads from current location up to project root
set -euo pipefail

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SCRIPT_DIR="$(dirname "$0")"

# If called with a path argument, use hierarchical loading
if [[ $# -gt 0 && -n "$1" ]]; then
    START_PATH="$1"
else
    START_PATH="$PROJECT_ROOT"
fi

# Find all indices from start path to project root
INDICES=$("$SCRIPT_DIR/find-context-docs.sh" "$START_PATH" 2>/dev/null || echo "")

if [[ -z "$INDICES" ]]; then
    # Fallback: check single index at project root (backward compatibility)
    INDEX_FILE="$PROJECT_ROOT/context_doc/INDEX.md"
    if [[ ! -f "$INDEX_FILE" ]]; then
        cat <<EOF
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "No document index found. Use /doc commands to create documentation, which will automatically create and update the index."
}
EOF
        exit 0
    fi
    INDICES="$INDEX_FILE"
fi

# Build merged content with hierarchy indicators
MERGED_CONTENT=""
INDEX_COUNT=0

while IFS= read -r idx_path; do
    if [[ -n "$idx_path" && -f "$idx_path" ]]; then
        INDEX_COUNT=$((INDEX_COUNT + 1))

        # Calculate relative path from project root for header
        REL_PATH="${idx_path#$PROJECT_ROOT/}"
        DIR_PATH=$(dirname "$REL_PATH")

        if [[ "$DIR_PATH" == "context_doc" || "$DIR_PATH" == "." ]]; then
            HEADER="### [Root] Project Documentation"
        else
            # Extract module path (remove /context_doc suffix)
            MODULE_PATH="${DIR_PATH%/context_doc}"
            HEADER="### [$MODULE_PATH] Module Documentation"
        fi

        CONTENT=$(cat "$idx_path")

        # Escape special characters for JSON
        CONTENT=$(echo "$CONTENT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ' | sed 's/  */ /g')

        if [[ -n "$MERGED_CONTENT" ]]; then
            MERGED_CONTENT="$MERGED_CONTENT\\n\\n"
        fi
        MERGED_CONTENT="$MERGED_CONTENT$HEADER\\n$CONTENT"
    fi
done <<< "$INDICES"

if [[ $INDEX_COUNT -eq 0 ]]; then
    cat <<EOF
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "No document index found. Use /doc commands to create documentation."
}
EOF
    exit 0
fi

# Output for Claude's context
if [[ $INDEX_COUNT -eq 1 ]]; then
    SUMMARY="Document index loaded (1 location)."
else
    SUMMARY="Document indices loaded from $INDEX_COUNT locations (hierarchical)."
fi

cat <<EOF
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "$SUMMARY\\n\\n$MERGED_CONTENT\\n\\nUse /recall to load specific documents relevant to the current task."
}
EOF
