# CLAUDE.md - AI Agent Guidelines

This file provides rules and context for LLMs and AI agents working on projects in this repository.

---

## MANDATORY Rules

> These rules MUST be followed. No exceptions.

### 1. Update `PROJECT_STATE.md` After Every Change

**After EVERY task completion or code modification, you MUST update the project's `PROJECT_STATE.md` file.**

This file tracks:
- What was changed and why
- Current state of the codebase
- Features implemented and their status
- Known issues or incomplete work
- Next steps or pending tasks

If the file doesn't exist, create it. If it exists, append or update the relevant sections.

```markdown
## Recent Changes (YYYY-MM-DD)

### Task: [Brief description]
- **Files modified**: list of files
- **What changed**: description
- **Status**: complete/partial
- **Notes**: any relevant context
```

---

## Core Principles

1. **Read before writing** - Always read and understand existing code before making modifications
2. **Minimal changes** - Only change what's necessary to complete the task
3. **Preserve patterns** - Follow existing code style, naming conventions, and architecture
4. **Document changes** - Update relevant documentation when implementing features

---

## Project Structure Requirements

### Component Organization

Each logical component/package should follow this structure:

```
component-name/
├── README.md           # Component overview, purpose, and usage
├── CONTEXT.md          # Technical context for AI agents (optional)
├── src/                # Source code
├── tests/              # Tests for this component
└── docs/               # Additional documentation (if needed)
```

### Context Files

When creating new components or packages, include a `README.md` or `CONTEXT.md` with:

- **Purpose**: What this component does and why it exists
- **Dependencies**: External libraries and internal dependencies
- **Key files**: Important files and their responsibilities
- **Patterns**: Design patterns and conventions used
- **Gotchas**: Non-obvious behavior or constraints

---

## Documentation Requirements

### When Implementing Features

Before starting work:
1. Check for existing `PLAN.md` or `FEATURES.md` in the project
2. Review current feature list and roadmap

After completing work:
1. Update `FEATURES.md` with new/modified features
2. Update `PLAN.md` to reflect progress
3. Add inline comments only where logic is non-obvious

### Required Documentation Files (per project)

| File | Purpose |
|------|---------|
| `README.md` | Project overview, setup, and usage |
| `FEATURES.md` | List of implemented features and their status |
| `PLAN.md` | Current development plan and roadmap |
| `CHANGELOG.md` | Version history (for released projects) |

---

## Code Quality Rules

### Do

- Follow existing patterns in the codebase
- Write self-documenting code with clear naming
- Add tests for new functionality
- Handle errors at system boundaries
- Keep functions focused and small

### Don't

- Add features beyond what was requested
- Over-engineer or add unnecessary abstractions
- Add comments for obvious code
- Create utilities for one-time operations
- Leave debug code or console.log statements

---

## File Naming Conventions

- Components: `PascalCase.tsx` or `PascalCase.vue`
- Utilities: `kebab-case.ts`
- Tests: `*.test.ts` or `*.spec.ts`
- Documentation: `UPPERCASE.md` for root docs, `lowercase.md` for nested

---

## Task Workflow

1. **Understand** - Read relevant code and documentation
2. **Plan** - Break down into small, trackable tasks
3. **Implement** - Make minimal, focused changes
4. **Test** - Verify changes work as expected
5. **Document** - Update FEATURES.md and PLAN.md
6. **Review** - Check for unintended side effects

---

## Pre-Commit Checklist (Local CI/CD)

> No remote CI/CD configured yet. Agents MUST run these checks locally before committing.

Before committing, agents MUST:

1. **Run tests** (if test suite exists):
   ```bash
   npm test  # or: pytest, go test, etc.
   ```

2. **Run linter/formatter** (if configured):
   ```bash
   npm run lint  # or: ruff, eslint, prettier, etc.
   ```

3. **Verify build** (if applicable):
   ```bash
   npm run build  # or equivalent
   ```

4. **Update documentation**:
   - Update `PROJECT_STATE.md` (MANDATORY)
   - Update `FEATURES.md` if features changed
   - Update `PLAN.md` if roadmap affected

If any check fails, fix the issue before committing.

<!-- TODO: Add CI/CD automation rules when GitHub Actions or similar is configured -->

---

## Project-Specific Overrides

Individual projects may include their own `CLAUDE.md` or `.claude/` directory with project-specific rules that override these defaults.

---

## Questions?

When uncertain about implementation details:
1. Check existing code for patterns
2. Look for project-specific documentation
3. Ask the user for clarification

---

*Last updated: 2026-01-16*
