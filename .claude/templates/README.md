# Documentation Templates

Templates for project documentation. Copy these to your project and customize.

## Available Templates

| Template | Purpose | Copy To |
|----------|---------|---------|
| `PROJECT_STATE.template.md` | **MANDATORY** - Project state tracking | `project/PROJECT_STATE.md` |
| `FEATURES.template.md` | Track feature status | `project/FEATURES.md` |
| `PLAN.template.md` | Development roadmap | `project/PLAN.md` |
| `CONTEXT.template.md` | Component context for AI | `component/CONTEXT.md` |

## Usage

```bash
# Copy feature tracking template
cp .claude/templates/FEATURES.template.md your-project/FEATURES.md

# Copy plan template
cp .claude/templates/PLAN.template.md your-project/PLAN.md

# Copy context template for a component
cp .claude/templates/CONTEXT.template.md your-project/src/component/CONTEXT.md
```

## Best Practices

1. **ALWAYS update `PROJECT_STATE.md` after every task or code change** (MANDATORY)
2. Update `FEATURES.md` whenever a feature is added or modified
3. Update `PLAN.md` at the start and end of each work session
4. Add `CONTEXT.md` to complex components that need explanation
