# Context Docs Marketplace

Context-aware documentation plugins for Claude Code.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| **context-docs** | Context-aware documentation management. Generate ADRs, Design Docs, Runbooks, and Handoffs with intelligent indexing. |

## Installation

### 1. Add the Marketplace

```
/plugin marketplace add <GitHub URL or path>
```

Example:
```
/plugin marketplace add https://github.com/lidarman/claude-context-docs
```

Or for local development:
```
/plugin marketplace add /path/to/claude-context-docs
```

### 2. Install a Plugin

```
/plugin install context-docs@context-docs-marketplace
```

## Plugin Details

See individual plugin READMEs for detailed documentation:

- [context-docs](./context-docs/README.md) - Documentation management plugin

## License

MIT
