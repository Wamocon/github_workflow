# Workflow Guide — How It All Works

This document explains the four reusable GitHub Actions workflows, how they connect, and exactly how to integrate them into any project.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                        CENTRAL SHARED REPO                          │
│  .github/workflows/                                                 │
│    ├── pr-checks.yml          (typecheck + lint)                    │
│    ├── pr-autofix.yml         (auto-fix + commit back)              │
│    ├── deploy-preview.yml     (Vercel preview → test schema)        │
│    └── deploy-production.yml  (Vercel production → prod schema)     │
└──────────────────────────────────────────────────────────────────────┘
                          ▲                  ▲
                          │ workflow_call    │ workflow_call
              ┌───────────┘                  └──────────────┐
              │                                             │
   ┌──────────┴──────────┐                    ┌─────────────┴─────────┐
   │   PROJECT REPO A    │                    │    PROJECT REPO B     │
   │  .github/workflows/ │                    │  .github/workflows/   │
   │   pr-pipeline.yml   │                    │   pr-pipeline.yml     │
   │   prod-deploy.yml   │                    │   prod-deploy.yml     │
   └─────────────────────┘                    └───────────────────────┘
```

Each project repo contains **two small caller files** that reference the central workflows. No workflow logic lives inside individual projects.

---

## Execution Flow

### Flow 1 — Pull Request (feature branch → main)

When a developer opens or updates a Pull Request targeting `main` or `master`:

```
PR Opened / Updated
       │
       ▼
┌─────────────────┐
│  1. Auto-Fix     │  Runs ESLint --fix and Prettier --write
│  (pr-autofix)    │  Commits fixes back to the PR branch
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. PR Checks    │  Runs tsc --noEmit and eslint .
│  (pr-checks)     │  ❌ Fails = PR is blocked from merging
└────────┬────────┘
         │ ✅ Pass
         ▼
┌─────────────────┐
│  3. Preview      │  Deploys to Vercel preview environment
│  (deploy-preview)│  Uses NEXT_PUBLIC_DB_SCHEMA=test
└─────────────────┘
         │
         ▼
   Preview URL generated
   (visible in PR checks / job summary)
```

### Flow 2 — Merge to Main (production deployment)

When a PR is merged (or code is pushed directly) into `main` or `master`:

```
Push / Merge to main
       │
       ▼
┌──────────────────────┐
│  Deploy Production    │  Deploys to Vercel production
│  (deploy-production)  │  Uses NEXT_PUBLIC_DB_SCHEMA=prod
└──────────────────────┘
       │
       ▼
  Production URL updated
```

---

## Step-by-Step Integration for Any Project

### Flexibility by Repository Type

- Frontend-only Next.js projects: use the same deploy workflows without changes.
- Full-stack Next.js projects (frontend + API routes/server actions): use the same deploy workflows without changes.
- Projects with custom schema names: pass `db-schema` in caller workflow `with:`.

Defaults remain:
- Preview: `vercel-environment=preview`
- Production: `vercel-environment=production`
- Schema override: empty (uses Vercel env value)

### Prerequisites

Before integrating, ensure each project repository has these **GitHub Secrets** configured:

| Secret Name          | Where to Get It                                |
|----------------------|------------------------------------------------|
| `VERCEL_TOKEN`       | Vercel Dashboard → Settings → Tokens           |
| `VERCEL_PROJECT_ID`  | Run `vercel link` locally, check `.vercel/project.json` |

Set `VERCEL_ORG_ID` once at organisation level (secret or variable), then add repo-level secrets for `VERCEL_TOKEN` and `VERCEL_PROJECT_ID`.

### Step 1: Copy the Caller Workflows

Copy the two example files from this repository's `examples/` folder into your project:

```
your-project/
  .github/
    workflows/
      pr-pipeline.yml          ← from examples/caller-pr-pipeline.yml
      production-deploy.yml    ← from examples/caller-production-deploy.yml
```

### Step 2: Update the Organisation & Repository Name

In **both** copied files, replace the placeholder values:

```yaml
# BEFORE
uses: YOUR_ORG/THIS_REPO/.github/workflows/pr-checks.yml@main

# AFTER (example)
uses: wamocon/github_workflow/.github/workflows/pr-checks.yml@main
```

Replace:
- `YOUR_ORG` → your GitHub organisation name (e.g., `wamocon`)
- `THIS_REPO` → the name of this central shared repository (e.g., `github-workflow`)

### Step 3: Commit & Push

```bash
git add .github/workflows/
git commit -m "ci: add shared workflow integration"
git push origin main
```

### Step 4: Verify

1. Create a new feature branch and open a PR against `main`.
2. Watch the **Actions** tab — you should see the three jobs (Auto-Fix → PR Checks → Deploy Preview) run in sequence.
3. Merge the PR and verify the production deployment triggers.

---

## Detailed Workflow Reference

### 1. PR Checks (`pr-checks.yml`)

| Property     | Value                                              |
|--------------|----------------------------------------------------|
| **Trigger**  | `workflow_call` (called by consumer repos)         |
| **Purpose**  | Gate-keep the PR — blocks merge if code is bad     |
| **Inputs**   | `node-version` (default: 20)                       |

**What it does:**
1. Checks out the code
2. Installs dependencies via `npm ci`
3. Runs `npm run tsc -- --noEmit` — catches TypeScript errors
4. Runs `npm run eslint -- .` — catches code quality issues

**If it fails:** The PR status check turns red and the merge button is blocked (when branch protection rules are configured).

---

### 2. PR Auto-Fix (`pr-autofix.yml`)

| Property     | Value                                              |
|--------------|----------------------------------------------------|
| **Trigger**  | `workflow_call` (called by consumer repos)         |
| **Purpose**  | Automatically fix and commit lint/format issues    |
| **Inputs**   | `node-version` (default: 20)                       |
| **Permissions** | `contents: write` (to push the fix commit)      |

**What it does:**
1. Checks out the PR branch
2. Installs dependencies
3. Runs `npm run eslint -- . --fix` — auto-fixes lint errors
4. Runs `npm run prettier -- --write .` — formats all files
5. Uses `stefanzweifel/git-auto-commit-action` to commit changes back

**Result:** If there are fixable issues, a new commit appears on the PR with the message `style: auto-fix lint and formatting issues`.

---

### 3. Deploy Preview (`deploy-preview.yml`)

| Property     | Value                                              |
|--------------|----------------------------------------------------|
| **Trigger**  | `workflow_call` (called after pr-checks passes)    |
| **Purpose**  | Create a preview deployment with the test DB       |
| **Secrets**  | `VERCEL_TOKEN`, `VERCEL_PROJECT_ID` (plus org-level `VERCEL_ORG_ID`) |
| **Inputs**   | `node-version`, `vercel-environment` (default `preview`), `db-schema` (optional) |

**What it does:**
1. Pulls the Vercel **preview** environment config — this sets `NEXT_PUBLIC_DB_SCHEMA=test`
2. If `db-schema` input is set, overrides `NEXT_PUBLIC_DB_SCHEMA` for this repository
3. Builds frontend and backend runtime with `vercel build` (pages, API routes, route handlers, server actions)
4. Deploys with `vercel deploy --prebuilt`
5. Outputs the preview URL in the GitHub Actions job summary

**Important:** The preview deployment always uses the **test** database schema, ensuring developers never accidentally test against production data.

---

### 4. Deploy Production (`deploy-production.yml`)

| Property     | Value                                              |
|--------------|----------------------------------------------------|
| **Trigger**  | `workflow_call` (when code reaches main/master)    |
| **Purpose**  | Deploy to the live production domain               |
| **Secrets**  | `VERCEL_TOKEN`, `VERCEL_PROJECT_ID` (plus org-level `VERCEL_ORG_ID`) |
| **Inputs**   | `node-version`, `vercel-environment` (default `production`), `db-schema` (optional) |

**What it does:**
1. Pulls the Vercel **production** environment config — this sets `NEXT_PUBLIC_DB_SCHEMA=prod`
2. If `db-schema` input is set, overrides `NEXT_PUBLIC_DB_SCHEMA` for this repository
3. Builds frontend and backend runtime with `vercel build --prod` (pages, API routes, route handlers, server actions)
4. Deploys with `vercel deploy --prebuilt --prod`
5. Outputs the production URL in the GitHub Actions job summary

### Example Custom Overrides

Use this in caller workflows when a repository uses non-default schema names:

```yaml
with:
  node-version: "20"
  vercel-environment: preview
  db-schema: qa
```

---

## Branch Protection Rules (Recommended)

To enforce that no code reaches `main` without passing checks, configure branch protection:

1. Go to **GitHub → Repo → Settings → Branches → Branch protection rules**
2. Click **Add rule** for the `main` branch
3. Enable:
   - **Require a pull request before merging**
   - **Require status checks to pass before merging**
     - Add `PR Checks / Typecheck & Lint` as a required check
   - **Require branches to be up to date before merging**

This guarantees that every merge into `main` has passed type-checking and linting.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Workflows don't run | Ensure the central repo is **public** or that consumer repos have access. For private repos, make it an **internal** repo within the same org. |
| `VERCEL_TOKEN` error | Verify the secret is added under **Settings → Secrets → Actions** in the consumer repo (not this central repo). |
| Auto-fix creates infinite loop | The `git-auto-commit-action` uses `GITHUB_TOKEN` which does not re-trigger workflows by design. If using a PAT instead, add a `[skip ci]` suffix to the commit message. |
| Preview URL not visible | Check the **job summary** tab in the Actions run, or look at the deploy step's logs. |
| npm lockfile issue | Ensure `package-lock.json` is committed and up to date, then rerun. |
| Node version mismatch | Pass the correct version via inputs: `with: node-version: "18"` in your caller workflow. |
