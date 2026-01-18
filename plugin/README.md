# starship-claude plugin

A Claude Code plugin that provides an interactive setup wizard for configuring
[starship-claude](https://github.com/martinemde/starship-claude) as your
Claude Code statusline.

## Installation

> [!TIP]
> Run each of the following commands in `claude` _one at a time_.

```claude
/plugin marketplace add martinemde/starship-claude
```

```claude
/plugin install starship-claude@starship-claude
```

Then run the setup wizard as many times as you want:

```claude
/starship
```

The wizard will:

1. Check if starship is installed (offers to install if missing)
2. Detect existing configuration and ask what to do
3. Ask about Nerd Font support
4. Let you choose a color palette
5. Let you choose a prompt style
6. Install the script and generate your config
7. Update your Claude Code settings
8. Verify everything works

## What Gets Installed

After setup completes, you'll have:

- `~/.local/bin/starship-claude` - The statusline script
- `~/.claude/starship.toml` - Starship configuration for Claude Code
- `~/.claude/settings.json` - Updated with statusLine configuration

## Reconfiguring

To change your palette, style, or other options, re-run the setup wizard:

```claude
/starship
```
