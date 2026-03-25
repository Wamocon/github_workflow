# GitHub Copilot Guide

A practical guide for getting the most out of GitHub Copilot in your daily development workflow.

---

## Getting Started

### Installation

1. Ensure you have a **GitHub Copilot license** (individual or through the organisation)
2. Install the **GitHub Copilot** extension in VS Code
3. Install the **GitHub Copilot Chat** extension in VS Code
4. Sign in with your GitHub account when prompted

### Verification

After installation, you should see:
- The Copilot icon in the VS Code status bar (bottom right)
- Inline ghost-text suggestions as you type
- The Copilot Chat panel accessible via the sidebar or `Ctrl+Shift+I`

---

## Core Features

### 1. Inline Code Completion

Copilot suggests code as you type. Suggestions appear as grey ghost text.

| Action                    | Shortcut          |
|--------------------------|-------------------|
| Accept suggestion         | `Tab`             |
| Dismiss suggestion        | `Esc`             |
| Next suggestion           | `Alt + ]`         |
| Previous suggestion       | `Alt + [`         |
| Trigger suggestion        | `Alt + \`         |
| Accept next word only     | `Ctrl + →`        |

**Tips for better inline suggestions:**
- Write a clear comment before the code you want generated
- Use descriptive variable and function names
- Keep the relevant context open in adjacent tabs — Copilot reads open files

### 2. Copilot Chat (Side Panel)

Open with `Ctrl+Shift+I` or click the chat icon in the sidebar.

Use it for:
- Asking questions about your code
- Generating boilerplate code
- Explaining unfamiliar code
- Debugging errors
- Refactoring suggestions

### 3. Inline Chat

Trigger with `Ctrl+I` while your cursor is in the editor. This opens a small chat input directly in your code.

Use it for targeted edits:
- "Add error handling to this function"
- "Convert this to an async function"
- "Add TypeScript types to these parameters"

### 4. Chat Participants

Type `@` in the chat to access specialised participants:

| Participant      | What It Does                                    |
|------------------|-------------------------------------------------|
| `@workspace`     | Searches your entire workspace for context      |
| `@vscode`        | Answers questions about VS Code settings & APIs |
| `@terminal`      | Helps with terminal commands and errors         |

### 5. Slash Commands

Type `/` in chat for quick actions:

| Command       | Purpose                                      |
|---------------|----------------------------------------------|
| `/explain`    | Explain the selected code                    |
| `/fix`        | Fix the selected code                        |
| `/tests`      | Generate tests for the selected code         |
| `/doc`        | Generate documentation for the selected code |
| `/new`        | Scaffold a new project or file               |
| `/clear`      | Clear the chat history                       |

---

## Effective Prompting

### Mandatory Prompt Suffix for Database Tasks

When your task is connected to database work, append this instruction at the end of your prompt:

```text
Use MCP and database <project-ref-or-db-name>. Before final answer, verify linting, formatting, type checks, and build.
```

This avoids mixing databases and forces Copilot to include quality checks in every DB-related response.

### Be Specific

```
❌ "Make a component"
✅ "Create a React Server Component that fetches a user profile from Supabase
   using the test schema and displays the name, email, and avatar"
```

### Provide Context

```
❌ "Write a query"
✅ "Write a Supabase query to get all orders with status 'pending'
   from the test.orders table, joined with test.users on user_id,
   ordered by created_at descending, limited to 20 results"
```

### Use Step-by-Step Instructions

```
✅ "Create a Next.js API route that:
   1. Accepts a POST request with { email, password }
   2. Validates the input
   3. Calls Supabase auth.signUp()
   4. Returns the user object or error
   5. Handles rate limiting"
```

### Reference Files

```
✅ "Look at the UserProfile component in @workspace and create a similar
   component for displaying order details"
```

---

## Copilot for Common Tasks

### Generating Supabase Queries

```typescript
// Ask Copilot: "Generate a typed Supabase query for fetching user orders"
const { data, error } = await supabase
  .from('orders')
  .select(`
    id,
    status,
    total,
    created_at,
    users (
      full_name,
      email
    )
  `)
  .eq('user_id', userId)
  .order('created_at', { ascending: false });
```

### Generating Migration SQL

Ask in chat:
> "Generate a Supabase migration SQL to create a `products` table in the test schema with columns: id (UUID), name (TEXT), price (DECIMAL), category (TEXT), created_at (TIMESTAMPTZ). Include RLS policies."

### Writing Server Actions

Ask in chat:
> "Create a Next.js Server Action to update a user's profile. Use the Supabase client from @/lib/supabase/server. Accept name and avatar_url as inputs."

### Generating Tests

Select a function → `Ctrl+I` → type `/tests`

Or in chat:
> "Generate unit tests for the `calculateOrderTotal` function using Vitest"

---

## Copilot in the Terminal

Copilot can help with terminal commands too:

1. Open the terminal
2. Press `Ctrl+I` to open inline chat in the terminal
3. Describe what you want:
   - "List all files modified in the last commit"
   - "Find all TypeScript files importing from Supabase"
   - "Run the migration and show the output"

---

## Copilot Edits (Multi-File)

For changes spanning multiple files:

1. Open Copilot Chat
2. Click the **Edits** mode (pencil icon) or use `Ctrl+Shift+I`
3. Add the relevant files to the working set
4. Describe the change:
   > "Add a `phone` field to the User type, update the profile form component, and create a migration for the new column"

Copilot will propose edits across all the files simultaneously.

---

## Organisation-Specific Tips

### Using with Our Workflow

1. **Before writing a migration**, ask Copilot to review your SQL:
   > "Review this migration SQL for correctness and suggest improvements"

2. **Before opening a PR**, ask Copilot to check your code:
   > "Review this file for TypeScript errors, unused imports, and potential bugs"

3. **When CI fails**, paste the error in chat:
   > "This ESLint error appeared in CI: [paste error]. How do I fix it?"

4. **For new features**, start with Copilot:
   > "I need to add a feature for user notifications. Given our Next.js + Supabase stack, what's the best approach?"

### Using with MCP

When you have MCP configured (see [MCP Setup](mcp-setup.md)), Copilot has direct access to your database schema. This means:

- It knows your exact table names and column types
- Generated queries will use correct column names
- It can suggest proper TypeScript types matching your schema

### Prompt Templates for DB Work

Use these templates directly:

```text
Use MCP and database <project-ref>.
Create SQL for <task> and update repository schema files.
Before final answer, verify linting, formatting, type checks, and build.
```

```text
Use MCP and database <project-ref>.
Generate Next.js server code for <task> based on existing schema.
Before final answer, verify linting, formatting, type checks, and build.
```

---

## Keyboard Shortcuts Summary

| Action                          | Shortcut             |
|---------------------------------|----------------------|
| Accept inline suggestion        | `Tab`                |
| Dismiss suggestion              | `Esc`                |
| Next / Previous suggestion      | `Alt + ]` / `Alt + [` |
| Trigger suggestion manually     | `Alt + \`            |
| Open Copilot Chat               | `Ctrl + Shift + I`   |
| Inline Chat (in editor)         | `Ctrl + I`           |
| Inline Chat (in terminal)       | `Ctrl + I`           |
| Accept next word                | `Ctrl + →`           |

---

## Privacy & Security

- **Do not paste secrets** (API keys, tokens, passwords) into Copilot Chat
- **Review all generated code** before committing — Copilot can make mistakes
- **Copilot reads open files** for context — close sensitive files if needed
- **Code is processed by GitHub** — ensure your organisation's Copilot policy allows this
