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

6. **Determine document root (Monorepo Support)**:
   - Find the nearest submodule boundary by checking for `.git` file (not directory) in parent directories
   - Use `bash ${CLAUDE_PLUGIN_ROOT}/scripts/find-doc-root.sh $(pwd)` to determine placement
   - If in a submodule, use that submodule's root for `context_doc/`
   - If not in a submodule, use project root (`$CLAUDE_PROJECT_DIR`)
   - This keeps module-specific documentation with its module

7. **Save document**: Write to `<doc_root>/context_doc/<type>/<filename>.md`
   - Create `<doc_root>/context_doc/<type>/` directory if it doesn't exist

8. **Update index**: Add entry to `<doc_root>/context_doc/INDEX.md`
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

## Monorepo Support

When working in a monorepo with git submodules:
- Documents are created in the `context_doc/` directory of the nearest submodule
- Root-level architecture docs belong in the main project root
- This keeps module-specific documentation with its module

**Submodule Detection:**
```bash
# A submodule root has .git as a FILE (not directory)
[ -f .git ]  # Returns true for submodule roots
```

**Example Structure:**
```
project-root/
├── context_doc/           # Root-level docs (architecture)
├── packages/
│   ├── api/               # Submodule
│   │   └── context_doc/   # API-specific docs created here
│   └── ui/                # Submodule
│       └── context_doc/   # UI-specific docs created here
```

## Output

After completion, report:
- Document type created
- File path (including which module/root it was saved to)
- Keywords indexed
- Brief summary of content
