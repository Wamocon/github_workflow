# Tips & Best Practices

A collection of practical tips for developers working across our projects.

---

## Git Workflow

### Branch Naming Convention

Use a consistent pattern for all branches:

```
feature/short-description     → New features
fix/short-description         → Bug fixes
hotfix/short-description      → Urgent production fixes
chore/short-description       → Maintenance (deps, config)
refactor/short-description    → Code restructuring
```

**Examples:**
```
feature/user-notifications
fix/order-total-calculation
chore/upgrade-next-15
refactor/auth-middleware
```

### Commit Message Convention

Follow the [Conventional Commits](https://www.conventionalcommits.org/) standard:

```
type(scope): short description

feat(auth): add password reset flow
fix(orders): correct total calculation for discounts
chore(deps): upgrade supabase-js to v2.45
db(migration): create notifications table
ci(workflow): update Node.js version to 20
docs(readme): add deployment instructions
style(lint): auto-fix formatting issues
```

### Pull Request Guidelines

1. **Keep PRs small** — aim for under 400 lines of changes
2. **One concern per PR** — don't mix features with refactors
3. **Write a clear description** — what changed and why
4. **Link to the issue/task** — reference the ticket number
5. **Add screenshots** for UI changes
6. **Self-review before requesting** — read your own diff first

---

## Code Quality

### TypeScript

- **Always use strict mode** — `strict: true` in `tsconfig.json`
- **Avoid `any`** — use `unknown` and narrow the type
- **Use Zod for runtime validation** at API boundaries
- **Prefer interfaces over types** for object shapes (they give better error messages)
- **Export types from a central file** per feature (`types.ts`)

### Next.js

- **Use Server Components by default** — only add `"use client"` when you need interactivity
- **Keep Server Actions in separate files** — (`actions.ts` in the feature folder)
- **Use `loading.tsx` and `error.tsx`** for every route segment
- **Validate all form inputs** on both client and server
- **Use `revalidatePath` / `revalidateTag`** instead of manual cache busting

### Supabase Client

- **Use `createServerClient`** in Server Components and Server Actions
- **Use `createBrowserClient`** only in Client Components
- **Always check for errors** from Supabase:

```typescript
const { data, error } = await supabase.from('users').select('*');
if (error) throw error;
```

- **Use typed queries** with generated types:

```typescript
import { Database } from '@/types/supabase';
const supabase = createServerClient<Database>(...);
```

---

## Environment & Tooling

### Required Global Tools

Every developer should have these installed:

```bash
# Node.js (via nvm recommended)
nvm install 20
nvm use 20

# npm (bundled with Node.js)
# verify npm is available
npm -v

# Vercel CLI
npm install -g vercel

# Supabase CLI
npm install -g supabase
```

### VS Code Extensions (Recommended)

| Extension                     | Purpose                           |
|-------------------------------|-----------------------------------|
| GitHub Copilot                | AI code assistance                |
| GitHub Copilot Chat           | AI chat interface                 |
| ESLint                        | Linting                           |
| Prettier                      | Code formatting                   |
| Tailwind CSS IntelliSense     | Tailwind autocomplete             |
| Error Lens                    | Inline error display              |
| GitLens                       | Git blame & history               |
| Supabase                      | Supabase integration              |

### VS Code Settings (Recommended)

Add these to your workspace `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "files.exclude": {
    "**/.next": true,
    "**/node_modules": true
  }
}
```

---

## Performance Tips

### Database Queries

- **Select only the columns you need** — avoid `select('*')` in production code
- **Add indexes** for columns used in `WHERE`, `ORDER BY`, and `JOIN` clauses
- **Use pagination** — never fetch unbounded lists
- **Use database views** for complex queries that are reused frequently

### Next.js

- **Use `next/image`** for all images — automatic optimisation
- **Use `next/font`** for fonts — no layout shift
- **Lazy-load heavy components** with `dynamic()` and `{ ssr: false }`
- **Use `Suspense` boundaries** for streaming
- **Check bundle size** with `next build` — look for unexpectedly large chunks

---

## Security Checklist

- [ ] All tables have **Row Level Security (RLS)** enabled
- [ ] API routes validate input with **Zod schemas**
- [ ] No secrets in client-side code (`NEXT_PUBLIC_` prefix means public)
- [ ] `SUPABASE_SERVICE_ROLE_KEY` is **never** exposed to the browser
- [ ] All SQL uses **parameterised queries** (Supabase client handles this)
- [ ] CORS is configured correctly for your domains
- [ ] Auth tokens are stored in **httpOnly cookies**, not localStorage

---

## Debugging Tips

### CI Pipeline Failures

1. Go to **GitHub → Actions tab → Failed run**
2. Click the failed job step to see the exact error
3. Common fixes:
  - **Type errors** → Run `npm run tsc -- --noEmit` locally to reproduce
  - **Lint errors** → Run `npm run eslint -- .` locally, or let the auto-fixer handle it
  - **Missing dependencies** → Check that `package-lock.json` is committed
   - **Vercel deploy fails** → Verify secrets are set and `vercel link` was done

### Local Development Issues

| Issue                          | Quick Fix                                        |
|--------------------------------|--------------------------------------------------|
| `Module not found`             | `npm install` then restart the dev server        |
| Stale data after migration     | Restart the dev server to pick up schema changes |
| TypeScript errors in IDE       | Restart TS server: `Ctrl+Shift+P` → "Restart TS Server" |
| `.env` changes not picked up   | Restart `next dev`                               |
| Port already in use            | `npx kill-port 3000`                             |

### Supabase Issues

| Issue                          | Quick Fix                                        |
|--------------------------------|--------------------------------------------------|
| RLS blocking queries           | Check policies and `auth.uid()` matches          |
| Migration won't apply          | Run `supabase migration list` to check status    |
| Connection timeout             | Check Supabase project isn't paused              |

---

## Quick Reference Commands

```bash
# Start development
npm run dev

# Type check
npm run tsc -- --noEmit

# Lint
npm run eslint -- .

# Lint with auto-fix
npm run eslint -- . --fix

# Format
npm run prettier -- --write .

# Create a migration
npx supabase migration new <name>

# Apply migrations
npx supabase db push

# Link Vercel project
vercel link

# Pull Vercel env
vercel env pull .env.local

# Deploy preview
vercel deploy

# Deploy production
vercel deploy --prod
```
