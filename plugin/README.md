# starship-claude plugin

A Claude Code plugin that provides an interactive setup wizard for configuring
[starship-claude](https://github.com/martinemde/starship-claude) as your
Claude Code statusline.

## Features

- **Interactive Setup**: Step-by-step wizard that guides you through configuration
- **Nerd Font Detection**: Asks if you can see icons and adjusts accordingly
- **Multiple Color Palettes**: Choose from 8 popular terminal themes
  - Catppuccin (Mocha, Latte, Frappe, Macchiato)
  - Gruvbox Dark
  - Dracula
  - Nord
  - Solarized Dark
- **Style Options**: Powerline arrows or minimal clean text
- **Automatic Installation**: Downloads the script, generates config, and updates settings

## Installation

> [!TIP]
> Run the following commands in `claude` to configure your statusline.

```claude
/plugin marketplace add martinemde/starship-claude
/plugin install starship-claude@starship-claude
```

## Usage

Run the setup wizard:

```
/starship-claude:setup
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

To change your palette, style, or other options, run the setup wizard again:

```
/starship-claude:setup
```
