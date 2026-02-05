---
description: Validate context_doc directories conform to plugin conventions
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
---

Validate all `context_doc/` directories in the project to ensure they conform to plugin conventions.

## Process

1. **Discover all context_doc directories**:
   - Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/find-context-docs.sh $(pwd)` to find all `context_doc/README.md` files from the current location to the project root
   - Extract the parent directory of each README.md to get `context_doc/` paths
   - If no context_doc directories are found, inform the user and suggest using `/doc` to create documentation first

2. **Run validation on each context_doc directory**:
   - For each discovered `context_doc/` path, run:
     ```
     bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-context-docs.sh <context_doc_path>
     ```
   - Capture the output (one line per check result)

3. **Parse and categorize results**:
   Each output line has the format: `STATUS CATEGORY MESSAGE`
   - **STATUS**: `PASS`, `FAIL`, `WARN`, or `INFO`
   - **CATEGORY**: `structure`, `naming`, `index`, `consistency`
   - **MESSAGE**: Human-readable description

   Group results by category and compute summary:
   - **structure** → "Directory Structure"
   - **naming** → "Document Naming"
   - **index** → "README.md Format"
   - **consistency** → "Cross-Reference"

4. **Display maintenance report**:

   Format the output as a structured report for each location:

   ```
   ## Maintenance Report

   ### <relative_path_to_context_doc>

   | Category | Status | Details |
   |----------|--------|---------|
   | Directory Structure | ✓ PASS | All N checks passed |
   | Document Naming | ✗ FAIL | M issue(s) found |
   | README.md Format | ✓ PASS | All N checks passed |
   | Cross-Reference | ⚠ WARN | M warning(s) found |
   ```

   **Status symbols:**
   - `✓ PASS` — All checks in this category passed (no FAIL or WARN)
   - `✗ FAIL` — At least one FAIL in this category
   - `⚠ WARN` — No FAIL but at least one WARN in this category
   - `ℹ INFO` — Only informational messages (e.g., no files to check)

   **If there are FAIL or WARN results**, list them under an "Issues Found" section:

   ```
   #### Issues Found

   1. ✗ **Naming**: `old-doc.md` doesn't match `YYYYMMDD-<doctype>-<title>.md`
   2. ⚠ **Orphan**: `docs/20260203-design-new.md` is not in README.md
   ```

   **If all checks pass**, display:
   ```
   ✓ All checks passed. Your context_doc structure is in good shape.
   ```

5. **Suggest actions for failures**:
   If issues are found, provide actionable recommendations:
   - **Missing README.md**: "Run `/doc` to create a document, which will auto-create README.md"
   - **Missing docs/ directory**: "Create `docs/` directory inside context_doc"
   - **Naming violations**: "Rename file to follow `YYYYMMDD-<doctype>-<title>.md` format"
   - **Old-style subdirectories**: "Move files from old subdirectories into `docs/` with proper naming"
   - **Invalid INDEX Type**: "Update Type column to one of: ADR, Design, Runbook, Handoff, How-To"
   - **Orphan files**: "Add missing entries to README.md using the index format"
   - **Missing files**: "Remove stale INDEX entries or restore the missing document files"
   - **Type/doctype mismatch**: "Ensure INDEX Type matches the doctype in the filename"

   Do NOT offer to auto-fix issues. Only report and recommend.

## Output Example

```
## Maintenance Report

### /project/context_doc

| Category | Status | Details |
|----------|--------|---------|
| Directory Structure | ✓ PASS | All 4 checks passed |
| Document Naming | ✗ FAIL | 1 issue found |
| README.md Format | ✓ PASS | All 5 checks passed |
| Cross-Reference | ⚠ WARN | 1 warning found |

#### Issues Found

1. ✗ **Naming**: `old-doc.md` doesn't match `YYYYMMDD-<doctype>-<title>.md`
2. ⚠ **Orphan**: `docs/20260203-design-new.md` is not in README.md

#### Recommendations

- Rename `old-doc.md` to follow `YYYYMMDD-<doctype>-<title>.md` format
- Add `docs/20260203-design-new.md` to README.md
```

## Edge Cases

- **No context_doc directories found**: Report this and suggest using `/doc` to create documentation
- **Empty docs/ directory**: Report as INFO, not a failure
- **README.md exists but has no entries**: Report as INFO
- **Multiple context_doc directories** (monorepo): Validate each independently, report all results
