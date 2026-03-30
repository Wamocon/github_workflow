# Workflow Guide — How It All Works

This document explains the reusable GitHub Actions workflows, how they connect, and exactly how to integrate them into any project.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                        CENTRAL SHARED REPO                          │
│  .github/workflows/                                                 │
│    ├── pr-checks.yml       (typecheck + lint)            reusable   │
│    ├── pr-autofix.yml      (auto-fix + commit back)      reusable   │
│    └── deploy-preview.yml  (Vercel CLI deploy)           reusable   │
└──────────────────────────────────────────────────────────────────────┘
                          ▲
                          │ workflow_call
              ┌───────────┘
              │
   ┌──────────┴──────────────────────┐
   │         PROJECT REPO            │
   │  .github/workflows/             │
   │    pr-pipeline.yml              │  → calls pr-autofix + pr-checks
   │    deploy.yml                   │  → calls deploy-preview (unified)
   └─────────────────────────────────┘
```

Each project repo contains **two small caller files**. All workflow logic lives in the central repo.

- **`pr-pipeline.yml`** — runs on every PR: auto-fixes lint/format, then validates with typecheck + lint.
- **`deploy.yml`** — runs on both PR and push events: preview deployment for PRs, production deployment for merges to `main`/`master`.

---

## Execution Flow

### Flow 1 — Pull Request opened or updated

```
PR Opened / Updated (targeting main or master)
       │
       ├────────────────────────────────────────────────────┐
       ▼                                                    ▼
┌──────────────────────┐                    ┌──────────────────────────┐
│   pr-pipeline.yml    │                    │      deploy.yml          │
│                      │                    │                          │
│  1. Auto-Fix         │  ESLint --fix      │  set-vars job            │
│     (pr-autofix)     │  Prettier --write  │   → vercel_env=preview   │
│                      │  commits to PR     │   → vercel_args=(empty)  │
│  2. PR Checks        │  tsc --noEmit      │                          │
│     (pr-checks)      │  eslint .          │  deploy job              │
│     ❌ blocks merge  │                    │   → vercel pull preview  │
└──────────────────────┘                    │   → vercel build         │
                                            │   → vercel deploy        │
                                            └──────────────────────────┘
                                                         │
                                                         ▼
                                               Preview URL in job summary
```

### Flow 2 — Merge (push) to main/master

```
Push / Merge to main or master
       │
       ▼
┌──────────────────────────┐
│      deploy.yml          │
│                          │
│  set-vars job            │
│   → vercel_env=production│
│   → vercel_args=--prod   │
│                          │
│  deploy job              │
│   → vercel pull prod     │
│   → vercel build --prod  │
│   → vercel deploy --prod │
└──────────────────────────┘
         │
         ▼
   Production URL updated
```

---

## Step-by-Step Integration for Any Project

### Schema Flexibility

The `db_schema` input on `deploy-preview.yml` is **optional and defaults to empty**.

| Project type | What to do | Result |
|---|---|---|
| Uses `public` or any single schema | Leave `db_schema` empty (default) | Schema comes from Vercel Dashboard env vars |
| Uses `test` / `prod` schema per environment | Leave `db_schema` empty, configure in Vercel Dashboard | Vercel pull fetches the right value automatically |
| Non-standard schema names (e.g. `qa`, `live`) | Pass `db_schema: "qa"` in the caller `with:` block | Overrides whatever Vercel has |

### Prerequisites

Before integrating, ensure these **GitHub Secrets** are configured:

| Secret Name        | Scope        | Where to Get It                                      |
|--------------------|--------------|------------------------------------------------------|
| `VERCEL_TOKEN`     | Organisation | Vercel Dashboard → Settings → Tokens                 |
| `VERCEL_ORG_ID`    | Organisation | `.vercel/project.json` → `orgId` after `vercel link` |
| `VERCEL_PROJECT_ID`| Repository   | `.vercel/project.json` → `projectId`                 |

`VERCEL_TOKEN` and `VERCEL_ORG_ID` are set **once** at organisation level. `VERCEL_PROJECT_ID` is a repo-level secret (each project has its own Vercel project).

### Step 1: Copy the Caller Workflows

Copy **both** example files from this repository's `examples/` folder into your project:

```
your-project/
  .github/
    workflows/
      pr-pipeline.yml    ← from examples/caller-pr-pipeline.yml
      deploy.yml         ← from examples/caller-production-deploy.yml
```

### Step 2: Replace the Placeholders

In **both** copied files, replace:

```yaml
# BEFORE
uses: YOUR_ORG/THIS_REPO/.github/workflows/pr-checks.yml@main

# AFTER
uses: Wamocon/github_workflow/.github/workflows/pr-checks.yml@main
```

- `YOUR_ORG` → your GitHub organisation name (e.g. `Wamocon`)
- `THIS_REPO` → this central repository name (e.g. `github_workflow`)

### Step 3: (Optional) Configure Schema Override

If your project uses non-standard Supabase schema names, uncomment and set the `db_schema` input in `deploy.yml`:

```yaml
with:
  vercel_env: ${{ needs.set-vars.outputs.vercel_env }}
  vercel_args: ${{ needs.set-vars.outputs.vercel_args }}
  db_schema: "qa"    # your custom schema name
```

For most projects, leave it empty — Vercel env vars handle the schema automatically.

### Step 4: Add the Repo Secret

Go to **GitHub → Your Repo → Settings → Secrets and variables → Actions** and add:

| Secret             | Value                          |
|--------------------|--------------------------------|
| `VERCEL_PROJECT_ID`| From `.vercel/project.json`    |

(`VERCEL_TOKEN` and `VERCEL_ORG_ID` are already at org level — nothing to add.)

### Step 5: Commit & Push

```bash
git add .github/workflows/
git commit -m "ci: add shared workflow integration"
git push origin main
```

### Step 6: Verify

1. Open a PR targeting `main` — the **Actions** tab should show `PR Pipeline` (auto-fix + checks) and `Deploy` (Vercel preview) running in parallel.
2. Check the **Deploy** job summary for the preview URL.
3. Merge the PR — the **Deploy** job should trigger again and deploy to production.

---

## Detailed Workflow Reference

### 1. PR Checks (`pr-checks.yml`)

| Property        | Value                                                     |
|-----------------|-----------------------------------------------------------|
| **Trigger**     | `workflow_call`                                           |
| **Purpose**     | Gate-keep the PR — blocks merge if code is bad            |
| **Inputs**      | `node-version` (default: `"20"`)                          |

**What it does:**
1. Checks out the code
2. Installs dependencies via `npm ci`
3. Runs `npm run tsc -- --noEmit` — catches TypeScript errors
4. Runs `npm run eslint -- .` — catches code quality issues

**If it fails:** The PR status check turns red and the merge button is blocked (when branch protection rules are configured).

---

### 2. PR Auto-Fix (`pr-autofix.yml`)

| Property        | Value                                                     |
|-----------------|-----------------------------------------------------------|
| **Trigger**     | `workflow_call`                                           |
| **Purpose**     | Automatically fix and commit lint/format issues           |
| **Inputs**      | `node-version` (default: `"20"`)                          |
| **Permissions** | `contents: write` — to push the fix commit               |

**What it does:**
1. Checks out the PR branch
2. Installs dependencies
3. Runs `npm run eslint -- . --fix` — auto-fixes lint errors
4. Runs `npm run prettier -- --write .` — formats all files
5. Uses `stefanzweifel/git-auto-commit-action` to commit changes back

**Result:** A new commit appears on the PR with the message `style: auto-fix lint and formatting issues`.

---

### 3. Deploy (`deploy-preview.yml`)

| Property    | Value                                                                                          |
|-------------|------------------------------------------------------------------------------------------------|
| **Trigger** | `workflow_call` (called by consumer repo `deploy.yml`)                                         |
| **Purpose** | Unified Vercel CLI deployment — preview for PRs, production for merges                         |
| **Inputs**  | `vercel_env` (required), `vercel_args` (optional, default `""`), `db_schema` (optional, default `""`) |
| **Secrets** | `VERCEL_TOKEN`, `VERCEL_PROJECT_ID` (required); `VERCEL_ORG_ID` (optional — org level)         |

**Inputs explained:**

| Input        | Values                        | Set by                           |
|--------------|-------------------------------|----------------------------------|
| `vercel_env` | `"preview"` or `"production"` | `set-vars` job in caller         |
| `vercel_args`| `""` or `"--prod"`            | `set-vars` job in caller         |
| `db_schema`  | `""` or e.g. `"qa"`           | Optional — leave empty for most projects |

**What it does:**
1. Installs Vercel CLI (`vercel@latest`) globally
2. Runs `vercel pull --yes --environment=[vercel_env]` — fetches env vars from Vercel Dashboard for the target environment
3. If `db_schema` is non-empty, overrides `NEXT_PUBLIC_DB_SCHEMA` with that value
4. Runs `vercel build [vercel_args]`
5. Runs `vercel deploy --prebuilt [vercel_args]`
6. Outputs the deployment URL to the job summary

**Deployment matrix (driven by the caller's `set-vars` job):**

| Event in caller | `vercel_env`  | `vercel_args` | Vercel result         |
|-----------------|---------------|---------------|-----------------------|
| `pull_request`  | `preview`     | _(empty)_     | Preview deployment    |
| `push`          | `production`  | `--prod`      | Production deployment |

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
| `VERCEL_TOKEN` error | Verify `VERCEL_TOKEN` is set at **organisation level** under Settings → Secrets → Actions. |
| `VERCEL_PROJECT_ID` not found | Ensure `VERCEL_PROJECT_ID` is set as a **repo-level** secret in the consumer repo. |
| Preview deploys when push expected | Confirm the event is `push` not `pull_request` — check the Actions tab trigger label. |
| Schema is wrong in deployment | Check what `NEXT_PUBLIC_DB_SCHEMA` is set to in Vercel Dashboard under the Preview / Production environment. Pass `db_schema` in the caller only if you need to override it. |
| Auto-fix creates infinite loop | The `git-auto-commit-action` uses `GITHUB_TOKEN` which does not re-trigger workflows by design. If using a PAT instead, add a `[skip ci]` suffix to the commit message. |
| Deployment URL not visible | Check the **job summary** tab in the Actions run, or look at the deploy step's logs. |
| npm lockfile issue | Ensure `package-lock.json` is committed and up to date, then rerun. |
