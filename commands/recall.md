---
description: Load relevant documents from context_doc based on current task or query
argument-hint: [query...]
allowed-tools: Read, Glob, Grep, Bash
---

Load relevant documentation from the project's context_doc directories to build context for the current task.

## Process

1. **Find relevant indices (Monorepo Support)**:
   - Determine current working context (file being edited, current directory)
   - Use `bash ${CLAUDE_PLUGIN_ROOT}/scripts/find-context-docs.sh $(pwd)` to find all indices
   - Traverse from current location to project root
   - Load all `context_doc/INDEX.md` files found along the path
   - Merge indices with hierarchy indicators (nearest module first, then root)
   - If no indices exist, inform user to create documents first using `/doc`

   **Hierarchy Order (nearest first):**
   - Nearest module's `context_doc/INDEX.md` (most specific, highest relevance)
   - Parent directories' indices (if any)
   - Root `context_doc/INDEX.md` (most general, architecture-level)

2. **Determine search strategy**:

   **If query provided (`$ARGUMENTS` is not empty)**:
   - Search for documents matching the query keywords
   - Match against: Title, Keywords, Type columns in all loaded indices
   - Rank by relevance (keyword frequency, hierarchy level, recency)

   **If no query provided**:
   - Analyze current conversation context
   - Identify key topics, technologies, components being discussed
   - Infer relevant keywords from the task at hand
   - Search all loaded indices for documents matching inferred keywords

3. **Select documents**:
   - Identify top 3-5 most relevant documents
   - Prioritize by:
     1. Hierarchy level (nearest module > parent > root)
     2. Keyword match strength
     3. Document type relevance to current task
     4. Recency (newer documents may have more current decisions)

4. **Load documents**:
   - Read each selected document fully
   - Build context from document contents

5. **Present summary**:
   - List documents loaded with brief descriptions
   - Indicate source (module name or root)
   - Explain relevance to current task
   - Highlight key points from each document

## Output Format

```
## Documents Loaded

### 1. [Title] (Type)
- **Source**: [Root | module-path]
- **Path**: context_doc/type/filename.md
- **Keywords**: keyword1, keyword2, keyword3
- **Relevance**: Why this document is relevant to current task
- **Key Points**:
  - Point 1
  - Point 2

### 2. [Title] (Type)
...
```

## Monorepo Behavior

In a monorepo with submodules:
- Multiple indices may be loaded (e.g., api module + root)
- Documents from the nearest module have higher relevance
- Root-level documents provide architectural context
- Unrelated module indices are NOT loaded (only ancestor paths)

**Example**: Working on `packages/api/src/handlers.ts`:

| Loaded | Path | Reason |
|--------|------|--------|
| Yes | `packages/api/context_doc/INDEX.md` | Nearest module |
| Yes | `context_doc/INDEX.md` | Root architecture |
| No | `packages/ui/context_doc/INDEX.md` | Different module path |

## Edge Cases

- **No index exists**: Guide user to create documents with `/doc`
- **No matching documents**: Inform user and suggest creating relevant documentation
- **Query too broad**: Ask user to refine search terms
- **Large result set**: Limit to top 5 most relevant, mention others exist
- **Multiple modules**: Group results by source, indicate hierarchy level
