#!/usr/bin/env bash
# Stop hook: when the turn ends with uncommitted or unpushed work, make Claude
# ask the user whether to commit and push. Asks once per distinct repo state,
# so declining doesn't re-trigger until something changes again.

input=$(cat)

# Already continuing because of this hook: let Claude stop.
if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
git_dir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
root=$(git rev-parse --show-toplevel)

status=$(git status --porcelain 2>/dev/null)
unpushed=""
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  unpushed=$(git rev-list '@{u}..HEAD' 2>/dev/null)
fi

[ -z "$status" ] && [ -z "$unpushed" ] && exit 0

# Fingerprint the current state: status, tracked diff, untracked file contents
# and unpushed commits.
fingerprint=$( {
  printf '%s\n' "$status" "$unpushed"
  git diff HEAD 2>/dev/null
  (cd "$root" && git ls-files -o --exclude-standard -z | xargs -0 git hash-object 2>/dev/null)
} | git hash-object --stdin)
marker="$git_dir/claude-kit-commit-asked"
if [ -f "$marker" ] && [ "$(cat "$marker")" = "$fingerprint" ]; then
  exit 0
fi
printf '%s' "$fingerprint" > "$marker"

if [ -f "$root/.claude/git-workflow.json" ]; then
  setup=""
else
  setup=" This project has no .claude/git-workflow.json yet, so run the setup step of the skill first (ask solo or team, save the file)."
fi

reason="There are uncommitted or unpushed changes. Follow the ck-git:commit-push skill: ask the user with AskUserQuestion whether to commit and push now.${setup} If they decline, stop without committing."

printf '{"decision":"block","reason":"%s"}\n' "$reason"
