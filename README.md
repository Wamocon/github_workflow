# WAMOCON — Shared Workflows & Developer Guide

Central repository containing reusable GitHub Actions workflows and standardised documentation for all organisation projects.

---

## Repository Structure

```
.
├── .github/
│   ├── copilot-instructions.md     # Workspace-level GitHub Copilot instructions for this repo
│   └── workflows/
│       ├── pr-checks.yml            # Reusable: TypeScript + ESLint validation
│       ├── pr-autofix.yml           # Reusable: Auto-fix lint & format errors
│       ├── deploy-preview.yml       # Reusable: Vercel preview deployment (test schema)
│       └── deploy-production.yml    # Reusable: Vercel production deployment (prod schema)
├── examples/
│   ├── caller-pr-pipeline.yml       # Copy this → your project's PR workflow
│   └── caller-production-deploy.yml # Copy this → your project's production workflow
├── docs/
│   ├── workflow-guide.md            # How the 4 workflows work & integration steps
│   ├── supabase-vercel-linking.md   # Linking projects to Supabase & Vercel
│   ├── database-schema-migrations.md # Database migration workflow (mandatory)
│   ├── mcp-setup.md                 # AI tool MCP configuration for Supabase
│   ├── github-copilot-guide.md      # GitHub Copilot usage guide
│   └── tips-and-best-practices.md   # General tips, conventions, and debugging
└── README.md                        # This file
```

---

## Quick Start (For Any New Project)

### 1. Copy the Caller Workflows

Copy the two files from `examples/` into your project's `.github/workflows/` directory:

```bash
# From your project root
mkdir -p .github/workflows
cp path/to/this-repo/examples/caller-pr-pipeline.yml .github/workflows/pr-pipeline.yml
cp path/to/this-repo/examples/caller-production-deploy.yml .github/workflows/production-deploy.yml
```

### 2. Update Organisation & Repo Name

In both files, replace `YOUR_ORG/THIS_REPO` with your actual values:

```yaml
uses: wamocon/github-workflow/.github/workflows/pr-checks.yml@main
```

### 3. Add GitHub Secrets

In your project's GitHub repo, go to **Settings → Secrets → Actions** and add:

| Secret              | Source                                   |
|---------------------|------------------------------------------|
| `VERCEL_TOKEN`      | Vercel Dashboard → Settings → Tokens     |
| `VERCEL_PROJECT_ID` | `.vercel/project.json` after `vercel link` |

Set `VERCEL_ORG_ID` once at organisation level (GitHub org secret or variable) so it does not need to be passed in each workflow action.

### 4. Done

- **Open a PR** → Auto-fix runs → Checks run → Preview deploys
- **Merge to main** → Production deploys

---

## How It Works

```
Developer opens PR against main/master
       │
       ├─→ Auto-Fix (eslint --fix, prettier --write, commit back)
       │
       ├─→ PR Checks (tsc --noEmit, eslint .)
       │          │
       │          ├─ ❌ Fail → PR blocked
       │          └─ ✅ Pass ↓
       │
       └─→ Preview Deploy (Vercel preview, test DB schema)

Developer merges PR into main
       │
       └─→ Production Deploy (Vercel production, prod DB schema)
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Workflow Guide](docs/workflow-guide.md) | Detailed explanation of all 4 workflows, execution flow, integration steps, and troubleshooting |
| [Supabase & Vercel Linking](docs/supabase-vercel-linking.md) | How to link projects, configure environment variables, and set up secrets |
| [Database Schema & Migrations](docs/database-schema-migrations.md) | Mandatory migration workflow — never use the Supabase UI for schema changes |
| [MCP Setup](docs/mcp-setup.md) | Configure AI tools to read your database schema via Supabase MCP |
| [GitHub Copilot Guide](docs/github-copilot-guide.md) | Features, shortcuts, prompting tips, and integration with our stack |
| [Tips & Best Practices](docs/tips-and-best-practices.md) | Git conventions, code quality, debugging, and quick reference commands |

---

## GitHub Copilot Instructions

### Repo-Level (Team Shared)

This repository uses a workspace instruction file at:

- [.github/copilot-instructions.md](.github/copilot-instructions.md)

If a project should enforce team-specific Copilot behavior, keep this file in that repo under `.github/copilot-instructions.md`.

### User-Level (Personal, Works Across All Repos)

If a developer wants personal instructions without adding files in every repository, they can create a user-level instruction file in:

- `%APPDATA%\\Code\\User\\prompts\\`
- Typical Windows path: `C:\Users\<your-user>\AppData\Roaming\Code\User\prompts\`

Example user-level file:

- `C:\Users\<your-user>\AppData\Roaming\Code\User\prompts\my-default.instructions.md`

Example content:

```md
---
description: "Use when generating or editing code in any repo"
---

- Always check linting, formatting, type checks, and build impact.
- For database tasks, use MCP with the correct project reference.
- Prefer minimal, safe changes and explain assumptions.
```

When both exist:

- Repo-level instructions define project/team rules.
- User-level instructions add personal defaults across repositories.

Use repo-level instructions for shared team standards, and user-level instructions for personal preferences.

---

## Requirements for Consumer Projects

Each project that uses these shared workflows needs:

- **npm** as the package manager (for `npm ci`, `npm run eslint`, `npm run tsc`)
- **TypeScript** configured with `tsconfig.json`
- **ESLint** configured (`.eslintrc.*` or `eslint.config.*`)
- **Prettier** configured (`.prettierrc` or `prettier.config.*`)
- A **Vercel project** linked via `vercel link`
- Repo secrets: `VERCEL_TOKEN`, `VERCEL_PROJECT_ID`
- Organisation-level secret or variable: `VERCEL_ORG_ID`
