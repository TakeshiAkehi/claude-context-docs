#!/bin/bash
# Find the appropriate context_doc root for document generation
# Usage: find-doc-root.sh [start_path]
# Output: Path to the directory where context_doc/ should be created
#
# Logic: Traverse up from start_path to project root, looking for submodule boundary
# Submodule detection: .git is a FILE (not directory) in submodule roots
set -euo pipefail

START_PATH="${1:-$(pwd)}"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Normalize paths
if [[ "$START_PATH" != /* ]]; then
    START_PATH="$(pwd)/$START_PATH"
fi
START_PATH=$(cd "$START_PATH" 2>/dev/null && pwd || echo "$START_PATH")
PROJECT_ROOT=$(cd "$PROJECT_ROOT" 2>/dev/null && pwd || echo "$PROJECT_ROOT")

# If start path is a file, use its directory
if [[ -f "$START_PATH" ]]; then
    START_PATH=$(dirname "$START_PATH")
fi

# Default to project root
DOC_ROOT="$PROJECT_ROOT"

# Traverse up from start path to project root, looking for submodule boundary
CURRENT="$START_PATH"

while [[ "$CURRENT" != "$PROJECT_ROOT" && "$CURRENT" != "/" ]]; do
    # Check if this is a submodule root
    # Submodules have .git as a file (pointing to main repo), not a directory
    if [[ -f "$CURRENT/.git" ]]; then
        DOC_ROOT="$CURRENT"
        break
    fi

    CURRENT=$(dirname "$CURRENT")
done

echo "$DOC_ROOT"
