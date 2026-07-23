---
name: using-git-worktrees
description: Use when creating an isolated Git workspace or running the current default branch locally, especially for Bun monorepos or concurrent local Convex development.
version: 1.1.0
mutating: true
writes_to: ["<repo-name>-worktrees/", "**/.env.local"]
---

# Using Git Worktrees

## Contract

Feature work gets one branch and sibling `<repo-name>-worktrees/<branch-slug>`. A no-edit request to run current `main` gets the reusable detached `<repo-name>-worktrees/local-main`. Every worktree gets isolated environment files, ports, and local state. Readiness requires installed dependencies, non-production targets, live requested surfaces, and no shared runtime state.

Announce: “I’m using the using-git-worktrees skill to create an isolated local runtime.”

## 1. Inspect

Run this preamble from the requested repository and branch only on its emitted state:

```bash
repo_root=$(git rev-parse --show-toplevel)
git_dir=$(cd "$(git rev-parse --git-dir)" && pwd -P)
git_common=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
superproject=$(git rev-parse --show-superproject-working-tree 2>/dev/null || true)
printf 'REPO_ROOT: %s\nIS_LINKED: %s\nIS_SUBMODULE: %s\nBRANCH: %s\n' \
  "$repo_root" "$([ "$git_dir" != "$git_common" ] && echo yes || echo no)" \
  "$([ -n "$superproject" ] && echo yes || echo no)" "$(git branch --show-current)"
```

Read the root instruction file and package scripts. If `IS_LINKED` is `yes` and `IS_SUBMODULE` is `no`, keep an externally managed worktree or move a manual nested worktree to the canonical sibling root before Bootstrap. Otherwise fetch without changing the source checkout.

Choose one mode from the request:

- `FEATURE`: implementation or any tracked edit. Use the user’s base when explicit; otherwise current `origin/main`.
- `LAUNCH_MAIN`: run/preview/QA of current `main` with no tracked edits. Its ignored local database is disposable QA state.

## 2. Prepare

Put manual worktrees beside—not inside—the primary checkout. Fetch `origin/main`, then set:

```bash
git fetch origin main
worktree_root="$(dirname "$repo_root")/$(basename "$repo_root")-worktrees"
mkdir -p "$worktree_root"
```

For `FEATURE`, set a short branch and slug, then run:

```bash
git worktree add "$worktree_root/$slug" -b "$branch" origin/main
```

For `LAUNCH_MAIN`, use `$worktree_root/local-main`. If absent, run `git worktree add --detach "$worktree_root/local-main" origin/main`. If present, require it to be registered to this repository, clean, and to have zero commits in `origin/main..HEAD`; stop only its owned processes, then run `git -C "$worktree_root/local-main" switch --detach origin/main`. A failed runtime is repaired here; creating another worktree is the failure mode this gate prevents.

The source checkout may be dirty. Preserve it: never stash, clean, reset, rebase, copy tracked files from it, or base work on its stale `main`.

## 3. Bootstrap

If the worktree is a Bun monorepo or uses Convex, read [BUN_CONVEX.md](BUN_CONVEX.md) in full and follow it. Otherwise use repository-declared setup. Prefer a generic `setup:worktree`; for `LAUNCH_MAIN`, prefer the repository’s canonical local QA launcher after setup.

Do not run or create unit tests unless the repository owner explicitly requested them. Use the repository’s existing check/build workflow and a live smoke instead.

## 4. Prove readiness

Before implementation, verify all of these:

- the branch and absolute worktree path are correct;
- ignored `.env.local` files needed by the monorepo exist at the same relative paths, without printing values;
- the lockfile is unchanged after dependency installation;
- every Convex selector is `local:*`, every Convex URL is loopback, and database state lives under this worktree;
- every allocated surface and Convex port is listening and owned by this worktree;
- every requested surface responds on its unique URL; and
- `git status --short` contains no accidental environment, dependency, or generated-file changes.

If any item fails, report `BLOCKED` with the exact command and error. Continuing with a shared/cloud database, missing local environment, or colliding port is the failure mode this gate prevents.

## Report

```text
READY | BLOCKED
Mode: FEATURE | LAUNCH_MAIN
Worktree: <absolute path>
Branch/base: <branch> from <sha>
Environment: <N> ignored files copied; values not displayed
Runtime: <surface URLs>; Convex <local name> on <cloud>/<site ports>
Validation: <commands and result>
Friction: <none or exact issue>
```

## Cleanup

Stop only processes whose working directory is this worktree. Keep a clean `local-main` warm for reuse. Remove feature worktrees only when merged, explicitly abandoned, or the POC is preserved. Use `git worktree remove <exact-path>` from the primary checkout; delete a feature branch only when no longer needed.
