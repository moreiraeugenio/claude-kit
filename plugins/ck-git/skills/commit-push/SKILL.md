---
name: commit-push
description: "Use for ANY git commit, push, branch or PR work, whenever the user says commit/push/ship it, and whenever a change is finished and uncommitted or unpushed. Reads the project's .claude/git-workflow.json (solo or team) and asks once to create it if missing."
---

# Commit and push: solo or team, saved per project

Every project has a git workflow saved in `.claude/git-workflow.json` at the repo root. Read it before any commit, push, branch or PR. Apply it even if the user did not mention it.

## 1. Setup (only when the file is missing)

Ask once with AskUserQuestion, then never again for this project:

1. **"Is this a solo project or a team project?"**
   - `Solo`: only you work on it.
   - `Team`: you and other people work on it.
2. **Team only:** "How should commits and pushes work in this project?"
   - `Main directly`: commit and push to the default branch, like solo.
   - `Branch + PR`: a feature branch per change, pushed, with a pull request opened.
   - `Branch, no PR`: a feature branch per change, pushed, without opening a PR.
   - The user can also pick "Other" and describe their own rules.

Write the answer to `.claude/git-workflow.json`, then include that file in the next commit so every machine and teammate shares it:

```json
{ "mode": "solo" }
```

```json
{ "mode": "team", "workflow": "main" }
```

`workflow` is `main`, `branch-pr`, `branch`, or `custom`. For `custom`, add a `"notes"` field with the user's rules written out in full.

## 2. The rules

**Solo, and team with `workflow: main`:**
- Commit and push straight to the default branch (`main`, or `master` if that's the repo's default). Never create a branch, worktree or PR unless the user explicitly asks for one in this conversation.
- If HEAD is on another branch and the user didn't ask for it, say so and ask before committing there.

**Team with `branch-pr` or `branch`:**
- Never commit to the default branch. Create a short, descriptive branch from an up-to-date default branch (`git pull --rebase` first). Reuse the current feature branch while the work continues on the same change.
- Push with `-u`. For `branch-pr`, open the PR with `gh pr create` and give the user the link.

**Team with `custom`:** follow `notes`. If they don't cover a case, ask.

**Always, any mode:**
- Never force-push, rewrite pushed history, skip hooks (`--no-verify`) or amend a pushed commit, unless the user explicitly asks.
- If a push is rejected, `git pull --rebase` and push again. If the rebase conflicts, stop and ask.
- Stage only the files that belong to the change. Never commit secrets or `.env` files.
- Write commit messages in the style of `git log` (subject line, imperative, then a body if useful).

## 3. Ask after every change

When a task leaves uncommitted or unpushed changes, end the turn by asking with AskUserQuestion, not in plain text:

- **"Commit and push these changes?"** with a one-line summary of what changed and where it goes (e.g. "to main", or "branch `fix-login` + PR").
- Options: `Commit and push` (recommended), `Commit only`, `Not now`.

Then do exactly what was picked. On `Not now`, leave everything as it is and don't ask again for the same changes. If the user already said "commit and push" for this change, don't ask, just do it.

The plugin's Stop hook reminds Claude about this when a turn ends with uncommitted or unpushed work, and stays quiet until the repo state changes again.
