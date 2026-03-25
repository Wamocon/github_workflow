# Database Setup, MCP, and Schema Management

This document defines the organisation process for setting up Supabase, enabling MCP globally, and creating schemas using GitHub Copilot with the schema file stored in the repository.

---

## 1. Create Supabase Project Manually

1. Open Supabase dashboard: https://supabase.com/dashboard
2. Click **New project**
3. Select organisation
4. Set project name (use the same name as the GitHub repository)
5. Set database password and region
6. Create the project and wait until status is healthy

After creation, open:
- **Project Settings -> API** for API keys and URL
- **Project Settings -> Database** for connection details

---

## 2. Collect Required Secrets

From Supabase dashboard, collect:

| Secret / Variable | Source in Supabase | Required |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Project Settings -> API -> Project URL | Yes |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Project Settings -> API -> anon public key | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Project Settings -> API -> service_role key | Optional (server-only tasks) |
| `DATABASE_URL` | Project Settings -> Database -> Connection string | Optional (raw SQL tooling) |
| `PROJECT_REF` | Project URL fragment | Yes (for MCP setup) |

Notes:
- `SUPABASE_SERVICE_ROLE_KEY` must never be exposed to browser code.
- If the project only uses client-side Supabase calls and MCP for schema work, `SUPABASE_SERVICE_ROLE_KEY` and `DATABASE_URL` can stay unset.

---

## 3. Setup Supabase MCP Globally

Use global MCP setup so every repository can access Supabase context.

### VS Code Global MCP Example

Add this in user settings or global MCP config:

```json
{
  "mcp": {
    "servers": {
      "supabase": {
        "command": "npx",
        "args": [
          "-y",
          "@supabase/mcp-server-supabase@latest",
          "--read-only",
          "--project-ref",
          "your-project-ref"
        ],
        "env": {
          "SUPABASE_ACCESS_TOKEN": "your-supabase-access-token"
        }
      }
    }
  }
}
```

### Verify MCP Connection

In Copilot Chat, ask:

```text
Use MCP for database <project-ref>. List all schemas and tables.
```

If MCP is connected, the response will include real schemas/tables from Supabase.

---

## 4. Schema Workflow with GitHub Copilot

Do schema work through repository files so changes remain version controlled.

### Required Repo Files

Keep schema SQL in repository, for example:

```
database/
  schemas/
    001_base.sql
    002_feature_orders.sql
```

You can choose a different folder name, but keep SQL files committed in git.

### Copilot Prompt Pattern

Use prompts like:

```text
Use MCP for database <project-ref>.
Create/update database/schemas/001_base.sql to define test and prod schemas,
required tables, indexes, and grants. Then provide the SQL commands needed to apply it safely.
After generating, verify linting, formatting, type checks, and build-impact assumptions.
```

### Apply to Supabase

After Copilot updates SQL files, apply changes with your SQL execution method (Supabase SQL editor or CLI) and commit the SQL file.

If your Copilot/agent setup has Supabase execution tools enabled, ask it to do both in one flow:
1. Update SQL files in the repository
2. Execute the schema SQL against Supabase
3. Return execution output for verification

---

## 5. Create test/prod Schemas and Grants

Use this baseline SQL to ensure both schemas exist and are accessible.

```sql
CREATE SCHEMA IF NOT EXISTS test;
CREATE SCHEMA IF NOT EXISTS prod;

GRANT USAGE ON SCHEMA test TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA prod TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA test
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA prod
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
```

Add table-level grants/policies as required by your security model.

---

## 6. Set Search Path / Explicit Schema Usage

Recommended application behavior:
- Always query with explicit schema (for example `test.users` / `prod.users`) where possible.
- Use `NEXT_PUBLIC_DB_SCHEMA` to choose runtime schema in app code.

Optional database-level setting:

```sql
ALTER ROLE authenticator SET search_path = public, test, prod;
```

Use this only if your team intentionally relies on implicit schema resolution.

---

## 7. Connection Validation Checklist

- [ ] Supabase project created and healthy
- [ ] URL and keys copied from Project Settings -> API
- [ ] MCP configured globally with correct `project-ref`
- [ ] Copilot MCP prompt returns real schemas/tables
- [ ] SQL schema file exists in repository and committed
- [ ] `test` and `prod` schemas created
- [ ] Schema usage grants applied
- [ ] Application reads `NEXT_PUBLIC_DB_SCHEMA`
