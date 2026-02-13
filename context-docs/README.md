# context-docs

Context-aware documentation management for Claude Code.

## Overview

This plugin helps you create and manage project documentation that serves dual purposes:
1. **Human-readable documentation** - For developers to understand the repository
2. **AI context optimization** - For Claude to efficiently load relevant knowledge

## Features

- **Document Generation** (`/doc <type>`) - Generate ADR, Design Doc, Feature Spec, Runbook, or Handoff with interactive path selection
- **Smart Recall** (`/recall [query]`) - Load relevant documents based on current task or explicit query
- **Structure Validation** (`/maintain`) - Validate context_doc directories conform to plugin conventions
- **Automatic Indexing** - Maintains a searchable index of all documents
- **Session Integration** - Automatically loads document index at session start
- **Flexible Output** - Save documents to any location (project root, current directory, or custom path)
- **Hierarchical Context Loading** - Load indices from multiple locations in monorepos

## Plugin Components

| Type | Count | Description |
|------|-------|-------------|
| Commands | 3 | `/doc`, `/recall`, `/maintain` |
| Hooks | 1 | SessionStart (インデックス自動読み込み) |
| Skills | 1 | documentation-standards |
| Agents | 1 | context-loader |
| Templates | 5 | ADR, Design, Spec, Runbook, Handoff |

### Plugin Structure

```
context-docs/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── agents/
│   └── context-loader.md    # Document retrieval agent
├── commands/
│   ├── doc.md               # /doc command
│   ├── maintain.md          # /maintain command
│   └── recall.md            # /recall command
├── hooks/
│   └── hooks.json           # SessionStart hook
├── scripts/
│   ├── find-context-docs.sh          # Find indices from path to root
│   ├── load-index.sh                 # Index loader script
│   ├── update-index.sh               # Index updater script
│   └── validate-context-docs.sh      # Validate context_doc structure
├── skills/
│   └── documentation/
│       ├── SKILL.md         # Documentation standards
│       └── templates/       # Document templates
│           ├── adr.md
│           ├── design.md
│           ├── handoff.md
│           ├── runbook.md
│           └── spec.md
├── CLAUDE.md
└── README.md
```

## Document Types

| Type | Purpose | Use When |
|------|---------|----------|
| **ADR** | Architecture Decision Record | Making significant technical choices |
| **Design Doc** | Design documentation | Planning feature implementation |
| **Spec** | Feature Specification | Recording completed feature behavior and constraints |
| **Runbook** | Operational procedures | Documenting how to perform tasks |
| **Handoff** | Session transition notes | Ending a session or switching context |

## Usage

### Generate Documents

```bash
/doc adr       # Create an Architecture Decision Record
/doc design    # Create a Design Document
/doc spec      # Create a Feature Specification
/doc runbook   # Create a Runbook
/doc handoff   # Create a Handoff document
```

When you run `/doc`, you'll be asked where to save the document:

```
Where should this ADR document be saved?

1. Project root (Recommended): /path/to/project/context_doc/docs/
2. Current directory: /path/to/current/context_doc/docs/
3. Custom path: Enter a custom directory path
4. Recent: /path/to/packages/api/ (last used)
```

### Recall Documents

```bash
/recall              # Auto-detect relevant docs from current task
/recall auth api     # Search for docs matching "auth" and "api"
```

### Validate Structure

```bash
/maintain            # Check all context_doc/ directories for convention compliance
```

### Automatic Behavior

- **Session Start**: Document index (`context_doc/README.md`) is automatically loaded
- **Document Creation**: Index is automatically updated when documents are generated
- **Path History**: Recently used output paths are remembered and shown as options

## Project Directory Structure

Documents are stored in `context_doc/` at your chosen location:

```
your-chosen-path/
├── context_doc/
│   ├── README.md          # Document index (auto-maintained)
│   └── docs/             # All documents (ADR, Design, Spec, Runbook, Handoff, How-To)
```

## Multiple Documentation Locations

You can have `context_doc/` directories at multiple locations in your project:

```
project-root/
├── .claude/
│   └── doc-paths.json       # Path history (auto-maintained)
├── context_doc/             # Root-level docs (architecture, overall design)
│   ├── README.md
│   └── docs/
├── packages/
│   ├── api/
│   │   └── context_doc/     # API-specific docs
│   │       ├── README.md
│   │       └── docs/
│   └── ui/
│       └── context_doc/     # UI-specific docs
│           └── README.md
```

### Context Loading Behavior

When using `/recall` or at session start:
- Traverses from current file location to project root
- Loads all `context_doc/README.md` files in the path
- Nearest location has highest relevance
- Sibling directories are NOT loaded (avoids irrelevant context)

**Example**: Working on `packages/api/src/handlers.ts`:

| Loaded | Path | Reason |
|--------|------|--------|
| ✅ Yes | `packages/api/context_doc/README.md` | Nearest location |
| ✅ Yes | `context_doc/README.md` | Root architecture |
| ❌ No | `packages/ui/context_doc/README.md` | Different branch path |

## Index Format

The `README.md` file maintains a searchable table:

```markdown
# Document Index

| Title | Type | Keywords | Date |
|-------|------|----------|------|
| [API Authentication](docs/20260201-adr-api-auth.md) | ADR | auth, jwt, oauth | 2026-02-01 |
| [User Service Design](docs/20260202-design-user-service.md) | Design | user, crud, api | 2026-02-02 |
```

## File Naming Convention

All documents follow the format: `YYYYMMDD-<doctype>-title.md`

Examples:
- `20260202-adr-api-authentication-jwt.md`
- `20260202-design-user-service.md`
- `20260201-runbook-database-migration.md`

## How It Works

### Context Efficiency

1. **Index-based retrieval**: Instead of loading all documents, only the index is loaded at session start
2. **Keyword matching**: Documents are retrieved based on keyword relevance to current task
3. **Selective loading**: Only relevant documents are fully loaded into context
4. **Hierarchical loading**: Only ancestor path indices are loaded (avoids unrelated context)

### Workflow

```
Session Start
    ↓
Load README.md (from current path to root)
    ↓
Work on task
    ↓
/recall → Load relevant docs
    ↓
/doc <type> → User selects output location
    ↓
Generate documentation → Update README.md
```

## License

MIT
