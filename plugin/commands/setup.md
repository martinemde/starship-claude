---
name: setup
description: Interactive setup wizard for starship-claude statusline
argument-hint: '[--reset]'
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - Glob
---

# Starship-Claude Setup Wizard

You are running an interactive setup wizard to configure the starship-claude statusline for Claude Code. Follow these steps in order, using AskUserQuestion for each decision point.

## Step 1: Check for Starship

Run this command to check if starship is installed:

```bash
command -v starship >/dev/null 2>&1 && echo "installed" || echo "not_installed"
```

### If starship is NOT installed:

Tell the user: "This prompt uses **Starship**, a fast configurable prompt for any shell. You can read more about it at https://starship.rs. We need to install starship to use this prompt."

Then ask:

- **Question**: "Install starship to continue?"
- **Header**: "Starship"
- **Options**:
  - "Install starship" → Run: `curl -sS https://starship.rs/install.sh | sh`
  - "Exit wizard" → Tell them to visit https://starship.rs when they're ready and exit the wizard

### If starship IS installed:

Tell the user: "Looks like you already have starship installed, great!"

Then ask:

- **Question**: "Ready to configure your Claude statusline?"
- **Header**: "Ready"
- **Options**:
  - "Launch it! 🚀" → Continue to the next step

## Step 2: Check Existing Configuration

Check if configuration already exists:

```bash
test -f ~/.claude/starship.toml && echo "exists" || echo "not_found"
```

If it exists, ask:

- **Question**: "Found existing ~/.claude/starship.toml. What should I do?"
- **Header**: "Existing"
- **Options**:
  - "Replace it" → Continue with installation
  - "Keep it and exit" → Exit the wizard without changes

## Step 3: Nerd Font Detection

Ask the user if they can see Nerd Font icons:

- **Question**: "Can you see these icons clearly? 󰚩 󱚦 (<--robot faces)"
- **Header**: "Nerd Font"
- **Options**:
  - "Yes, I can see the icons clearly" → Set `use_nerd_fonts = true`
  - "No, I see boxes or question marks" → Set `use_nerd_fonts = false`

## Step 4: Color Palette Selection

Ask the user to choose a color palette:

- **Question**: "Which color palette would you like?"
- **Header**: "Palette"
- **Options**:
  - "Catppuccin Mocha (Recommended)" → `palette = catppuccin_mocha`
  - "Catppuccin Latte (Light)" → `palette = catppuccin_latte`
  - "Solarized Dark" → `palette = solarized_dark`
  - "Gruvbox Dark" → `palette = gruvbox_dark`

If user selects "Other", ask a follow-up question:

- **Question**: "Choose from additional palettes:"
- **Header**: "Palette"
- **Options**:
  - "Nord" → `palette = nord`
  - "Dracula" → `palette = dracula`
  - "Catppuccin Frappe" → `palette = catppuccin_frappe`
  - "Catppuccin Macchiato" → `palette = catppuccin_macchiato`

## Step 5: Format Style Selection

Ask the user which prompt style they prefer:

- **Question**: "Which prompt style do you prefer?"
- **Header**: "Style"
- **Options**:
  - "Powerline (Recommended)" → Arrow separators with colored backgrounds
  - "Minimal" → Clean text without backgrounds or separators

## Step 6: Install Files

### 6a. Create directories

```bash
mkdir -p ~/.local/bin ~/.claude
```

### 6b. Download the starship-claude script

```bash
curl -fsSL https://raw.githubusercontent.com/martinemde/starship-claude/main/starship-claude \
  -o ~/.local/bin/starship-claude && chmod +x ~/.local/bin/starship-claude
```

### 6c. Generate starship.toml

Read the appropriate template files from `${CLAUDE_PLUGIN_ROOT}/templates/` and combine them:

1. Read the base template based on style and nerd font choice:
   - Powerline + Nerd Fonts: `templates/base-powerline-nerd.toml`
   - Powerline + No Nerd Fonts: `templates/base-powerline-text.toml`
   - Minimal (either): `templates/base-minimal.toml`

2. Read the palette file: `templates/palettes/{palette_name}.toml`

3. Combine the base template and palette into a single file and write to `~/.claude/starship.toml`

### 6d. Update settings.json

Read `~/.claude/settings.json` if it exists. Add or update the statusLine configuration:

```json
{
  "statusLine": {
    "type": "command",
    "padding": 0,
    "command": "~/.local/bin/starship-claude"
  }
}
```

If the file doesn't exist, create it with just the statusLine configuration.
If it exists, preserve all other settings and only add/update the statusLine key.

## Step 7: Verify Installation

Run a test to verify everything works:

```bash
echo '{"model":{"display_name":"Sonnet 4"},"cost":{"total_cost_usd":0.05},"context_window":{"context_window_size":200000,"current_usage":{"input_tokens":10000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}' | ~/.local/bin/starship-claude --no-progress
```

Show the output to the user.

## Step 8: Success Message

Display this completion message:

```
Setup complete!

Your starship-claude statusline is now configured with:
- Palette: {palette_name}
- Style: {style_name}
- Nerd Fonts: {yes/no}

Files created/updated:
- ~/.local/bin/starship-claude (script)
- ~/.claude/starship.toml (starship config)
- ~/.claude/settings.json (Claude Code settings)

To see your new statusline, start a new Claude Code session.

To reconfigure later, run /starship-claude:setup again.
```

## Template File Locations

The template files are located at `${CLAUDE_PLUGIN_ROOT}/templates/`:

```
templates/
├── base-powerline-nerd.toml   # Powerline style with Nerd Font icons
├── base-powerline-text.toml   # Powerline style without Nerd Fonts
├── base-minimal.toml          # Minimal clean style
└── palettes/
    ├── catppuccin_mocha.toml
    ├── catppuccin_latte.toml
    ├── catppuccin_frappe.toml
    ├── catppuccin_macchiato.toml
    ├── gruvbox_dark.toml
    ├── dracula.toml
    ├── nord.toml
    └── solarized_dark.toml
```

To generate the final config, concatenate the base template with the palette file.
