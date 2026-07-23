# Bun monorepo and local Convex bootstrap

Read the repository instructions first. This contract fills the worktree gap; it does not override project-specific app commands.

## 1. Copy local environment safely

Use the primary checkout as the environment source. On first creation or when files are missing, run this skill's `scripts/copy-env-local.sh <primary-checkout> <worktree>` helper. It copies ignored files named exactly `.env.local` to the same relative paths while excluding environment profiles, provider state, prior worktrees, dependencies, caches, build output, and local Convex state. It also strips Convex selectors, URLs, deploy keys, and admin keys so local bootstrap starts fail-closed. Do not overwrite a warm launch worktree's configured local targets merely to refresh it. Do not print file contents or values.

If the repository has a runtime-neutral `setup:worktree` command, prefer it and verify the same result. Product- or runtime-specific copy helpers are not canonical.

## 2. Install deterministically

Run `bun install --frozen-lockfile` at the monorepo root. A lockfile change is a bootstrap failure, not something to commit. Use the Bun version declared by `packageManager` when available.

## 3. Allocate an isolated runtime

Derive a runtime ID from the branch slug (`local-main` for the launch fast path). Reserve one unused contiguous app-port block large enough for every requested surface and one unused consecutive Convex cloud/site pair. The repository assigns surface ports from `WORKTREE_APP_PORT` in its declared surface order. Check every listener with `lsof`; never assume defaults are free. Export:

```bash
export WORKTREE_ID="$slug"
export WORKTREE_APP_PORT=<free-port>
export WORKTREE_CONVEX_CLOUD_PORT=<free-even-port>
export WORKTREE_CONVEX_SITE_PORT=$((WORKTREE_CONVEX_CLOUD_PORT + 1))
```

When Portless is present, prefer its automatic Git-branch prefix with a stable product-surface name, then use the exact URL it emits. If the repository disables automatic branch namespacing, include `WORKTREE_ID` in the name explicitly. Pass a fixed child port through `PORTLESS_APP_PORT` (not `PORT`) when the wrapper supports it. One global Portless proxy may be shared, but the effective route and app port may not be shared.

## 4. Create a worktree-local Convex deployment

Run the repository’s local Convex bootstrap when present, passing the runtime identity and allocated ports explicitly. Otherwise inspect the pinned CLI's `deployment` and `dev` help, create/select a fresh local deployment, then start it with the allocated cloud/site ports. Convex CLI versions differ: do not assume a `--local` or instance-name flag exists. Then write every required Convex selector/URL through the repository’s environment command or the CLI output.

If the repository tracks Convex generated declarations, inspect `convex dev --help` for a codegen-disable option. Use it for the long-running worktree backend when available (`--codegen=disable` in recent CLIs), after bootstrap has established that the committed declarations are current. Run codegen deliberately when a schema/API change needs new tracked output; do not let an idle local backend keep rewriting generated files. Restore bootstrap-only churn and confirm `git status --short` stays clean while the backend remains live.

Hard gates:

- `CONVEX_DEPLOYMENT` starts with `local:`;
- public/server Convex URLs use `127.0.0.1` or `localhost` and the allocated ports;
- local state/config is beneath the worktree backend (normally `.convex/local/`);
- no production/dev-cloud deploy key is inherited; and
- a second worktree gets a different deployment name, port pair, and data directory.

Seed only the repository’s documented local baseline. Never import production or shared-dev data. A blank isolated local database is valid; expected QA fixtures should be created by the repository’s canonical local seed command.

## 5. Start and smoke

Run `bun run setup:worktree` when declared. For authenticated local QA, run the repository's canonical launcher (normally `bun run qa:local -- [--surface <key>]...`); it must fail before browser startup when the effective credential is invalid, start the backend plus requested surfaces, and emit stable local login URLs.

Keep logs per worktree. Prove every allocated port is listening, every requested URL responds, and each process has this worktree as its working directory. Verify authentication in a fresh signed-out browser context: an existing session can select the wrong actor even when the database is isolated. Repair credential, seed, browser-session, or runtime failures in the same worktree. If a warm launch exceeds five minutes, report the timed phase causing the delay. Leave servers running only when the user asked for a usable POC; otherwise stop them after proof.
