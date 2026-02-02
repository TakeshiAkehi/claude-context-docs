# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin called `context-docs` that provides context-aware documentation management. It generates ADR, Design Doc, Runbook, and Handoff documents with intelligent indexing for efficient context retrieval. Supports both single-repo and monorepo (git submodule) structures.

## Testing the Plugin

```bash
# Run plugin with Claude Code
claude --plugin-dir /path/to/context-docs

# Test scripts directly
CLAUDE_PROJECT_DIR=/path/to/repo bash scripts/find-context-docs.sh /path/to/start
CLAUDE_PROJECT_DIR=/path/to/repo bash scripts/find-doc-root.sh /path/to/start
```

## Architecture

### Component Flow

```
SessionStart Hook (hooks/hooks.json)
    → scripts/load-index.sh
        → scripts/find-context-docs.sh (hierarchical index discovery)
        → Outputs JSON with systemMessage containing merged indices

/doc command (commands/doc.md)
    → scripts/find-doc-root.sh (determines output location)
    → Creates document using skills/documentation/templates/<type>.md
    → scripts/update-index.sh (updates INDEX.md)

/recall command (commands/recall.md)
    → Uses context-loader agent (agents/context-loader.md)
    → scripts/find-context-docs.sh (finds all relevant indices)
    → Loads and presents relevant documents
```

### Key Design Decisions

**Monorepo Support**:
- `find-context-docs.sh`: Traverses from current path UP to project root, collecting all `context_doc/INDEX.md` files (nearest first)
- `find-doc-root.sh`: Detects submodule boundaries by checking for `.git` FILE (not directory) - submodules have `.git` as a file pointing to main repo
- Sibling module indices are never loaded - only ancestor paths

**Index Format**: Markdown table in `context_doc/INDEX.md` with columns: Title, Path, Type, Keywords, Date

**File Naming**: `YYYYMMDD-HHMM-title.md` format for all documents

### Environment Variables

- `CLAUDE_PROJECT_DIR`: Project root (set by Claude Code)
- `CLAUDE_PLUGIN_ROOT`: Plugin directory (set by Claude Code, use in hooks/commands for portability)

## File Purposes

| Path | Purpose |
|------|---------|
| `scripts/find-context-docs.sh` | Find all INDEX.md files from path to root |
| `scripts/find-doc-root.sh` | Determine document output location (submodule detection) |
| `scripts/load-index.sh` | SessionStart hook - loads and merges indices |
| `scripts/update-index.sh` | Appends entry to INDEX.md |
| `commands/doc.md` | Instructions for /doc command |
| `commands/recall.md` | Instructions for /recall command |
| `agents/context-loader.md` | Agent definition for document retrieval |
| `skills/documentation/SKILL.md` | Documentation standards and guidelines |
