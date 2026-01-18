---
name: starship
description: Starship-claude statusline setup wizard
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

Display this start message:

````markdown
Welcome to starship-claude setup! 🚀

With Claude's help, this will guide you through configuring a statusline to display useful information: project, context usage, model, and git status, right below your prompt.

Why Starship? Starship is a powerful and configurable prompt for shells like bash, zsh, and fish. I created starship-claude because I wanted the same thing in claude. Starship-claude doesn't have one built in style, you're free to create your own style to match your preferences.

You can read more about Starship here: https://starship.rs

Before we continue, starship-claude requires **Starship** (no surprise there). We need to install to continue. If you don't want to use Homebrew, you'll need to install yourself:

```bash
curl -sS https://starship.rs/install.sh | sh
```
````

Then ask:

- **Question**: "Install starship?"
- **Header**: "Starship"
- **Options**:
  - "brew install starship" → Run: `brew install starship`
  - "I installed it myself" → Start over from Step 1 and re-check starship
  - "Exit wizard" → Tell them to visit <https://starship.rs> when they're ready and exit the wizard

### If starship IS installed

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
  - "Replace it" → Continue to the next step
  - "Back it up and replace it" → Run: `cp ~/.claude/starship.toml ~/.claude/starship.toml.bak` and continue to the next step
  - "Keep it and exit" → Exit the wizard without changes

## Step 3: Nerd Font Detection

Ask the user if they can see Nerd Font icons.

> [!IMPORTANT]
> You can't display nerd fonts properly.
> You MUST run the cat command below.

```bash
cat ${CLAUDE_PLUGIN_ROOT}/templates/nerd-fonts-sample.txt
```

Then ask:

- **Question**: "Can you see the icons above clearly?"
- **Header**: "Nerd Font"
- **Options**:
  - "Yes, I can see the icons clearly" → Continue to Step 4
  - "No, I see boxes or question marks" → Set `has_nerd_fonts=false` and skip to Step 5

## Step 4: Format Style Selection

> [!NOTE]
> Only run this step if the user has Nerd Fonts.
> If they don't have Nerd Fonts, skip to Step 5 and use `minimal-text` template.

Show both style options side by side:

> [!Important]
> You can't display nerd fonts properly.
> You MUST run the command below to preview styles.

```bash
${CLAUDE_PLUGIN_ROOT}/bin/configure.sh --nerdfont --compare-styles
```

Then ask:

- **Question**: "Which prompt style do you prefer?"
- **Header**: "Style"
- **Options**:
  - "Minimal" → Set `chosen_style=minimal`
  - "Bubbles" → Set `chosen_style=bubbles`
  - "Powerline" → Set `chosen_style=powerline`

## Step 5: Color Palette Selection

Show all available palettes in the chosen style.

**If user has Nerd Fonts**, run:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/configure.sh --nerdfont --style ${chosen_style} --all-palettes
```

**If user does NOT have Nerd Fonts**, run:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/configure.sh --all-palettes
```

Then ask (you will need to split this into multiple questions if the interface doesn't support long lists):

- **Question**: "Which color palette do you like? (press ctrl+o to see)"
- **Header**: "Palette"
- **Options**:
  - "Catppuccin Mocha" → `chosen_palette=catppuccin_mocha`
  - "Catppuccin Frappe" → `chosen_palette=catppuccin_frappe`
  - "Tokyo Night" → `chosen_palette=tokyonight`
  - "Nord" → `chosen_palette=nord`
  - "Custom" -> Ask the user to describe or paste the color palette they want.

The user may ask for a different palette. That's ok, just `--write` without a color, then edit `~/.claude/starship.toml` with the custom colors.

## Step 6: Install Files

### 6a. Install starship-claude binary

```bash
mkdir -p ~/.local/bin ~/.claude && \
  cp ${CLAUDE_PLUGIN_ROOT}/bin/starship-claude ~/.local/bin/starship-claude && \
  chmod +x ~/.local/bin/starship-claude
```

### 6b. Generate starship.toml

Generate the configuration file using configure.sh based on the user's choices:

**If user has Nerd Fonts**, run:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/configure.sh --nerdfont --style ${chosen_style} --palette ${chosen_palette} --write
```

**If user does NOT have Nerd Fonts**, run:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/configure.sh --palette ${chosen_palette} --write
```

This will create `~/.claude/starship.toml` with the appropriate template and palette.

### 6c. Update settings.json

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

If the file doesn't exist, create it with just this configuration.
If it exists, preserve all other settings and only add/update the statusLine key.

### 6d. Optionally Update ~/.claude/starship.toml

If the user asked for a custom palette, read `~/.claude/starship.toml`, then substitute only the `[palettes.custom]` section at the end, replacing in with the user's custom colors.

```toml
# Example custom palette section
[palettes.custom]

claude = "#D97757" # This is Claude Code's brand color
claude_bg = "#313244"

directory = "#89dceb"
directory_bg = "#1e1e2e"

git_branch = "#eba0ac"
git_status = "#f2cdcd"
git_bg = "#313244"

model = "#74c7ec"
model_bg = "#1e1e2e"

context = "#fab387"
context_bg = "#313244"

cost = "#a6e3a1"
cost_bg = "#45475a"
```

Preserve all other settings and avoid writing the whole file (it will mangle any nerd fonts).

## Step 7: Verify Installation

Run a test to verify everything works:

```bash
echo '{"model":{"display_name":"Opus 4.5"},"cost":{"total_cost_usd":0.05},"context_window":{"context_window_size":200000,"current_usage":{"input_tokens":10000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}' | ~/.local/bin/starship-claude --no-progress
```

Show the output to the user.

## Step 8: Success Message

Display this completion message:

```
Setup complete!

You are now the proud owner of a starship powered statusline.

TODO:
1. Restart claude if you don't see the statusline.
2. Run /starship at any time to reconfigure.
3. Customize it by hand by editing ~/.claude/starship.toml

Files created/updated:
- ~/.local/bin/starship-claude (statusline script)
- ~/.claude/starship.toml (starship config)
- ~/.claude/settings.json (claude settings)

I hope you enjoy! Please let me know if you have any feedback!
```

## Template File Locations

The template files are located at `${CLAUDE_PLUGIN_ROOT}/templates/`:

```
templates/
├── bubbles.toml       # Bubbles style with nerd fonts
├── minimal-text.toml  # Minimal style without nerd fonts
├── minimal-nerd.toml  # Minimal style with nerd fonts
├── powerline.toml     # Powerline style with nerd fonts
└── starship-claude    # Binary for generating statusline
```
