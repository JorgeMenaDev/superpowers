---
name: using-git-worktrees
description: Use when creating an isolated Git workspace, especially for Bun monorepos or concurrent local Convex development.
mutating: true
writes_to: [.worktrees/, .gitignore, "**/.env.local"]
---

# Using Git Worktrees

## Contract

One feature gets one branch, one project-local `.worktrees/<branch-slug>` directory, one copied set of ignored local environment files, and one isolated runtime identity. The worktree is ready only when dependencies are installed, every local target is non-production, and its app plus local database can run without sharing ports or state with another worktree.

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

Read the root instruction file and package scripts. If `IS_LINKED` is `yes` and `IS_SUBMODULE` is `no`, keep the current worktree and continue at Bootstrap. Otherwise fetch the remote without changing the source checkout. Use the user’s base when explicit; otherwise create from current `origin/main`.

## 2. Create

Set a short branch name and filesystem-safe slug. Use `.worktrees/<slug>` under the primary checkout. Verify `.worktrees/` is ignored with `git check-ignore -q .worktrees`; if not, add it to the repository’s `.gitignore` through the repository’s normal change process before creating the worktree. Never put a worktree inside another linked worktree.

```bash
git fetch origin main
git worktree add ".worktrees/$slug" -b "$branch" origin/main
```

The source checkout may be dirty; do not stash, clean, reset, rebase, copy tracked files from it, or base the new branch on its stale `main`.

## 3. Bootstrap

If the worktree is a Bun monorepo or uses Convex, read [BUN_CONVEX.md](BUN_CONVEX.md) in full and follow it. Otherwise use the package manager and setup commands declared by the repository. Prefer a repo’s generic `setup:worktree` script when present, but the skill remains the owner of readiness and verifies its effects.

Do not run or create unit tests unless the repository owner explicitly requested them. Use the repository’s existing check/build workflow and a live smoke instead.

## 4. Prove readiness

Before implementation, verify all of these:

- the branch and absolute worktree path are correct;
- ignored `.env.local` files needed by the monorepo exist at the same relative paths, without printing values;
- the lockfile is unchanged after dependency installation;
- every Convex selector is `local:*`, every Convex URL is loopback, and database state lives under this worktree;
- allocated app and Convex ports are listening and do not belong to another worktree;
- the app responds on its unique URL; and
- `git status --short` contains no accidental environment, dependency, or generated-file changes.

If any item fails, report `BLOCKED` with the exact command and error. Continuing with a shared/cloud database, missing local environment, or colliding port is the failure mode this gate prevents.

## Report

```text
READY | BLOCKED
Worktree: <absolute path>
Branch/base: <branch> from <sha>
Environment: <N> ignored files copied; values not displayed
Runtime: app <url>; Convex <local name> on <cloud>/<site ports>
Validation: <commands and result>
Friction: <none or exact issue>
```

## Cleanup

Stop only processes whose working directory is this worktree. Remove the worktree only when its branch is merged, abandoned by explicit instruction, or the POC is complete and its findings are preserved. Use `git worktree remove <exact-path>` from the primary checkout; delete the branch only when its work is no longer needed.
