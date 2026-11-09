---
description: Review the whole project against the latest infra plugin rules (Railway IaC, CLI deploys, Dockerfiles, role-based names) and bring it in line.
argument-hint: "[optional focus, e.g. a folder or a single skill]"
---

Bring this whole project in line with the claude-kit `ck-infra` plugin, using its latest version. Works without the `ck` plugin. To sync against several plugins at once, use `/ck:sync` instead.

## 1. Read the rules

1. Refresh the marketplace: `claude plugin marketplace update claude-kit`. If that fails (marketplace not added here, offline), go on.
2. List all of the plugin's skills, agents, commands and hooks, and read each one in full (SKILL.md, agent and command files, hook scripts), except this `sync` command. Read the latest version: the local marketplace copy at `~/.claude/plugins/marketplaces/claude-kit/plugins/ck-infra/`, or https://github.com/moreiraeugenio/claude-kit/tree/main/plugins/ck-infra if that's missing.
3. Compare the latest `version` (its `.claude-plugin/plugin.json`) with the installed one (`claude plugin list --json`, the `ck-infra@claude-kit` entry for this project or user scope). Check whether `.claude/settings.json` has `"ck-infra@claude-kit": true` under `enabledPlugins`.

## 2. Review, then fix

Focus, if I gave one: $ARGUMENTS

1. Review the whole project (or the focus above) against every rule in the plugin. If a rule doesn't apply to this project, skip it and say why. Where the plugin provides an agent built for review or auditing, use it. Where a skill needs per-project setup (a config file, a question for me), run that setup and ask what it says to ask.
2. Before changing anything, show me a findings list grouped by skill/agent. For each finding give the file:line, the rule it breaks, and the fix you propose. If nothing breaks a rule, say so and stop here.
3. Then apply the fixes. Keep changes minimal and match the existing code style. Ask me before any destructive or infra-affecting change, such as deleting files, changing deploy targets, renaming env vars, or a `plan`/`apply` that recreates, resizes or deletes a resource.
4. Run the project's existing lint, typecheck and tests, and report the results.

## 3. Finish

1. Summarise what changed per skill/agent, and anything you left alone on purpose.
2. If the installed version is older than the latest, tell me to run `claude plugin update ck-infra@claude-kit` and then `/reload-plugins`. If the plugin isn't enabled in `.claude/settings.json`, say so and offer to enable it (or run `/ck:setup`).
3. Don't commit during the review. At the end, commit and push the way the project's git workflow says (the ck-git plugin's `.claude/git-workflow.json`, if present). Otherwise ask me first.
