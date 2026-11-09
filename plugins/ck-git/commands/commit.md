---
description: Commit and push everything that's changed in the repo, including edits made by hand, following this project's git workflow.
argument-hint: "[optional note about the change or commit message]"
---

Commit and push the current changes in this repository, following the ck-git:commit-push skill and the project's `.claude/git-workflow.json`.

Running this command is the user's go-ahead: don't ask whether to commit and push, just do it.

1. If `.claude/git-workflow.json` is missing, run the skill's setup step first (ask solo or team, save the file, include it in this commit).
2. Run `git status` and `git diff HEAD` (plus untracked files) to see everything that changed. Assume the user may have made these changes by hand outside this conversation: read the diff to understand them rather than relying on memory.
3. Stage the changes that belong in the commit. Leave out secrets, `.env` files and obvious junk (build output, editor/OS files) and tell the user what you skipped. If the changes are clearly unrelated to each other, split them into separate commits.
4. Write the commit message from the diff in the style of `git log`. If the user passed a note, use it: $ARGUMENTS
5. Commit and push where the workflow says (default branch for solo / `main`, a feature branch and PR for `branch-pr`, and so on), with the skill's rules on rejected pushes, force-pushing and hooks.
6. If there's nothing to commit but there are unpushed commits, just push them. If there's nothing at all, say so.

Finish with one line: the commit(s) made and where they were pushed (and the PR link, if one was opened).
