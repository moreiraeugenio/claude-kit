---
description: Review this project against the claude-kit plugins you pick (enabled or not, latest version) and bring it in line.
argument-hint: "[optional plugin names to sync against, e.g. infra git]"
---

Bring this project in line with the claude-kit plugins I choose, using each plugin's latest version.

## 1. Gather status

1. Refresh the marketplace: `claude plugin marketplace update claude-kit`. If that fails (marketplace not added here, offline), read the catalog from https://github.com/moreiraeugenio/claude-kit/blob/main/.claude-plugin/marketplace.json instead.
2. Read the catalog: `.claude-plugin/marketplace.json` in the local marketplace copy (`~/.claude/plugins/marketplaces/claude-kit/`), or the GitHub one. Skip the `kit` plugin itself: it has no rules to sync against.
3. Read `.claude/settings.json` (and `.claude/settings.local.json` if present) for `enabledPlugins` entries ending in `@claude-kit`.
4. Run `claude plugin list --json` and keep the `@claude-kit` entries installed for this project (`projectPath` is this repo, or `scope` is `user`), with their `version`.
5. Look at the project's stack and tooling to work out which plugins fit. Workflow plugins (for example git) fit any project.

For each plugin, work out a status: `enabled · installed <v>` (add `· update to <latest>` when older than the catalog version), `enabled · not installed`, or `not enabled`.

## 2. Ask which to sync against

If I passed plugin names, use those and skip the question: $ARGUMENTS

Otherwise ask with AskUserQuestion, as a multi-select question. Each plugin is one option: the label is the plugin name, the description is its status plus one short line on what it does. Put enabled plugins first, then ones that fit the project, and add "(Recommended)" to the label of every plugin that is enabled or fits. The tool allows at most 4 options per question, so split larger lists across several questions (up to 4 per call) grouped by area.

If I picked plugins that aren't enabled, ask in one more question whether to also enable them in `.claude/settings.json` (so their skills load in future sessions) or only review against them this time. To enable, merge into the file and keep every other setting: add `"<plugin>@claude-kit": true` under `enabledPlugins`, and add `extraKnownMarketplaces.claude-kit` = `{ "source": { "source": "github", "repo": "moreiraeugenio/claude-kit" }, "autoUpdate": true }` if it's missing. Check that the result is valid JSON.

## 3. Read the rules

For each selected plugin, list all of its skills, agents, commands and hooks, and read each one in full (SKILL.md, agent and command files, hook scripts). Read them from the latest version, not the installed copy: the local marketplace copy at `~/.claude/plugins/marketplaces/claude-kit/plugins/<plugin>/`, or https://github.com/moreiraeugenio/claude-kit/tree/main/plugins/<plugin> if that's missing.

## 4. Review, then fix

1. Review the whole project against the rules in each selected plugin. If a rule doesn't apply to this project, skip it and say why. Where a plugin provides an agent built for review or auditing, use that agent for its area. Some plugins cover a workflow rather than code (for example a skill that needs a per-project config file, such as the git plugin's `.claude/git-workflow.json`): run their setup steps and ask me whatever they say to ask.
2. Before changing anything, show me a findings list grouped by plugin and skill/agent. For each finding give the file:line, the rule it breaks, and the fix you propose.
3. Then apply the fixes. Keep changes minimal and match the existing code style. Ask me before any destructive or infra-affecting change, such as deleting files, changing deploy targets, renaming env vars, or a `plan`/`apply` that recreates, resizes or deletes a resource.
4. Run the project's existing lint, typecheck and tests, and report the results.

## 5. Finish

1. Summarise what changed per plugin, and anything you left alone on purpose.
2. If an installed plugin is older than the catalog version, or a plugin was newly enabled, tell me to restart Claude Code (or run `/reload-plugins`), then `/plugin` to install it, or `claude plugin update <plugin>@claude-kit` to update it.
3. Don't commit during the review. At the end, commit and push the way the enabled plugins say (for example the git plugin's workflow). If no plugin covers it, ask me first.
