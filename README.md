# context-docs

Context-aware documentation management for Claude Code.

## Overview

This plugin helps you create and manage project documentation that serves dual purposes:
1. **Human-readable documentation** - For developers to understand the repository
2. **AI context optimization** - For Claude to efficiently load relevant knowledge

## Features

- **Document Generation** (`/doc <type>`) - Generate ADR, Design Doc, Runbook, or Handoff from current context
- **Smart Recall** (`/recall [query]`) - Load relevant documents based on current task or explicit query
- **Automatic Indexing** - Maintains a searchable index of all documents
- **Session Integration** - Automatically loads document index at session start
- **Monorepo Support** - Hierarchical context loading for git submodules

## Plugin Components

| Type | Count | Description |
|------|-------|-------------|
| Commands | 2 | `/doc`, `/recall` |
| Hooks | 1 | SessionStart (インデックス自動読み込み) |
| Skills | 1 | documentation-standards |
| Agents | 1 | context-loader |
| Templates | 4 | ADR, Design, Runbook, Handoff |

### Plugin Structure

```
context-docs/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── agents/
│   └── context-loader.md    # Document retrieval agent
├── commands/
│   ├── doc.md               # /doc command
│   └── recall.md            # /recall command
├── hooks/
│   └── hooks.json           # SessionStart hook
├── scripts/
│   ├── find-context-docs.sh # Find indices from path to root
│   ├── find-doc-root.sh     # Find document output location
│   ├── load-index.sh        # Index loader script
│   └── update-index.sh      # Index updater script
├── skills/
│   └── documentation/
│       ├── SKILL.md         # Documentation standards
│       └── templates/       # Document templates
│           ├── adr.md
│           ├── design.md
│           ├── handoff.md
│           └── runbook.md
├── LICENSE
└── README.md
```

## Document Types

| Type | Purpose | Use When |
|------|---------|----------|
| **ADR** | Architecture Decision Record | Making significant technical choices |
| **Design Doc** | Design documentation | Planning feature implementation |
| **Runbook** | Operational procedures | Documenting how to perform tasks |
| **Handoff** | Session transition notes | Ending a session or switching context |

## Usage

### Generate Documents

```bash
/doc adr       # Create an Architecture Decision Record
/doc design    # Create a Design Document
/doc runbook   # Create a Runbook
/doc handoff   # Create a Handoff document
```

### Recall Documents

```bash
/recall              # Auto-detect relevant docs from current task
/recall auth api     # Search for docs matching "auth" and "api"
```

### Automatic Behavior

- **Session Start**: Document index (`context_doc/INDEX.md`) is automatically loaded
- **Document Creation**: Index is automatically updated when documents are generated

## Project Directory Structure

Documents are stored in `context_doc/` at your project root:

```
context_doc/
├── INDEX.md          # Document index (auto-maintained)
├── adr/              # Architecture Decision Records
├── design/           # Design Documents
├── runbook/          # Runbooks
└── handoff/          # Handoff documents
```

## Monorepo Support

For projects with git submodules, context-docs supports hierarchical documentation.

### Monorepo Structure

```
project-root/                     # Main repo
├── context_doc/                  # Root-level docs (architecture)
│   ├── INDEX.md
│   └── adr/
├── packages/
│   ├── api/                      # Submodule
│   │   ├── context_doc/          # API-specific docs
│   │   │   ├── INDEX.md
│   │   │   └── design/
│   │   └── src/
│   └── ui/                       # Submodule
│       ├── context_doc/          # UI-specific docs
│       │   └── INDEX.md
│       └── src/
```

### How It Works

**Document Generation (`/doc`):**
- Detects if you're in a submodule (checks for `.git` file)
- Creates `context_doc/` in the appropriate location
- Submodule docs stay with their module
- Root-level docs go to project root

**Context Loading (`/recall`, SessionStart):**
- Traverses from current file location to project root
- Loads all `context_doc/INDEX.md` files in the path
- Nearest module context has highest relevance
- Sibling modules are NOT loaded (avoids irrelevant context)

### Example Scenario

When editing `packages/api/src/handlers.ts`:

| Loaded | Path | Reason |
|--------|------|--------|
| ✅ Yes | `packages/api/context_doc/INDEX.md` | Nearest module |
| ✅ Yes | `context_doc/INDEX.md` | Root architecture |
| ❌ No | `packages/ui/context_doc/INDEX.md` | Different module path |

### Submodule Detection

Git submodules are detected by checking for a `.git` file (not directory):
- Submodule roots have `.git` as a **file** pointing to the main repo
- Regular repo roots have `.git` as a **directory**

```bash
# Check if current directory is a submodule root
[ -f .git ]  # Returns true for submodule roots
```

## Index Format

The `INDEX.md` file maintains a searchable table:

```markdown
# Document Index

| Title | Path | Type | Keywords | Date |
|-------|------|------|----------|------|
| API Authentication | adr/20260201-1000-api-auth.md | ADR | auth, jwt, oauth | 2026-02-01 |
| User Service Design | design/20260202-0900-user-service.md | Design | user, crud, api | 2026-02-02 |
```

## File Naming Convention

All documents follow the format: `YYYYMMDD-HHMM-title.md`

Examples:
- `20260202-1430-api-authentication-jwt.md`
- `20260202-0900-user-service-design.md`
- `20260201-1645-database-migration.md`

## Installation

### Option 1: Plugin directory flag

```bash
claude --plugin-dir /path/to/context-docs
```

### Option 2: Copy to plugins directory

```bash
cp -r context-docs ~/.claude/plugins/
```

### Option 3: Symlink

```bash
ln -s /path/to/context-docs ~/.claude/plugins/context-docs
```

## Testing

1. **Start Claude Code with the plugin**:
   ```bash
   claude --plugin-dir /path/to/context-docs
   ```

2. **Verify commands**: Run `/help` to confirm commands are available

3. **Test document generation**: Run `/doc adr` to create an ADR

4. **Test recall**: Run `/recall` to verify index loading

### Testing Monorepo Support

```bash
# Test find-context-docs.sh
bash scripts/find-context-docs.sh /path/to/submodule/src

# Test find-doc-root.sh
bash scripts/find-doc-root.sh /path/to/submodule/src
```

## How It Works

### Context Efficiency

1. **Index-based retrieval**: Instead of loading all documents, only the index is loaded at session start
2. **Keyword matching**: Documents are retrieved based on keyword relevance to current task
3. **Selective loading**: Only relevant documents are fully loaded into context
4. **Hierarchical loading**: In monorepos, only ancestor path indices are loaded

### Workflow

```
Session Start
    ↓
Load INDEX.md (hierarchical in monorepo)
    ↓
Work on task
    ↓
/recall → Load relevant docs (from all ancestor indices)
    ↓
/doc <type> → Generate documentation (in appropriate module)
    ↓
Update INDEX.md (in appropriate module)
```

## License

MIT
