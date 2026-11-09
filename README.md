# claude-kit

My reusable Claude Code skills, agents and commands, packaged as a [plugin marketplace](https://code.claude.com/docs/en/plugins/marketplace-reference). Each project opts in through its own committed `.claude/settings.json`, so nothing is installed globally and it works on any machine or account that clones the project.

## Plugins

| Plugin | What it does |
|---|---|
| `frontend` | Clickable elements look and act clickable: real links and buttons, pointer cursor, hover and focus states, in any stack. |
| `infra` | Railway: IaC in `.railway/` with one TypeScript file per service and its own `package.json` (`plan`, `apply`, `deploy:<service>` scripts), no `railway.json`, deploys via `railway up` (never a linked GitHub repo), every service and database built from a Dockerfile (no templates), role-based names like `database` / `database-data`. |
| `git` | Commits and pushes: asks once per project whether it's solo or team (saved in a committed `.claude/git-workflow.json`). Solo commits and pushes straight to main, never branching unless asked; team uses the workflow picked at setup. Claude asks to commit and push after every change (Stop hook). |

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
    "frontend@claude-kit": true,
    "infra@claude-kit": true
  }
}
```

Each person who clones the project trusts the folder when Claude Code asks, then installs the plugins once with `/plugin` (or the CLI below). Until then `/plugin` lists them as enabled in project settings but not installed.

CLI equivalent, run from the project root:

```bash
claude plugin marketplace add moreiraeugenio/claude-kit --scope project
claude plugin install frontend@claude-kit --scope project
```

The CLI rewrites `.claude/settings.json` without `autoUpdate`, so prefer copying the template, or add `"autoUpdate": true` back afterwards. It matters because third-party marketplaces don't auto-update by default. With it on, updates download in the background and apply on the next launch or after `/reload-plugins`. To update by hand, run `claude plugin update frontend@claude-kit`.

## Set up a project with prompts

Two prompts to paste into Claude Code in the target project. They don't name specific plugins, so they keep working as plugins, skills and agents are added here. Restart Claude Code between them, because plugins only load when a session starts.

**1. Install.** Lets you pick plugins from select boxes (fitting ones pre-marked as recommended), then enables them:

```
Set up the claude-kit plugin marketplace (github: moreiraeugenio/claude-kit) for this project.

1. Read https://github.com/moreiraeugenio/claude-kit/blob/main/.claude-plugin/marketplace.json and the Plugins table in the README to see what every plugin does.
2. Look at this project's stack and tooling to work out which plugins fit.
3. Let me choose with the AskUserQuestion tool, as a multi-select question. Each plugin is one option: the label is the plugin name, and the description is one short line on what it does. Add "(Recommended)" to the label of the plugins that fit this project and put them first. The tool allows at most 4 options per question, so if there are more plugins, split them across several questions (up to 4 per call) grouped by area.
4. Edit `.claude/settings.json` in the project root. Create the file and the `.claude/` folder if they don't exist. If the file already exists, merge these keys in and keep every other setting. If `enabledPlugins` or `extraKnownMarketplaces` already exist, add to them instead of replacing them:
   - `extraKnownMarketplaces.claude-kit` = { "source": { "source": "github", "repo": "moreiraeugenio/claude-kit" }, "autoUpdate": true }
   - `enabledPlugins` = "<plugin>@claude-kit": true for each plugin I selected
5. Check that the result is valid JSON, then show me the final file. Don't commit.
```

Then restart Claude Code and run `/plugin` to install the enabled plugins.

**2. Review and adjust.** Brings the codebase in line with every enabled plugin:

```
Bring this project in line with every claude-kit plugin enabled in `.claude/settings.json`.

1. For each enabled `<plugin>@claude-kit`, list all of its skills, agents, commands and hooks, and read each one in full (SKILL.md, agent and command files). If any are missing from your session, read them from https://github.com/moreiraeugenio/claude-kit/tree/main/plugins/<plugin> instead.
2. Review the whole project against the rules in each one. If one doesn't apply to this project, skip it and say why. Where a plugin provides an agent built for review or auditing, use that agent for its area.
3. Before changing anything, show me a findings list grouped by plugin and skill/agent. For each finding give the file:line, the rule it breaks, and the fix you propose.
4. Then apply the fixes. Keep changes minimal and match the existing code style. Ask me before any destructive or infra-affecting change, such as deleting files, changing deploy targets or renaming env vars.
5. Run the project's existing lint, typecheck and tests, and report the results.
6. Finish with a summary of what changed per plugin, and anything you left alone on purpose.

Don't commit.
```

Run prompt 2 again whenever a plugin gains new skills or agents.

## Use it in a project

Skills load on their own when the task matches, but they only fix code Claude is already editing and mention violations elsewhere. To apply a skill to a whole existing codebase, ask for it directly. Plugin skills are slash commands named `/<plugin>:<skill>`:

```
/frontend:clickable-elements Review the whole codebase against these rules and fix every violation.
```

Or in plain words:

```
Use the clickable-elements skill to audit every page and component in this repo. Fix all violations, then summarise what changed per file.
```

- **Large repos:** ask for a list first ("List all violations grouped by file, don't change anything yet"), check it, then say "fix them".
- **Check it's installed:** `/plugin` should show `frontend@claude-kit` as installed, and typing `/frontend:` should autocomplete. If not, do the install step above on that machine.
- **Review without edits:** run `/code-review` and add "check against the clickable-elements skill" to review the current diff against these rules.

## Add a plugin

1. Create `plugins/<name>/` with `.claude-plugin/plugin.json` (`name`, `description`, `version`).
2. Put components at the plugin root: `skills/<skill>/SKILL.md`, `agents/*.md`, `commands/*.md`, `hooks/hooks.json`, `.mcp.json`.
3. Register it in `.claude-plugin/marketplace.json` with `"source": "./plugins/<name>"`.
4. Run `claude plugin validate .` and `claude plugin validate plugins/<name>`.
5. Add a row to the table above.

Plugin names can't start with `claude-` or `anthropic-`.

## Versioning

Installed copies stay on their version until the version string changes. When a plugin changes, bump `version` in **both** its `plugin.json` and its entry in `marketplace.json`. Otherwise nobody gets the update. If you tag releases, `claude plugin tag plugins/<name>` creates a `<name>--v<version>` tag and checks that the two versions match.

## Exception: fork a single skill into a project

If one project needs a customised or frozen version of a skill, copy it to that project's `.claude/skills/<name>/SKILL.md` and edit it there, and don't enable the plugin for that skill. The copy no longer gets updates from this repo.
