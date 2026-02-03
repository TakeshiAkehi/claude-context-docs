---
name: documentation-standards
description: This skill should be used when creating ADR, Design Doc, Runbook, or Handoff documents, when following documentation best practices, when structuring technical documentation, or when maintaining document indexes.
version: 1.0.0
---

# Documentation Standards for Context-Aware Documentation

## Document Types

### ADR (Architecture Decision Record)

**Purpose**: Record significant architectural decisions with context and consequences.

**When to create**:
- Choosing between technologies or frameworks
- Defining system boundaries or interfaces
- Making irreversible or costly-to-change decisions
- Establishing patterns or conventions

**Key sections**:
- Status (Proposed/Accepted/Deprecated/Superseded)
- Context (Why this decision is needed)
- Decision (What was decided)
- Consequences (Positive, Negative, Risks)
- Alternatives Considered

**Template**: `${CLAUDE_PLUGIN_ROOT}/skills/documentation/templates/adr.md`

### Design Document

**Purpose**: Document the design of features, systems, or components before implementation.

**When to create**:
- Planning new features
- Designing system architecture
- Documenting complex implementations
- Coordinating cross-team work

**Key sections**:
- Goals and Non-Goals
- Requirements (Functional/Non-Functional)
- Architecture and Components
- Implementation Plan
- Testing Strategy

**Template**: `${CLAUDE_PLUGIN_ROOT}/skills/documentation/templates/design.md`

### Runbook

**Purpose**: Document step-by-step procedures for operational tasks.

**When to create**:
- Deployment procedures
- Incident response
- Maintenance tasks
- Debugging common issues

**Key sections**:
- Prerequisites
- Step-by-step Procedure
- Rollback Procedure
- Troubleshooting
- Post-procedure Verification

**Template**: `${CLAUDE_PLUGIN_ROOT}/skills/documentation/templates/runbook.md`

### Handoff

**Purpose**: Capture session state for continuity between work sessions.

**When to create**:
- End of work session
- Before context window fills
- When switching between tasks
- Before taking a break from complex work

**Key sections**:
- Summary
- Current State (Completed/In Progress/Not Started)
- Key Decisions Made
- Technical Context
- Next Steps

**Template**: `${CLAUDE_PLUGIN_ROOT}/skills/documentation/templates/handoff.md`

## File Naming Convention

All documents use the format: `YYYYMMDD-HHMM-<title>.md`

- **Date/Time**: Use current timestamp at creation
- **Title**: Kebab-case, descriptive, 3-5 words
- **Examples**:
  - `20260202-1430-api-authentication-jwt.md`
  - `20260202-0900-user-service-design.md`
  - `20260201-1645-database-migration.md`

## Index Management

### Index Location

`context_doc/INDEX.md`

### Index Format

```markdown
# Document Index

| Title | Path | Type | Keywords | Date |
|-------|------|------|----------|------|
| API Authentication with JWT | adr/20260202-1430-api-auth-jwt.md | ADR | auth, jwt, security, api | 2026-02-02 |
```

### Keywords Guidelines

Extract 3-5 keywords per document:
- Technology names (jwt, postgres, react)
- Concepts (auth, caching, validation)
- Component names (user-service, api-gateway)
- Problem domains (security, performance, scalability)

## Writing Guidelines

### For AI Context Efficiency

1. **Front-load key information**: Put decisions, conclusions, and critical facts at the beginning
2. **Use structured formats**: Tables, lists, and headers for easy scanning
3. **Include searchable keywords**: Use consistent terminology throughout
4. **Link related documents**: Reference related ADRs, design docs by path

### For Human Readability

1. **Provide context**: Explain why, not just what
2. **Include examples**: Concrete examples clarify abstract concepts
3. **Use consistent formatting**: Follow templates for predictability
4. **Keep it current**: Update status, mark deprecated documents

### Quality Checklist

- [ ] Title clearly describes content
- [ ] Keywords are accurate and searchable
- [ ] Status is current
- [ ] All template sections are filled or marked N/A
- [ ] Related documents are linked
- [ ] Date is accurate
