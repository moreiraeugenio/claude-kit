---
description: Set up claude-kit in this project, asking which plugins to enable and installing them. Re-run any time to add or remove plugins.
argument-hint: "[optional plugin names to enable, e.g. ck-infra ck-git]"
---

Set up the claude-kit plugin marketplace (github: moreiraeugenio/claude-kit) for this project, or change which of its plugins are enabled.

## 1. Gather status

1. Refresh the marketplace: `claude plugin marketplace update claude-kit`. If that fails, read the catalog from https://github.com/moreiraeugenio/claude-kit/blob/main/.claude-plugin/marketplace.json instead.
2. Read the catalog (`~/.claude/plugins/marketplaces/claude-kit/.claude-plugin/marketplace.json`, or the GitHub one) and the Plugins table in its README to see what every plugin does.
3. Read `.claude/settings.json` in the project root, if it exists, for `enabledPlugins` entries ending in `@claude-kit`. Plugins were renamed with a `ck-` prefix (`frontend` → `ck-frontend`, `infra` → `ck-infra`, `git` → `ck-git`, `kit` → `ck`). If `.claude/settings.json` still has old entries (`frontend@claude-kit`, `infra@claude-kit`, `git@claude-kit`), replace each with its new name, keep every other setting, and run `claude plugin uninstall <old>@claude-kit --scope project` for the old ones. If `kit@claude-kit` is installed for the user, tell me to run `claude plugin uninstall kit@claude-kit` and `claude plugin install ck@claude-kit`.
4. Look at this project's stack and tooling to work out which plugins fit. Workflow plugins (for example ck-git) fit any project, not only a particular stack.

## 2. Ask which to enable

If I passed plugin names, use those and skip the question: $ARGUMENTS

Otherwise ask with AskUserQuestion, as a multi-select question. Each plugin is one option: the label is the plugin name, and the description is one short line on what it does, prefixed with `enabled ·` if it already is. Add "(Recommended)" to the label of plugins that fit this project or are already enabled, and put them first. The `ck` plugin is installed for the user, so leave it out. The tool allows at most 4 options per question, so if there are more plugins, split them across several questions (up to 4 per call) grouped by area.

The answer is the full set: a plugin enabled before but not picked now gets disabled. If any would be disabled, confirm that with me first.

## 3. Write settings and install

1. Edit `.claude/settings.json` in the project root. Create the file and the `.claude/` folder if they don't exist. If the file already exists, merge these keys in and keep every other setting. If `enabledPlugins` or `extraKnownMarketplaces` already exist, add to them instead of replacing them:
   - `extraKnownMarketplaces.claude-kit` = `{ "source": { "source": "github", "repo": "moreiraeugenio/claude-kit" }, "autoUpdate": true }`
   - `enabledPlugins`: `"<plugin>@claude-kit": true` for each plugin I selected; remove the entries of plugins I deselected.
2. Install each selected plugin that isn't installed for this project yet: `claude plugin install <plugin>@claude-kit --scope project`. For deselected ones, run `claude plugin uninstall <plugin>@claude-kit --scope project`. If a command fails or asks for input, stop running them, and tell me to run `/plugin` after reloading instead.
3. The CLI rewrites `.claude/settings.json` and drops `autoUpdate`: re-read the file and make sure `extraKnownMarketplaces.claude-kit.autoUpdate` is `true` and every other setting is still there.
4. Check that the result is valid JSON, then show me the final file.

## 4. Finish

1. Tell me to run `/reload-plugins` (or restart Claude Code) so the plugins load, and then `/ck:sync` to bring the codebase in line with them.
2. Ask me whether to commit and push `.claude/settings.json`. If the ck-git plugin was just enabled, its workflow applies once it's loaded, so commit with a plain `git commit` and `git push` to the current branch.
