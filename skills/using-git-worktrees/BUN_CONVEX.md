# Bun monorepo and local Convex bootstrap

Read the repository instructions first. This contract fills the worktree gap; it does not override project-specific app commands.

## 1. Copy local environment safely

Use the primary checkout as the environment source. Discover exact `.env.local` files while excluding `.git`, `.worktrees`, `node_modules`, build output, and local Convex state. Copy each ignored file to the same relative path in the worktree, creating parent directories. Do not copy `.env.production.local`, deploy keys, `.convex/`, `node_modules/`, caches, or build output. Do not print file contents or values.

If the repository has a runtime-neutral `setup:worktree` command, prefer it and verify the same result. Product- or runtime-specific copy helpers are not canonical.

## 2. Install deterministically

Run `bun install --frozen-lockfile` at the monorepo root. A lockfile change is a bootstrap failure, not something to commit. Use the Bun version declared by `packageManager` when available.

## 3. Allocate an isolated runtime

Derive a runtime ID from the branch slug. Choose one unused app port and one unused consecutive Convex cloud/site pair. Check actual listeners with `lsof`; never assume default ports are free. Export the identity for setup and dev commands:

```bash
export WORKTREE_ID="$slug"
export WORKTREE_APP_PORT=<free-port>
export WORKTREE_CONVEX_CLOUD_PORT=<free-even-port>
export WORKTREE_CONVEX_SITE_PORT=$((WORKTREE_CONVEX_CLOUD_PORT + 1))
```

When Portless is present, use a unique name containing `WORKTREE_ID`; one global Portless proxy may be shared, but its route name and app port may not be shared.

## 4. Create a worktree-local Convex deployment

Run the repository’s local Convex bootstrap when present, passing the runtime identity and allocated ports explicitly. Otherwise run the pinned Convex CLI from the backend package with `--local`, the allocated cloud/site ports, and a worktree-unique local deployment name. Then rewrite every copied Convex selector/URL through the repository’s environment command or the Convex CLI output.

Hard gates:

- `CONVEX_DEPLOYMENT` starts with `local:`;
- public/server Convex URLs use `127.0.0.1` or `localhost` and the allocated ports;
- local state/config is beneath the worktree backend (normally `.convex/local/`);
- no production/dev-cloud deploy key is inherited; and
- a second worktree gets a different deployment name, port pair, and data directory.

Seed only the repository’s documented local baseline. Never import production or shared-dev data. A blank isolated local database is valid; expected QA fixtures should be created by the repository’s canonical local seed command.

## 5. Start and smoke

Start the backend and one requested app with the runtime identity/ports in their environment. Keep logs per worktree. Prove the Convex cloud and site ports are listening, the app URL responds, and the owning processes have this worktree as their working directory. Leave servers running only when the user asked for a usable POC; otherwise stop them after proof.
