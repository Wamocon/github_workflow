# Model Context Protocol (MCP) Setup for Supabase

This guide explains how to configure AI coding assistants (GitHub Copilot, Claude Desktop, Cursor, etc.) to use the Supabase MCP server. This gives the AI full awareness of your database schema, preventing hallucinated table/column names when generating SQL or Next.js code.

---

## What Is MCP?

The **Model Context Protocol** is an open standard that lets AI tools securely connect to external data sources and tools. When connected to your Supabase database, the AI can:

- Read your exact table structures, column names, and types
- Generate accurate SQL queries
- Scaffold Next.js API routes / Server Actions that match your schema
- Suggest correct Supabase client queries (`supabase.from('users').select(...)`)

---

## Prerequisites

- A Supabase project with tables already created (via [migrations](database-schema-migrations.md))
- Your Postgres connection string (from Supabase Dashboard → Settings → Database → Connection string)
- An AI tool that supports MCP (VS Code with GitHub Copilot, Claude Desktop, Cursor, Windsurf, etc.)

---

## Getting Your Connection String

1. Go to **Supabase Dashboard → Your Project → Settings → Database**
2. Copy the **Connection string (URI)** format:

```
postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
```

> **Security Warning:** Never commit this connection string to Git or share it publicly. Store it securely.

---

## Setup for VS Code (GitHub Copilot)

### Option A: Workspace MCP Settings

Create or edit `.vscode/mcp.json` in your project root:

```json
{
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
```

> **Note:** Use `--read-only` to prevent the AI from making writes. This is the recommended default for safety.

### Option B: User-Level MCP Settings

To make this available across all your projects, add it to your VS Code User Settings (`settings.json`):

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

---

## Setup for Claude Desktop

Edit the Claude Desktop configuration file:

- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
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
```

Restart Claude Desktop after saving the configuration.

---

## Setup for Cursor

1. Open Cursor Settings → **MCP**
2. Click **Add new MCP server**
3. Configure:
   - **Name:** `supabase`
   - **Type:** `command`
   - **Command:** `npx -y @supabase/mcp-server-supabase@latest --read-only --project-ref your-project-ref`
4. Add environment variable:
   - `SUPABASE_ACCESS_TOKEN` = your token

---

## Getting Your Supabase Access Token

1. Go to **Supabase Dashboard → Account → Access Tokens** (https://supabase.com/dashboard/account/tokens)
2. Click **Generate new token**
3. Give it a descriptive name (e.g., `MCP - Local Dev`)
4. Copy the token immediately (it won't be shown again)

---

## Verifying the Connection

After configuring MCP, test it by asking the AI:

> "List all the tables in my database"

or

> "What are the columns in the users table?"

The AI should return accurate schema information from your actual database, not guessed structures.

---

## What the AI Can Do with MCP

| Capability                        | Example Prompt                                           |
|----------------------------------|----------------------------------------------------------|
| List tables                      | "What tables exist in the test schema?"                  |
| Describe a table                 | "Show me the columns and types of the orders table"      |
| Generate SQL                     | "Write a query to get all pending orders with user info" |
| Generate Supabase client code    | "Create a server action to fetch user profile by ID"     |
| Suggest migrations               | "Generate a migration to add a phone column to users"    |
| Write RLS policies               | "Create an RLS policy so users can only see their data"  |

---

## Security Best Practices

1. **Always use `--read-only`** mode unless you specifically need write access
2. **Never share your access token** — each developer should generate their own
3. **Use the `test` schema** for AI-assisted development, not `prod`
4. **Review all AI-generated SQL** before running it against any database
5. **Rotate tokens periodically** — delete old tokens from the Supabase dashboard
6. **Do not commit MCP config with tokens** — use environment variables or keep tokens in user-level settings only

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Connection refused" | Verify the connection string is correct and your IP is allowed in Supabase network settings |
| AI returns wrong schema | Ensure the MCP server is connecting to the correct project ref |
| MCP server not starting | Run `npx @supabase/mcp-server-supabase@latest --help` to verify it's installed correctly |
| Token expired | Generate a new access token from the Supabase dashboard |
| AI doesn't see recent tables | Restart the MCP server (restart VS Code / Claude Desktop) to refresh the schema cache |
