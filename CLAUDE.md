# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a marketplace for Claude Code plugins that provides context-aware documentation management. The main plugin is **context-docs**, which enables creation and retrieval of Architecture Decision Records (ADRs), Design Docs, Runbooks, and Handoff documents with intelligent indexing.

The project is structured as a single-plugin marketplace with a standardized marketplace format for easy sharing and distribution.

## Project Structure

```
.
├── context-docs/              # Main plugin directory
│   ├── .claude-plugin/        # Plugin manifest
│   ├── agents/                # Agent definitions for async tasks
│   ├── commands/              # Command implementations (/doc, /recall)
│   ├── hooks/                 # Lifecycle hooks (SessionStart)
│   ├── scripts/               # Shell scripts for file operations
│   ├── skills/                # Skill definitions (documentation standards)
│   └── CLAUDE.md              # Plugin-specific guidance
├── .claude-plugin/            # Marketplace manifest
├── .claude/                   # Local Claude Code settings
└── context_doc/               # Generated documentation directory (docs/ subdirectory)
```

## Key Architecture Decisions

### 1. Hierarchical Document Discovery (Monorepo Support)

The system traverses **upward** from the current file location to the project root to find all `context_doc/INDEX.md` files:

- **Nearest module index** (e.g., `packages/api/context_doc/INDEX.md`) - highest relevance
- **Parent directory indices** (if any)
- **Root index** (e.g., `context_doc/INDEX.md`) - architecture-level context

This hierarchy means documents are loaded based on proximity to where you're working, avoiding irrelevant context from sibling modules.

**Related files**: `scripts/find-context-docs.sh`, `scripts/load-index.sh`

### 2. Document Index as Single Source of Truth

Instead of loading all documents into context at session start, only the `INDEX.md` file (a markdown table) is loaded. This provides:

- **Efficient context**: Index metadata (title, keywords, type) instead of full documents
- **Selective loading**: Only relevant documents fetched via `/recall` command
- **Searchability**: Keywords enable fast matching to current tasks

**Related files**: `scripts/update-index.sh`, `commands/recall.md`

### 3. User-Selected Output Paths

When saving documents, users choose the output location via `AskUserQuestion`:

- **Project root** - for project-wide architectural documentation
- **Current directory** - for module-specific documentation
- **Custom path** - for flexible placement
- **Recent paths** - history of previously used locations

Path selections are persisted in `.claude/doc-paths.json` (up to 5 entries).

**Related files**: `commands/doc.md`, `.claude/settings.local.json`

### 4. Plugin Marketplace Format

The plugin is structured following the Claude Code marketplace specification:

- Single marketplace manifest: `.claude-plugin/marketplace.json`
- Plugin directory with `.claude-plugin/plugin.json`
- Separation of concerns: commands, hooks, agents, scripts, skills, templates

This standardization enables distribution and installation via `/plugin marketplace add`.

**Related files**: `.claude-plugin/marketplace.json`, `context-docs/.claude-plugin/plugin.json`

## Core Scripts

| Script | Purpose |
|--------|---------|
| `scripts/find-context-docs.sh` | Traverse from path to project root, collecting all `context_doc/INDEX.md` files. Output: list of index paths (nearest first). |
| `scripts/load-index.sh` | SessionStart hook that loads and merges indices. Outputs JSON systemMessage containing merged documentation. |
| `scripts/update-index.sh` | Append a new document entry to INDEX.md. Called after `/doc` generates a new document. |

All scripts handle absolute/relative path normalization and use `$CLAUDE_PROJECT_DIR` for cross-platform compatibility.

## Commands

### `/doc <type> [title]`

Generate documentation from current conversation context.

**Types**: `adr`, `design`, `runbook`, `handoff`

**Process**:
1. Validate document type (ask user if missing/invalid)
2. Extract context from conversation
3. Generate document using template
4. Ask user to select output location (project root, current dir, custom, or recent)
5. Show preview and get user confirmation
6. Save document and update INDEX.md
7. Persist selected path to `.claude/doc-paths.json`

**Related files**: `commands/doc.md`, `skills/documentation/templates/`

### `/recall [query...]`

Load relevant documentation from `context_doc/` directories.

**Process**:
1. Find all indices from current location to project root
2. If query provided: search by keywords/title across indices
3. If no query: infer relevant keywords from conversation context
4. Rank results by hierarchy level, keyword match, document type relevance
5. Load top 3-5 documents and present summary

**Related files**: `commands/recall.md`, `agents/context-loader.md`

## Testing

Test scripts independently by setting environment variables:

```bash
# Test index discovery
CLAUDE_PROJECT_DIR=/path/to/repo bash context-docs/scripts/find-context-docs.sh /path/to/start

# Test index loading (as SessionStart hook would)
CLAUDE_PROJECT_DIR=/path/to/repo CLAUDE_PLUGIN_ROOT=/path/to/context-docs bash context-docs/scripts/load-index.sh

# Test with specific start path
CLAUDE_PROJECT_DIR=/path/to/repo CLAUDE_PLUGIN_ROOT=/path/to/context-docs bash context-docs/scripts/load-index.sh /path/to/start
```

Verify script output format matches expected JSON structure with `"continue": true` and `"systemMessage"` fields.

## Document Naming Convention

All documents follow: `YYYYMMDD-<doctype>-<title>.md`

Example: `20260202-adr-api-authentication-jwt.md`

This format ensures:
- **Chronological sorting**: Dates appear naturally in file listings
- **Type identification**: Document type is visible in the filename
- **Uniqueness**: Date + type + title prevents collisions
- **Searchability**: Date prefix enables finding recent documents

## Index Format

The `INDEX.md` file is a markdown table with columns:

| Title | Path | Type | Keywords | Date |
|-------|------|------|----------|------|

Example:
```markdown
# Document Index

| Title | Path | Type | Keywords | Date |
|-------|------|------|----------|------|
| API Authentication Strategy | docs/20260201-adr-api-auth.md | ADR | auth, jwt, oauth, security | 2026-02-01 |
| User Service Design | docs/20260202-design-user-service.md | Design | user, crud, api, database | 2026-02-02 |
```

## Development Guidelines

### Adding New Document Types

1. Create template in `context-docs/skills/documentation/templates/<type>.md`
2. Update `/doc` command to recognize new type in validation
3. Update `/recall` to handle new type in ranking/presentation
4. Document the new type in `context-docs/README.md`

### Modifying Index Discovery

Changes to hierarchical loading logic should be made in `scripts/find-context-docs.sh`. This script is the source of truth for path traversal.

### Shell Script Safety

All scripts use `set -euo pipefail` for safety. When modifying:
- Quote all variables that contain paths
- Validate input paths before operations
- Test with paths containing spaces and special characters

### Backwards Compatibility

The `load-index.sh` script includes backwards compatibility fallback (lines 20-32) for projects with a single root-level `INDEX.md`. Maintain this fallback when making changes.

## Related Documentation

- **Plugin Details**: See `context-docs/README.md` for comprehensive plugin documentation
- **Plugin-Specific Guidance**: See `context-docs/CLAUDE.md` for plugin development details
- **Skill Guidelines**: See `context-docs/skills/documentation/SKILL.md` for documentation standards
- **Marketplace Format**: See `.claude-plugin/marketplace.json` for plugin distribution
