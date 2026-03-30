# Supabase & Vercel Linking

This document covers how to link your local development environment to Vercel and configure the standardised environment variables that all projects must use.

---

## Standard Environment Variables

Every project in the organisation **must** use these exact variable names. This ensures consistency across all repositories.

| Variable Name                  | Description                              | Required | Example Value                                         |
|-------------------------------|------------------------------------------|----------|-------------------------------------------------------|
| `NEXT_PUBLIC_SUPABASE_URL`    | The Supabase project API URL             | Yes      | `https://xyzabcdef.supabase.co`                       |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | The Supabase anonymous/public key       | Yes      | `eyJhbGciOiJIUzI1NiIs...`                             |
| `NEXT_PUBLIC_DB_SCHEMA`       | The database schema to use               | Yes      | `test` (preview) or `prod` (production)               |
| `SUPABASE_SERVICE_ROLE_KEY`   | Server-side only Supabase service key    | Optional | `eyJhbGciOiJIUzI1NiIs...`                             |
| `DATABASE_URL`                | Direct Postgres connection string        | Optional | `postgresql://postgres:[PASSWORD]@db.xyzabcdef.supabase.co:5432/postgres` |

Optional usage guidance:
- `SUPABASE_SERVICE_ROLE_KEY` is only needed for trusted backend/admin operations.
- `DATABASE_URL` is only needed for direct SQL tooling or drivers.
- If you manage schema via Supabase project UI + MCP-guided SQL flow, these optional values can remain unset.

> **Important:** `NEXT_PUBLIC_DB_SCHEMA` is automatically set by the Vercel environment pull in CI/CD:
> - **Preview deployments** → `test`
> - **Production deployments** → `prod`

These are defaults only. If a repository uses custom schema names (for example `qa` and `live`), set `db-schema` in the caller workflow inputs for preview/production deploy jobs.

---

## Linking a New Project to Vercel

### Step 1: Install the Vercel CLI

```bash
npm install -g vercel
```

### Step 2: Log In

```bash
vercel login
```

Follow the prompts to authenticate with your WAMOCON organisation email.

### Step 3: Link Your Project

Navigate to the root of your project and run:

```bash
vercel link
```

You will be asked:
1. **Set up project?** → Yes
2. **Which scope?** → Select the WAMOCON organisation
3. **Link to existing project?** → Yes (if the Vercel project already exists) or No to create one
4. **What's your project's name?** → Use the same name as the GitHub repository

This creates a `.vercel/` folder in your project with `project.json`:

```json
{
  "orgId": "team_xxxxxxxxxxxxxxx",
  "projectId": "prj_xxxxxxxxxxxxxxx"
}
```

> **Do NOT commit `.vercel/` to git.** It should already be in `.gitignore`.

### Step 4: Extract the Secret Values

From `.vercel/project.json`, copy:
- `orgId` → This is your `VERCEL_ORG_ID` (set once at organisation level)
- `projectId` → This is your `VERCEL_PROJECT_ID_PROD` (production Vercel project)

If you maintain a separate Vercel project for staging, link that project with `vercel link` and copy its `projectId` as `VERCEL_PROJECT_ID_STAGING`.

Your `VERCEL_TOKEN` is generated from Vercel Dashboard → Settings → Tokens.

### Step 5: Add Secrets to GitHub

Set `VERCEL_ORG_ID` and `VERCEL_TOKEN` once in **GitHub Organisation Secrets**.

Then go to **GitHub → Your Repo → Settings → Secrets and variables → Actions** and add:

| Secret Name                 | Scope        | Value                                          |
|-----------------------------|--------------|------------------------------------------------|
| `VERCEL_TOKEN`              | Organisation | Your Vercel personal access token              |
| `VERCEL_ORG_ID`             | Organisation | `orgId` from `.vercel/project.json`            |
| `VERCEL_PROJECT_ID_PROD`    | Repository   | `projectId` of the production Vercel project   |
| `VERCEL_PROJECT_ID_STAGING` | Repository   | `projectId` of the staging Vercel project      |

---

## Configuring Vercel Environment Variables

In the Vercel Dashboard for each project:

1. Go to **Settings → Environment Variables**
2. Add the following variables:

### Preview Environment

| Variable                        | Value         | Environment |
|---------------------------------|---------------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL`      | (your URL)    | Preview     |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | (your key)    | Preview     |
| `NEXT_PUBLIC_DB_SCHEMA`         | `test`        | Preview     |

### Production Environment

| Variable                        | Value         | Environment  |
|---------------------------------|---------------|--------------|
| `NEXT_PUBLIC_SUPABASE_URL`      | (your URL)    | Production   |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | (your key)    | Production   |
| `NEXT_PUBLIC_DB_SCHEMA`         | `prod`        | Production   |

### Optional Server-Only Variables

Only add these if your backend explicitly requires them:

| Variable                      | Where to set | Environment |
|------------------------------|--------------|-------------|
| `SUPABASE_SERVICE_ROLE_KEY`  | Vercel env   | Server only |
| `DATABASE_URL`               | Vercel env   | Server only |

Do not expose these values to browser bundles.

> **Why this matters:** When the CI/CD pipeline runs `vercel pull --environment=preview`, it fetches `NEXT_PUBLIC_DB_SCHEMA=test`. When it runs `vercel pull --environment=production`, it fetches `NEXT_PUBLIC_DB_SCHEMA=prod`. This is how we guarantee the correct schema without any manual switches.

---

## Local Development Setup

For local development, create a `.env.local` file in your project root:

```env
NEXT_PUBLIC_SUPABASE_URL=https://xyzabcdef.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
NEXT_PUBLIC_DB_SCHEMA=test
```

If needed for server-only scripts, add:

```env
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIs...
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xyzabcdef.supabase.co:5432/postgres
```

Alternatively, pull from Vercel:

```bash
vercel env pull .env.local
```

> **Never commit `.env.local` to git.** Ensure it is in `.gitignore`.

---

## Checklist for New Projects

- [ ] Vercel CLI installed and logged in
- [ ] Project linked via `vercel link`
- [ ] `VERCEL_ORG_ID` set at organisation level (secret or variable)
- [ ] `VERCEL_TOKEN` and `VERCEL_ORG_ID` set at organisation level
- [ ] `VERCEL_PROJECT_ID_PROD` and `VERCEL_PROJECT_ID_STAGING` added as repo secrets
- [ ] Required variables set in Vercel Dashboard (Preview + Production)
- [ ] Optional server-only variables added only if needed
- [ ] `NEXT_PUBLIC_DB_SCHEMA` set to `test` for Preview, `prod` for Production
- [ ] `.vercel/` and `.env.local` in `.gitignore`
- [ ] Caller workflow files copied and configured (see [Workflow Guide](workflow-guide.md))
