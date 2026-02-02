#!/bin/bash
# Update document index with a new entry
# Usage: update-index.sh <title> <path> <type> <keywords> [doc_root]
# doc_root: Optional. Directory containing context_doc/. Defaults to $CLAUDE_PROJECT_DIR
set -euo pipefail

TITLE="$1"
PATH_ARG="$2"
TYPE="$3"
KEYWORDS="$4"
DOC_ROOT="${5:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
DATE=$(date +%Y-%m-%d)

INDEX_FILE="$DOC_ROOT/context_doc/INDEX.md"

# Create index if it doesn't exist
if [ ! -f "$INDEX_FILE" ]; then
  mkdir -p "$(dirname "$INDEX_FILE")"
  cat > "$INDEX_FILE" << 'EOF'
# Document Index

| Title | Path | Type | Keywords | Date |
|-------|------|------|----------|------|
EOF
fi

# Add new entry
echo "| $TITLE | $PATH_ARG | $TYPE | $KEYWORDS | $DATE |" >> "$INDEX_FILE"

echo "Index updated in $DOC_ROOT: $TITLE"
