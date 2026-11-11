# claude-kit

My reusable Claude Code skills, agents and commands, packaged as a [plugin marketplace](https://code.claude.com/docs/en/plugins/marketplace-reference). Each project opts in through its own committed `.claude/settings.json`, so nothing but the small `ck` tooling plugin is installed globally, and it works on any machine or account that clones the project.

## Plugins

| Plugin | What it does |
|---|---|
| `ck-frontend` | Clickable elements look and act clickable: real links and buttons, pointer cursor, hover and focus states, in any stack. `/ck-frontend:sync` reviews the whole project against it and fixes it. |
| `ck-infra` | Railway: IaC in `.railway/` with one TypeScript file per service and its own `package.json` (`plan`, `apply`, `deploy:<service>` scripts), no `railway.json`, the Railway project named exactly like the git repo (`contention` → `contention`, never a random generated name), deploys via `railway up` (never a linked GitHub repo), every service and database built from a Dockerfile (no templates), role-based names like `database` / `database-data`, every service, volume and bucket in `us-east4-eqdc4a` (US East, the region closest to Brazil), memory and volume sizes in whole GB so the dashboard shows them as set. `/ck-infra:sync` reviews the whole project against it and fixes it. |
| `ck-git` | Commits and pushes: asks once per project whether it's solo or team (saved in a committed `.claude/git-workflow.json`). Solo commits and pushes straight to main, never branching unless asked; team uses the workflow picked at setup. Claude asks to commit and push after every change (Stop hook). `/ck-git:commit` commits and pushes everything on demand, including changes you made by hand. `/ck-git:sync` reviews the project's git setup against it. |
| `ck` | Installed once per machine (user scope), not per project. `/ck:setup` asks which plugins to enable in the current project, then writes `.claude/settings.json` and installs them. `/ck:sync` asks which plugins to sync against (enabled or not) and shows each one's status (installed version vs latest). Then it reviews the project against their latest rules, shows the findings and fixes them. Pass names to skip the question: `/ck:setup ck-infra ck-git`, `/ck:sync ck-infra`. |

## Quick start

Once per machine, install the `ck` plugin for your user:

```bash
claude plugin marketplace add moreiraeugenio/claude-kit
claude plugin install ck@claude-kit
```

Then in any project:

1. `/ck:setup`: pick the plugins, and it enables and installs them.
2. `/reload-plugins`
3. `/ck:sync`: brings the codebase in line with them. Run it again whenever a plugin changes.

Anyone else who clones the project gets the enabled plugins from its committed `.claude/settings.json`, and doesn't need `ck` (see below). The prompts further down do the same as the two commands without installing `ck`.

## Enable it in a project

Copy [`templates/project-settings.json`](templates/project-settings.json) to `.claude/settings.json` in the project (merge the keys if that file already exists), keep only the plugins the project needs under `enabledPlugins`, and commit it.

```json
{
  "extraKnownMarketplaces": {
    "claude-kit": {
      "source": { "source": "github", "repo": "moreiraeugenio/claude-kit" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "ck-frontend@claude-kit": true,
    "ck-infra@claude-kit": true
  }
}
```

Each person who clones the project trusts the folder when Claude Code asks, then installs the plugins once with `/plugin` (or the CLI below). Until then `/plugin` lists them as enabled in project settings but not installed.

CLI equivalent, run from the project root:

```bash
claude plugin marketplace add moreiraeugenio/claude-kit --scope project
claude plugin install ck-frontend@claude-kit --scope project
```

The CLI rewrites `.claude/settings.json` without `autoUpdate`, so prefer copying the template, or add `"autoUpdate": true` back afterwards. It matters because third-party marketplaces don't auto-update by default. With it on, updates download in the background and apply on the next launch or after `/reload-plugins`. To update by hand, run `claude plugin update ck-frontend@claude-kit`.

## Set up a project with prompts

Use these where `ck` isn't installed: they do what `/ck:setup` and `/ck:sync` do. Two prompts to paste into Claude Code in the target project. They don't name specific plugins, so they keep working as plugins, skills and agents are added here. Restart Claude Code between them, because plugins only load when a session starts.

**1. Install.** Lets you pick plugins from select boxes (fitting ones pre-marked as recommended), then enables them:

```
Set up the claude-kit plugin marketplace (github: moreiraeugenio/claude-kit) for this project.

1. Read https://github.com/moreiraeugenio/claude-kit/blob/main/.claude-plugin/marketplace.json and the Plugins table in the README to see what every plugin does. Leave out `ck`: it's installed per user, not per project.
2. Look at this project's stack and tooling to work out which plugins fit. Workflow plugins (for example git or commit conventions) fit any project, not only a particular stack.
3. Let me choose with the AskUserQuestion tool, as a multi-select question. Each plugin is one option: the label is the plugin name, and the description is one short line on what it does. Add "(Recommended)" to the label of the plugins that fit this project and put them first. The tool allows at most 4 options per question, so if there are more plugins, split them across several questions (up to 4 per call) grouped by area.
4. Edit `.claude/settings.json` in the project root. Create the file and the `.claude/` folder if they don't exist. If the file already exists, merge these keys in and keep every other setting. If `enabledPlugins` or `extraKnownMarketplaces` already exist, add to them instead of replacing them:
   - `extraKnownMarketplaces.claude-kit` = { "source": { "source": "github", "repo": "moreiraeugenio/claude-kit" }, "autoUpdate": true }
   - `enabledPlugins` = "<plugin>@claude-kit": true for each plugin I selected
5. Check that the result is valid JSON, then show me the final file and ask me whether to commit and push it.
```

Then restart Claude Code and run `/plugin` to install the enabled plugins.

**2. Review and adjust.** With `ck` installed, run `/ck:sync` instead. It does the same as this prompt, but asks which plugins to sync against (enabled or not) and uses each one's latest version. Without `ck`, this prompt brings the codebase in line with every enabled plugin:

```
Bring this project in line with every claude-kit plugin enabled in `.claude/settings.json`.

1. For each enabled `<plugin>@claude-kit`, list all of its skills, agents, commands and hooks, and read each one in full (SKILL.md, agent and command files). If any are missing from your session, read them from https://github.com/moreiraeugenio/claude-kit/tree/main/plugins/<plugin> instead.
2. Review the whole project against the rules in each one. If one doesn't apply to this project, skip it and say why. Where a plugin provides an agent built for review or auditing, use that agent for its area. Some plugins cover a workflow rather than code (for example a skill that needs a per-project config file, such as the ck-git plugin's `.claude/git-workflow.json`): run their setup steps and ask me whatever they say to ask.
3. Before changing anything, show me a findings list grouped by plugin and skill/agent. For each finding give the file:line, the rule it breaks, and the fix you propose.
4. Then apply the fixes. Keep changes minimal and match the existing code style. Ask me before any destructive or infra-affecting change, such as deleting files, changing deploy targets or renaming env vars.
5. Run the project's existing lint, typecheck and tests, and report the results.
6. Finish with a summary of what changed per plugin, and anything you left alone on purpose.
7. Don't commit during the review. At the end, commit and push the way the enabled plugins say (for example the ck-git plugin's workflow). If no plugin covers it, ask me first.
```

Run `/ck:sync` (or prompt 2) again whenever a plugin changes.

## Use it in a project

Skills load on their own when the task matches, but they only fix code Claude is already editing and mention violations elsewhere. To apply a plugin to a whole existing codebase, run its sync command: `/ck-frontend:sync`, `/ck-infra:sync` or `/ck-git:sync`. Each one reads that plugin's latest rules, lists the findings, fixes them and runs your checks, without needing `ck`. Pass a focus to narrow it: `/ck-frontend:sync src/components`. For several plugins at once, use `/ck:sync`.

To apply a single skill, ask for it directly. Plugin skills are slash commands named `/<plugin>:<skill>`:

```
/ck-frontend:clickable-elements Review the whole codebase against these rules and fix every violation.
```

Or in plain words:

```
Use the clickable-elements skill to audit every page and component in this repo. Fix all violations, then summarise what changed per file.
```

- **Large repos:** ask for a list first ("List all violations grouped by file, don't change anything yet"), check it, then say "fix them".
- **Check it's installed:** `/plugin` should show `ck-frontend@claude-kit` as installed, and typing `/ck-frontend:` should autocomplete. If not, do the install step above on that machine.
- **Review without edits:** run `/code-review` and add "check against the clickable-elements skill" to review the current diff against these rules.

## Add a plugin

1. Create `plugins/ck-<area>/` (every plugin is named `ck-<area>` so its commands share the `/ck-` prefix) with `.claude-plugin/plugin.json` (`name`, `description`, `version`).
2. Put components at the plugin root: `skills/<skill>/SKILL.md`, `agents/*.md`, `commands/*.md`, `hooks/hooks.json`, `.mcp.json`.
3. Add `commands/sync.md` (copy another plugin's and change the name) so `/ck-<area>:sync` can review a whole project against it.
4. Register it in `.claude-plugin/marketplace.json` with `"source": "./plugins/ck-<area>"`.
5. Run `claude plugin validate .` and `claude plugin validate plugins/ck-<area>`.
6. Add a row to the table above, and enable it in this repo's `.claude/settings.json` (this repo uses every project plugin).

Plugin names can't start with `claude-` or `anthropic-`.

## Versioning

Installed copies stay on their version until the version string changes. When a plugin changes, bump `version` in **both** its `plugin.json` and its entry in `marketplace.json`. Otherwise nobody gets the update. If you tag releases, `claude plugin tag plugins/ck-<area>` creates a `ck-<area>--v<version>` tag and checks that the two versions match.

## Exception: fork a single skill into a project

If one project needs a customised or frozen version of a skill, copy it to that project's `.claude/skills/<name>/SKILL.md` and edit it there, and don't enable the plugin for that skill. The copy no longer gets updates from this repo.
