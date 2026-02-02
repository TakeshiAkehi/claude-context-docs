---
description: Generate documentation (adr, design, runbook, handoff) from current context
argument-hint: <type> [title]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Generate a documentation file based on the current conversation context.

## Document Type

The first argument `$1` specifies the document type:
- `adr` - Architecture Decision Record
- `design` - Design Document
- `runbook` - Runbook (operational procedures)
- `handoff` - Session handoff document

## Process

1. **Validate document type**: Ensure `$1` is one of: adr, design, runbook, handoff. If invalid or missing, ask the user which type to create.

2. **Extract context from conversation**: Analyze the current conversation to identify:
   - Key decisions made
   - Problems discussed
   - Solutions implemented
   - Technical details relevant to the document type

3. **Gather additional information**: If essential information is missing for the document type, use AskUserQuestion to collect:
   - For ADR: Decision context, alternatives considered, consequences
   - For Design: Requirements, constraints, dependencies
   - For Runbook: Prerequisites, steps, error handling
   - For Handoff: Current state, next steps, blockers

4. **Generate document**: Create the document following the template at `${CLAUDE_PLUGIN_ROOT}/skills/documentation/templates/<type>.md`

5. **Determine filename**:
   - Format: `YYYYMMDD-HHMM-<title>.md`
   - Use current timestamp
   - If `$2` provided, use it as title (convert to kebab-case)
   - Otherwise, derive title from document content

6. **Ask user for output location**: Use AskUserQuestion to prompt where to save the document.

   **Build options dynamically:**
   - Option 1: **Project root** (`$CLAUDE_PROJECT_DIR`) - Recommended for project-wide docs
   - Option 2: **Current directory** (`$(pwd)`) - Good for module-specific documentation
   - Option 3: **Custom path** - User enters any valid directory path
   - Option 4+ (if exists): **Recent paths** from `$CLAUDE_PROJECT_DIR/.claude/doc-paths.json`

   **AskUserQuestion format:**
   ```
   question: "Where should this <type> document be saved?"
   header: "Output Path"
   options:
     - label: "Project root (Recommended)"
       description: "$CLAUDE_PROJECT_DIR/context_doc/<type>/"
     - label: "Current directory"
       description: "$(pwd)/context_doc/<type>/"
     - label: "Custom path"
       description: "Enter a custom directory path"
     - label: "Recent: <last_used_path>" (if doc-paths.json exists)
       description: "<last_used_path>/context_doc/<type>/"
   ```

   **Handle response:**
   - If "Project root" selected: use `$CLAUDE_PROJECT_DIR`
   - If "Current directory" selected: use current working directory
   - If "Custom path" selected: ask for path input and validate it exists (or offer to create)
   - If "Recent" selected: use the corresponding path from history

7. **Preview document and get user approval**: Before saving, show the generated document to the user for review.

   **Display format:**
   ```
   ## Document Preview

   **Type**: <type>
   **Filename**: <filename>.md
   **Output path**: <selected_path>/context_doc/<type>/

   ---
   <full document content>
   ---
   ```

   **Use AskUserQuestion to confirm:**
   ```
   question: "このドキュメントの内容を確認してください。保存してよろしいですか？"
   header: "確認"
   options:
     - label: "保存する"
       description: "このままファイルに保存します"
     - label: "修正を依頼"
       description: "修正点を伝えて内容を調整します"
     - label: "キャンセル"
       description: "ドキュメントを保存せずに終了します"
   ```

   **Handle response:**
   - If "保存する" selected: proceed to save
   - If "修正を依頼" selected: ask what to change, regenerate, and show preview again
   - If "キャンセル" selected: abort without saving, inform user

8. **Save path preference**: After user approves, update `$CLAUDE_PROJECT_DIR/.claude/doc-paths.json`:
   ```json
   {
     "recent_paths": ["<selected_path>", ...previous up to 5],
     "last_used": "<selected_path>"
   }
   ```
   - Add selected path to front of `recent_paths` (if not already present)
   - Keep maximum 5 entries (LRU eviction)
   - Set `last_used` to selected path
   - Create `.claude/` directory if needed

9. **Save document**: Write to `<selected_path>/context_doc/<type>/<filename>.md`
   - Create `<selected_path>/context_doc/<type>/` directory if it doesn't exist

10. **Update index**: Add entry to `<selected_path>/context_doc/INDEX.md`
    - Create INDEX.md if it doesn't exist (use template format below)
    - Add new row with: Title, Path, Type, Keywords, Date

## Index Format

```markdown
# Document Index

| Title | Path | Type | Keywords | Date |
|-------|------|------|----------|------|
```

## Keywords Extraction

Extract 3-5 relevant keywords from the document content for searchability.
Focus on: technologies, concepts, component names, problem domains.

## Path History

Document output paths are saved in `$CLAUDE_PROJECT_DIR/.claude/doc-paths.json`:
- Stores up to 5 recently used paths
- Most recent path shown as "Recent" option in selection
- Project-specific (different projects have separate histories)

## Example Structure

```
project-root/
├── .claude/
│   └── doc-paths.json       # Path history
├── context_doc/             # Root-level docs (if user selects project root)
│   ├── INDEX.md
│   └── adr/
├── packages/
│   ├── api/
│   │   └── context_doc/     # API-specific docs (if user selects this path)
│   │       ├── INDEX.md
│   │       └── design/
│   └── ui/
│       └── context_doc/     # UI-specific docs (if user selects this path)
```

## Output

**On successful save**, report:
- Document type created
- File path (full path where it was saved)
- Keywords indexed
- Brief summary of content

**On cancel**, report:
- Document creation was cancelled by user
- No files were written
