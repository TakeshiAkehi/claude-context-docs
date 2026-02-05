#!/bin/bash
# Migrate context_doc from old per-type subdirectory structure to new flat docs/ structure
# Old: context_doc/<type>/YYYYMMDD-HHMM-title.md
# New: context_doc/docs/YYYYMMDD-<doctype>-title.md
#
# Usage: migrate-docs.sh [--dry-run] <context_doc_path>
# Output: Line-based status messages (MOVE, SKIP, CONFLICT, INDEX, CLEANUP, KEEP)
set -euo pipefail

# --- Argument parsing ---
DRY_RUN=false
CONTEXT_DOC_PATH=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *)
            if [[ -n "$CONTEXT_DOC_PATH" ]]; then
                echo "ERROR: Too many arguments. Only one path expected." >&2
                echo "Usage: migrate-docs.sh [--dry-run] <context_doc_path>" >&2
                exit 1
            fi
            CONTEXT_DOC_PATH="$arg"
            ;;
    esac
done

if [[ -z "$CONTEXT_DOC_PATH" ]]; then
    echo "ERROR: context_doc path is required" >&2
    echo "Usage: migrate-docs.sh [--dry-run] <context_doc_path>" >&2
    exit 1
fi

# --- Path normalization ---
if [[ "$CONTEXT_DOC_PATH" != /* ]]; then
    CONTEXT_DOC_PATH="$(pwd)/$CONTEXT_DOC_PATH"
fi
CONTEXT_DOC_PATH=$(cd "$CONTEXT_DOC_PATH" 2>/dev/null && pwd || echo "$CONTEXT_DOC_PATH")

if [[ ! -d "$CONTEXT_DOC_PATH" ]]; then
    echo "ERROR: Directory does not exist: $CONTEXT_DOC_PATH" >&2
    exit 1
fi

# --- Known document type subdirectories ---
DOC_TYPES=("adr" "design" "runbook" "handoff" "howto")

# --- Discover migration targets ---
# Arrays to hold planned operations (bash 3+ compatible, no associative arrays)
MOVE_SRCS=()
MOVE_DSTS=()
SKIP_FILES=()
CONFLICT_FILES=()

for doctype in "${DOC_TYPES[@]}"; do
    TYPE_DIR="$CONTEXT_DOC_PATH/$doctype"
    if [[ ! -d "$TYPE_DIR" ]]; then
        continue
    fi

    for filepath in "$TYPE_DIR"/*.md; do
        # Handle glob no-match (bash returns literal pattern)
        [[ -e "$filepath" ]] || continue

        filename=$(basename "$filepath")

        # Skip non-document files (e.g., README.md)
        # Pattern 1: Old format YYYYMMDD-HHMM-title.md
        if [[ "$filename" =~ ^([0-9]{8})-[0-9]{4}-(.+)\.md$ ]]; then
            date_part="${BASH_REMATCH[1]}"
            title_part="${BASH_REMATCH[2]}"
            new_filename="${date_part}-${doctype}-${title_part}.md"

        # Pattern 2: Already new format YYYYMMDD-doctype-title.md (in old directory)
        elif [[ "$filename" =~ ^([0-9]{8})-(adr|design|runbook|handoff|howto)-(.+)\.md$ ]]; then
            new_filename="$filename"

        # Pattern 3: No recognized pattern - skip
        else
            SKIP_FILES+=("${doctype}/${filename}")
            continue
        fi

        dest_path="$CONTEXT_DOC_PATH/docs/$new_filename"
        rel_src="${doctype}/${filename}"
        rel_dst="docs/${new_filename}"

        # Check for conflicts
        if [[ -e "$dest_path" ]]; then
            CONFLICT_FILES+=("$rel_dst")
            continue
        fi

        MOVE_SRCS+=("$rel_src")
        MOVE_DSTS+=("$rel_dst")
    done
done

# --- Check if there's anything to migrate ---
if [[ ${#MOVE_SRCS[@]} -eq 0 && ${#SKIP_FILES[@]} -eq 0 && ${#CONFLICT_FILES[@]} -eq 0 ]]; then
    echo "NOTHING_TO_MIGRATE"
    exit 0
fi

# --- Compute INDEX.md rewrites ---
INDEX_FILE="$CONTEXT_DOC_PATH/INDEX.md"
INDEX_REWRITES_OLD=()
INDEX_REWRITES_NEW=()

if [[ -f "$INDEX_FILE" ]]; then
    for i in "${!MOVE_SRCS[@]}"; do
        src="${MOVE_SRCS[$i]}"
        dst="${MOVE_DSTS[$i]}"
        # Check if the old path appears in INDEX.md
        if grep -qF "$src" "$INDEX_FILE" 2>/dev/null; then
            INDEX_REWRITES_OLD+=("$src")
            INDEX_REWRITES_NEW+=("$dst")
        fi
    done
fi

# --- Compute directory cleanup targets ---
CLEANUP_DIRS=()
KEEP_DIRS=()

for doctype in "${DOC_TYPES[@]}"; do
    TYPE_DIR="$CONTEXT_DOC_PATH/$doctype"
    [[ -d "$TYPE_DIR" ]] || continue

    # Count files that would remain after migration
    remaining=0
    for filepath in "$TYPE_DIR"/*; do
        [[ -e "$filepath" ]] || continue
        fname=$(basename "$filepath")
        # Check if this file is being moved
        is_moving=false
        for src in "${MOVE_SRCS[@]}"; do
            if [[ "$src" == "${doctype}/${fname}" ]]; then
                is_moving=true
                break
            fi
        done
        if ! $is_moving; then
            remaining=$((remaining + 1))
        fi
    done

    if [[ $remaining -eq 0 ]]; then
        CLEANUP_DIRS+=("$doctype/")
    else
        KEEP_DIRS+=("$doctype/")
    fi
done

# --- Output plan ---
echo "CONTEXT_DOC: $CONTEXT_DOC_PATH"
echo "FILES: ${#MOVE_SRCS[@]}"
echo "---"

for i in "${!MOVE_SRCS[@]}"; do
    echo "MOVE: ${MOVE_SRCS[$i]} -> ${MOVE_DSTS[$i]}"
done

if [[ ${#SKIP_FILES[@]} -gt 0 ]]; then
    for skip in "${SKIP_FILES[@]}"; do
        echo "SKIP: $skip (pattern mismatch)"
    done
fi

if [[ ${#CONFLICT_FILES[@]} -gt 0 ]]; then
    for conflict in "${CONFLICT_FILES[@]}"; do
        echo "CONFLICT: $conflict (already exists)"
    done
fi

if [[ ${#INDEX_REWRITES_OLD[@]} -gt 0 ]]; then
    echo "---"
    for i in "${!INDEX_REWRITES_OLD[@]}"; do
        echo "INDEX: ${INDEX_REWRITES_OLD[$i]} -> ${INDEX_REWRITES_NEW[$i]}"
    done
fi

echo "---"
if [[ ${#CLEANUP_DIRS[@]} -gt 0 ]]; then
    for dir in "${CLEANUP_DIRS[@]}"; do
        echo "CLEANUP: $dir (empty after migration, will remove)"
    done
fi
if [[ ${#KEEP_DIRS[@]} -gt 0 ]]; then
    for dir in "${KEEP_DIRS[@]}"; do
        echo "KEEP: $dir (has remaining files)"
    done
fi

# --- If dry-run, stop here ---
if $DRY_RUN; then
    exit 0
fi

# --- Execute migration ---
# Create docs/ directory
mkdir -p "$CONTEXT_DOC_PATH/docs"

# Move and rename files
moved=0
errors=0
for i in "${!MOVE_SRCS[@]}"; do
    src="$CONTEXT_DOC_PATH/${MOVE_SRCS[$i]}"
    dst="$CONTEXT_DOC_PATH/${MOVE_DSTS[$i]}"
    if mv "$src" "$dst" 2>/dev/null; then
        moved=$((moved + 1))
    else
        echo "ERROR: Failed to move ${MOVE_SRCS[$i]}" >&2
        errors=$((errors + 1))
    fi
done

# Rewrite INDEX.md paths (cross-platform sed: use temp file + mv)
if [[ ${#INDEX_REWRITES_OLD[@]} -gt 0 && -f "$INDEX_FILE" ]]; then
    TMP_INDEX="${INDEX_FILE}.migrate.tmp"
    cp "$INDEX_FILE" "$TMP_INDEX"
    for i in "${!INDEX_REWRITES_OLD[@]}"; do
        old_path="${INDEX_REWRITES_OLD[$i]}"
        new_path="${INDEX_REWRITES_NEW[$i]}"
        # Escape special characters for sed
        escaped_old=$(printf '%s\n' "$old_path" | sed 's/[[\.*^$()+?{|]/\\&/g')
        escaped_new=$(printf '%s\n' "$new_path" | sed 's/[&|\\]/\\&/g')
        sed "s|${escaped_old}|${escaped_new}|g" "$TMP_INDEX" > "${TMP_INDEX}.2"
        mv "${TMP_INDEX}.2" "$TMP_INDEX"
    done
    mv "$TMP_INDEX" "$INDEX_FILE"
    echo "INDEX: Updated ${#INDEX_REWRITES_OLD[@]} entries"
fi

# Clean up empty directories
if [[ ${#CLEANUP_DIRS[@]} -gt 0 ]]; then
for dir in "${CLEANUP_DIRS[@]}"; do
    full_dir="$CONTEXT_DOC_PATH/$dir"
    if [[ -d "$full_dir" ]]; then
        # Only remove if truly empty
        if [[ -z "$(ls -A "$full_dir" 2>/dev/null)" ]]; then
            rmdir "$full_dir"
            echo "CLEANED: $dir"
        fi
    fi
done
fi

# --- Summary ---
echo "---"
echo "DONE: Moved $moved files, $errors errors, ${#SKIP_FILES[@]} skipped, ${#CONFLICT_FILES[@]} conflicts"
