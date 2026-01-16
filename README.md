# GRIP - Global Registry Intelligence Platform

Master Entity Records from 135+ national registries.

## Overview

GRIP collects legal entity data from business, tax, and financial registries worldwide, providing:
- Single Master Entity Record per legal entity
- Bi-temporal tracking (valid time + system time)
- Automated entity resolution (85%+ STP rate)
- Full data lineage and audit trail

## Tech Stack

- **Frontend**: Next.js 14, TypeScript, Tailwind CSS
- **Backend**: Node.js (planned)
- **Database**: PostgreSQL + Neo4j (planned)

## Getting Started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Documentation

- `req/spec.md` - Complete platform specification
- `req/plan.md` - Implementation plan
- `req/registries_table.md` - Registry data (135 sources)

## Project Structure

```
├── src/app/          # Next.js App Router pages
├── req/              # Requirements & specifications
├── .claude/          # AI agent templates
├── CLAUDE.md         # AI agent guidelines
└── PROJECT_STATE.md  # Project state tracking (mandatory)
```

## License

See LICENSE file.
