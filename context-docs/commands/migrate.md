---
description: Migrate context_doc directories from old per-type subdirectory structure to new flat docs/ structure
argument-hint: [path]
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

Migrate documentation from the old per-type subdirectory structure (`context_doc/<type>/`) to the new flat structure (`context_doc/docs/`).

## Old vs New Structure

**Old** (per-type subdirectories):
```
context_doc/
├── adr/
│   └── 20260201-1430-api-auth.md
├── design/
│   └── 20260202-0900-user-service.md
└── INDEX.md
```

**New** (flat docs/ with doctype prefix):
```
context_doc/
├── docs/
│   ├── 20260201-adr-api-auth.md
│   └── 20260202-design-user-service.md
└── INDEX.md
```

## Process

1. **Discover migration targets**:

   **If `$ARGUMENTS` is provided**: Use that path as the `context_doc/` directory to migrate.

   **If no arguments**: Use `bash ${CLAUDE_PLUGIN_ROOT}/scripts/find-context-docs.sh $(pwd)` to find all `context_doc/INDEX.md` paths. Derive the `context_doc/` directory from each path by stripping the trailing `/INDEX.md`. Then check each directory for old-style subdirectories (adr/, design/, runbook/, handoff/, howto/).

   Additionally, use Glob to search for `**/context_doc/{adr,design,runbook,handoff,howto}/` directories that may not have an INDEX.md yet.

   If no old-style subdirectories are found at any location, inform the user that there's nothing to migrate.

2. **Generate dry-run preview**:

   For each `context_doc/` path that has old-style subdirectories, run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/migrate-docs.sh --dry-run <context_doc_path>
   ```

   Parse the output and present it to the user in a readable format:

   ```
   ## Migration Preview

   **Location**: <context_doc_path>
   **Files to migrate**: <count>

   | Action | Source | Destination |
   |--------|--------|-------------|
   | Move | adr/20260201-1430-api-auth.md | docs/20260201-adr-api-auth.md |
   | Move | design/20260202-0900-user-service.md | docs/20260202-design-user-service.md |
   | Skip | adr/README.md | (pattern mismatch) |
   | Conflict | docs/20260201-adr-api-auth.md | (already exists) |

   **Index updates**: <count> entries will be rewritten
   **Cleanup**: <dirs> empty directories will be removed
   ```

3. **Ask user for confirmation**:

   Use AskUserQuestion:
   ```
   question: "マイグレーションを実行しますか？"
   header: "Migrate"
   options:
     - label: "実行する"
       description: "上記のファイル移動とINDEX.md更新を実行します"
     - label: "キャンセル"
       description: "変更を加えずに終了します"
   ```

   If cancelled, inform the user and exit.

4. **Execute migration**:

   For each `context_doc/` path:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/migrate-docs.sh <context_doc_path>
   ```

5. **Verify and report results**:

   After execution:
   - Check that the expected files exist in `docs/`
   - Verify INDEX.md paths have been updated
   - Report results:

   ```
   ## Migration Complete

   - **Moved**: <count> files
   - **Index updated**: <count> entries
   - **Directories cleaned**: <list>
   - **Skipped**: <count> files (pattern mismatch)
   - **Conflicts**: <count> files (destination already exists)
   ```

## Edge Cases

- **Nothing to migrate**: If no old-style subdirectories exist, output "No migration needed — your documentation already uses the new structure."
- **Multiple locations** (monorepo): Process each `context_doc/` independently, show combined preview
- **Partial migration**: If some files were already moved manually, the script handles mixed states gracefully
- **No INDEX.md**: File moves proceed; index rewriting is skipped
- **Conflicts**: Files whose destination already exists are skipped (not overwritten)

## Output

**On success**: Report moved files count, index updates, and cleaned directories
**On cancel**: "Migration cancelled. No files were modified."
**On nothing to migrate**: "No migration needed — your documentation already uses the new structure."
