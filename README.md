# claude-kit

My reusable Claude Code skills, agents and commands, packaged as a [plugin marketplace](https://code.claude.com/docs/en/plugins/marketplace-reference). Each project opts in through its own committed `.claude/settings.json`, so nothing is installed globally and it works on any machine or account that clones the project.

## Plugins

| Plugin | What it does |
|---|---|
| `frontend` | Clickable elements look and act clickable: real links and buttons, pointer cursor, hover and focus states, in any stack. |

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
    "frontend@claude-kit": true
  }
}
```

Each person who clones the project trusts the folder when Claude Code asks, then installs the plugins once with `/plugin` (or the CLI below). Until then `/plugin` lists them as enabled in project settings but not installed.

CLI equivalent, run from the project root:

```bash
claude plugin marketplace add moreiraeugenio/claude-kit --scope project
claude plugin install frontend@claude-kit --scope project
```

The CLI rewrites `.claude/settings.json` without `autoUpdate`, so prefer copying the template, or add `"autoUpdate": true` back afterwards. It matters because Third-party marketplaces don't auto-update by default. With it on, updates download in the background and apply on the next launch or after `/reload-plugins`. To update by hand, run `claude plugin update frontend@claude-kit`.

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
