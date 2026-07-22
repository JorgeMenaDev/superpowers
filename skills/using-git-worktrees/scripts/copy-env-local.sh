#!/usr/bin/env bash

set -euo pipefail

source_root="${1:?usage: copy-env-local.sh <primary-checkout> <worktree>}"
target_root="${2:?usage: copy-env-local.sh <primary-checkout> <worktree>}"

source_root="$(cd "$source_root" && git rev-parse --show-toplevel)"
target_root="$(cd "$target_root" && git rev-parse --show-toplevel)"

if [[ "$source_root" == "$target_root" ]]; then
  echo "Source and target must be different checkouts." >&2
  exit 1
fi

source_common="$(cd "$source_root" && cd "$(git rev-parse --git-common-dir)" && pwd -P)"
target_common="$(cd "$target_root" && cd "$(git rev-parse --git-common-dir)" && pwd -P)"

if [[ "$source_common" != "$target_common" ]]; then
  echo "Source and target are not worktrees of the same repository." >&2
  exit 1
fi

copied=0
while IFS= read -r source_file; do
  relative_path="${source_file#"$source_root"/}"
  git -C "$source_root" check-ignore -q "$relative_path" || continue

  target_file="$target_root/$relative_path"
  mkdir -p "$(dirname "$target_file")"
  temp_file="$(mktemp "$(dirname "$target_file")/.env.local.XXXXXX")"
  awk '
    /^[[:space:]]*(CONVEX_DEPLOY_KEY|CONVEX_DEPLOYMENT_TOKEN|CONVEX_DEPLOYMENT|CONVEX_URL|CONVEX_SITE_URL|NEXT_PUBLIC_CONVEX_URL|NEXT_PUBLIC_CONVEX_SITE_URL|EXPO_PUBLIC_CONVEX_URL|EXPO_PUBLIC_CONVEX_SITE_URL|CONVEX_ADMIN_KEY|QA_CONVEX_ADMIN_KEY)[[:space:]]*=/ { next }
    { print }
  ' "$source_file" > "$temp_file"
  chmod 600 "$temp_file"
  mv "$temp_file" "$target_file"
  copied=$((copied + 1))
  printf 'Copied %s (Convex targets and keys stripped)\n' "$relative_path"
done < <(
  find "$source_root" \
    \( -type d \( -name .git -o -name .worktrees -o -name .env.profiles -o -name .vercel -o -name .convex -o -name node_modules -o -name .next -o -name dist -o -name build -o -name coverage \) -prune \) \
    -o -type f -name .env.local -print
)

printf 'Copied %s active .env.local file(s); values were not displayed.\n' "$copied"
