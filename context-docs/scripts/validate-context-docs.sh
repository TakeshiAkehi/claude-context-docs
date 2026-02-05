#!/bin/bash
# Validate a context_doc/ directory conforms to plugin conventions
# Usage: validate-context-docs.sh <context_doc_path>
# Output: One line per check result: PASS|FAIL|WARN|INFO <category> <message>
set -euo pipefail

CONTEXT_DOC="${1:?Usage: validate-context-docs.sh <context_doc_path>}"

# Validate directory exists
if [[ ! -d "$CONTEXT_DOC" ]]; then
    echo "FAIL structure Directory does not exist: $CONTEXT_DOC"
    exit 1
fi

# Normalize path
if [[ "$CONTEXT_DOC" != /* ]]; then
    CONTEXT_DOC="$(pwd)/$CONTEXT_DOC"
fi
CONTEXT_DOC=$(cd "$CONTEXT_DOC" 2>/dev/null && pwd || echo "$CONTEXT_DOC")

INDEX_FILE="$CONTEXT_DOC/README.md"
DOCS_DIR="$CONTEXT_DOC/docs"

VALID_DOCTYPES="adr|design|runbook|handoff|howto"
VALID_INDEX_TYPES="ADR|Design|Runbook|Handoff|How-To"
OLD_SUBDIRS="adr design runbook handoff howto"

# ── Directory Structure ──────────────────────────────────────────────

if [[ -f "$INDEX_FILE" ]]; then
    echo "PASS structure README.md exists"
else
    echo "FAIL structure README.md not found at $INDEX_FILE"
fi

if [[ -d "$DOCS_DIR" ]]; then
    echo "PASS structure docs/ directory exists"
else
    echo "FAIL structure docs/ directory not found"
fi

# Check for subdirectories inside docs/
if [[ -d "$DOCS_DIR" ]]; then
    SUBDIRS=$(find "$DOCS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
    if [[ -z "$SUBDIRS" ]]; then
        echo "PASS structure docs/ has flat structure (no subdirectories)"
    else
        while IFS= read -r subdir; do
            echo "FAIL structure docs/ contains subdirectory: $(basename "$subdir")"
        done <<< "$SUBDIRS"
    fi
fi

# Check for old-style subdirectories at context_doc level
for old_dir in $OLD_SUBDIRS; do
    if [[ -d "$CONTEXT_DOC/$old_dir" ]]; then
        echo "WARN structure Old-style subdirectory remains: $old_dir/"
    fi
done

# ── Document Naming ──────────────────────────────────────────────────

if [[ -d "$DOCS_DIR" ]]; then
    FILES=$(find "$DOCS_DIR" -maxdepth 1 -name '*.md' -type f 2>/dev/null || true)
    if [[ -z "$FILES" ]]; then
        echo "INFO naming No document files found in docs/"
    else
        while IFS= read -r filepath; do
            filename=$(basename "$filepath")

            # Check YYYYMMDD-<doctype>-<title>.md pattern
            if [[ "$filename" =~ ^([0-9]{8})-([a-z]+)-(.+)\.md$ ]]; then
                date_part="${BASH_REMATCH[1]}"
                doctype="${BASH_REMATCH[2]}"
                # title is BASH_REMATCH[3] — not validated beyond existence

                # Validate date
                year="${date_part:0:4}"
                month="${date_part:4:2}"
                day="${date_part:6:2}"
                if date -d "$year-$month-$day" >/dev/null 2>&1; then
                    echo "PASS naming $filename: valid date ($year-$month-$day)"
                else
                    echo "FAIL naming $filename: invalid date ($date_part)"
                fi

                # Validate doctype
                if echo "$doctype" | grep -qE "^($VALID_DOCTYPES)$"; then
                    echo "PASS naming $filename: valid doctype ($doctype)"
                else
                    echo "FAIL naming $filename: invalid doctype '$doctype' (expected: $VALID_DOCTYPES)"
                fi
            else
                echo "FAIL naming $filename: doesn't match YYYYMMDD-<doctype>-<title>.md"
            fi
        done <<< "$FILES"
    fi
fi

# ── README.md Format ─────────────────────────────────────────────────

if [[ -f "$INDEX_FILE" ]]; then
    # Check header
    if grep -q '^# Document Index' "$INDEX_FILE"; then
        echo "PASS index Has '# Document Index' header"
    else
        echo "FAIL index Missing '# Document Index' header"
    fi

    # Check table header columns
    if grep -qE '^\|\s*Title\s*\|\s*Path\s*\|\s*Type\s*\|\s*Keywords\s*\|\s*Date\s*\|' "$INDEX_FILE"; then
        echo "PASS index Table has correct columns (Title|Path|Type|Keywords|Date)"
    else
        echo "FAIL index Table columns don't match expected: Title|Path|Type|Keywords|Date"
    fi

    # Check each data row
    ROW_NUM=0
    while IFS= read -r line; do
        # Skip header, separator, and empty lines
        if echo "$line" | grep -qE '^\|\s*Title\s*\|'; then continue; fi
        if echo "$line" | grep -qE '^\|\s*-'; then continue; fi
        if [[ -z "$line" ]]; then continue; fi
        if echo "$line" | grep -qE '^#'; then continue; fi
        if ! echo "$line" | grep -qE '^\|'; then continue; fi

        ROW_NUM=$((ROW_NUM + 1))

        # Parse columns (pipe-delimited, trim whitespace)
        TITLE=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        PATH_VAL=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
        TYPE_VAL=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
        DATE_VAL=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $6); print $6}')

        # Check Path is markdown link format [Title](docs/...)
        if [[ "$PATH_VAL" =~ ^\[.+\]\(docs/.+\)$ ]]; then
            echo "PASS index Row $ROW_NUM: Path is valid link format ($PATH_VAL)"
        else
            echo "FAIL index Row $ROW_NUM: Path should be [Title](docs/...) format (got: $PATH_VAL)"
        fi

        # Check Type is valid
        if echo "$TYPE_VAL" | grep -qE "^($VALID_INDEX_TYPES)$"; then
            echo "PASS index Row $ROW_NUM: valid Type ($TYPE_VAL)"
        else
            echo "FAIL index Row $ROW_NUM: invalid Type '$TYPE_VAL' (expected: $VALID_INDEX_TYPES)"
        fi

        # Check Date format YYYY-MM-DD
        if echo "$DATE_VAL" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
            echo "PASS index Row $ROW_NUM: valid Date format ($DATE_VAL)"
        else
            echo "FAIL index Row $ROW_NUM: Date should be YYYY-MM-DD (got: $DATE_VAL)"
        fi

    done < "$INDEX_FILE"

    if [[ $ROW_NUM -eq 0 ]]; then
        echo "INFO index README.md has no document entries"
    fi
fi

# ── Cross-Reference (Consistency) ────────────────────────────────────

if [[ -f "$INDEX_FILE" && -d "$DOCS_DIR" ]]; then
    # Collect all paths referenced in README.md
    INDEX_PATHS=()
    while IFS= read -r line; do
        if echo "$line" | grep -qE '^\|\s*Title\s*\|'; then continue; fi
        if echo "$line" | grep -qE '^\|\s*-'; then continue; fi
        if [[ -z "$line" ]]; then continue; fi
        if echo "$line" | grep -qE '^#'; then continue; fi
        if ! echo "$line" | grep -qE '^\|'; then continue; fi

        PATH_VAL=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
        TYPE_VAL=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')

        # Extract actual path from markdown link format [Title](path)
        if [[ "$PATH_VAL" =~ ^\[.+\]\((.+)\)$ ]]; then
            ACTUAL_PATH="${BASH_REMATCH[1]}"
        else
            ACTUAL_PATH="$PATH_VAL"
        fi

        if [[ -n "$ACTUAL_PATH" ]]; then
            INDEX_PATHS+=("$ACTUAL_PATH")
            FULL_PATH="$CONTEXT_DOC/$ACTUAL_PATH"

            # Check file exists
            if [[ -f "$FULL_PATH" ]]; then
                echo "PASS consistency README entry '$ACTUAL_PATH' has matching file"
            else
                echo "FAIL consistency README entry '$ACTUAL_PATH' — file not found"
            fi

            # Check Type vs filename doctype consistency
            FNAME=$(basename "$ACTUAL_PATH")
            if [[ "$FNAME" =~ ^[0-9]{8}-([a-z]+)- ]]; then
                FILE_DOCTYPE="${BASH_REMATCH[1]}"
                # Map INDEX Type to filename doctype
                EXPECTED_DOCTYPE=""
                case "$TYPE_VAL" in
                    ADR)     EXPECTED_DOCTYPE="adr" ;;
                    Design)  EXPECTED_DOCTYPE="design" ;;
                    Runbook) EXPECTED_DOCTYPE="runbook" ;;
                    Handoff) EXPECTED_DOCTYPE="handoff" ;;
                    How-To)  EXPECTED_DOCTYPE="howto" ;;
                esac
                if [[ "$FILE_DOCTYPE" == "$EXPECTED_DOCTYPE" ]]; then
                    echo "PASS consistency '$FNAME': Type ($TYPE_VAL) matches doctype ($FILE_DOCTYPE)"
                else
                    echo "FAIL consistency '$FNAME': Type ($TYPE_VAL) doesn't match doctype ($FILE_DOCTYPE)"
                fi
            fi
        fi
    done < "$INDEX_FILE"

    # Check for orphan files (in docs/ but not in INDEX)
    FILES=$(find "$DOCS_DIR" -maxdepth 1 -name '*.md' -type f 2>/dev/null || true)
    if [[ -n "$FILES" ]]; then
        while IFS= read -r filepath; do
            filename=$(basename "$filepath")
            REL_PATH="docs/$filename"
            FOUND=false
            if [[ ${#INDEX_PATHS[@]} -gt 0 ]]; then
                for idx_path in "${INDEX_PATHS[@]}"; do
                    if [[ "$idx_path" == "$REL_PATH" ]]; then
                        FOUND=true
                        break
                    fi
                done
            fi
            if [[ "$FOUND" == false ]]; then
                echo "WARN consistency Orphan file: $REL_PATH (not in README.md)"
            fi
        done <<< "$FILES"
    fi
fi
