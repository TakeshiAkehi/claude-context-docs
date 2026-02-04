# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin called `context-docs` that provides context-aware documentation management. It generates ADR, Design Doc, Runbook, and Handoff documents with intelligent indexing for efficient context retrieval.

## Testing the Plugin

```bash
# Run plugin with Claude Code
claude --plugin-dir /path/to/context-docs

# Test scripts directly
CLAUDE_PROJECT_DIR=/path/to/repo bash scripts/find-context-docs.sh /path/to/start
```

## Architecture

### Component Flow

```
/doc command (commands/doc.md)
    → AskUserQuestion (user selects output location)
    → Creates document using skills/documentation/templates/<type>.md
    → scripts/update-index.sh (updates INDEX.md at selected location)
    → Saves path preference to .claude/doc-paths.json

/recall command (commands/recall.md)
    → Uses context-loader agent (agents/context-loader.md)
    → scripts/find-context-docs.sh (finds all relevant indices)
    → scripts/load-index.sh (loads and merges indices)
    → Loads and presents relevant documents
```

### Key Design Decisions

**Output Location Selection**:
- User explicitly chooses output path via AskUserQuestion
- Options: Project root, current directory, custom path, or recent paths
- Path history stored in `$CLAUDE_PROJECT_DIR/.claude/doc-paths.json`

**Context Loading (on-demand via /recall)**:
- `find-context-docs.sh`: Traverses from current path UP to project root, collecting all `context_doc/INDEX.md` files (nearest first)
- Sibling directory indices are never loaded - only ancestor paths
- No automatic loading at session start — user invokes `/recall` when context is needed

**Index Format**: Markdown table in `context_doc/INDEX.md` with columns: Title, Path, Type, Keywords, Date

**File Naming**: `YYYYMMDD-HHMM-title.md` format for all documents

### Environment Variables

- `CLAUDE_PROJECT_DIR`: Project root (set by Claude Code)
- `CLAUDE_PLUGIN_ROOT`: Plugin directory (set by Claude Code, use in hooks/commands for portability)

## File Purposes

| Path | Purpose |
|------|---------|
| `scripts/find-context-docs.sh` | Find all INDEX.md files from path to root |
| `scripts/load-index.sh` | Loads and merges document indices (used by /recall) |
| `scripts/update-index.sh` | Appends entry to INDEX.md (accepts doc_root parameter) |
| `commands/doc.md` | Instructions for /doc command (includes AskUserQuestion for path selection) |
| `commands/recall.md` | Instructions for /recall command |
| `agents/context-loader.md` | Agent definition for document retrieval |
| `skills/documentation/SKILL.md` | Documentation standards and guidelines |


