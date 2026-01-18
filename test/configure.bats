#!/usr/bin/env bats
# Tests for plugin/bin/configure.sh

bats_require_minimum_version 1.5.0
load test_helper

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export STARSHIP_CLAUDE_PLUGIN_ROOT="${PROJECT_ROOT}/plugin"
}

teardown() {
  if [ -n "${TEST_TEMP_DIR:-}" ] && [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

run_configure() {
  "${PROJECT_ROOT}/plugin/bin/configure.sh" "$@"
}

# Helper to verify template was used by comparing first N lines
verify_template_match() {
  local config_file="$1"
  local template_file="$2"
  local num_lines="${3:-10}"

  # Compare structure, ignoring palette line since that's expected to change
  diff <(head -n "$num_lines" "$template_file" | grep -v '^palette =') \
       <(head -n "$num_lines" "$config_file" | grep -v '^palette =')
}

@test "configure.sh: shows help with --help" {
  run run_configure --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: configure.sh"* ]]
  [[ "$output" == *"--nerdfont"* ]]
  [[ "$output" == *"--palette"* ]]
}

@test "configure.sh: shows help with -h" {
  run run_configure -h

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: configure.sh"* ]]
}

@test "configure.sh: generates default config with minimal-text template" {
  local output_file="${TEST_TEMP_DIR}/config.toml"

  run run_configure --write "$output_file"

  [ "$status" -eq 0 ]
  [ -f "$output_file" ]

  # Verify it's the minimal-text template
  grep -q '# Minimal Text Template' "$output_file"
  grep -q 'palette = "catppuccin_mocha"' "$output_file"
  grep -q '\[directory\]' "$output_file"
}

@test "configure.sh: applies dracula palette correctly" {
  local output_file="${TEST_TEMP_DIR}/config.toml"

  run run_configure --palette dracula --write "$output_file"

  [ "$status" -eq 0 ]
  [ -f "$output_file" ]

  # Verify palette was substituted
  grep -q 'palette = "dracula"' "$output_file"
  grep -q '\[palettes.dracula\]' "$output_file"
}

@test "configure.sh: rejects invalid palette" {
  run run_configure --palette invalid_palette_name

  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid palette 'invalid_palette_name'"* ]]
  [[ "$output" == *"Valid palettes:"* ]]
}

@test "configure.sh: minimal style uses minimal-text template by default" {
  local output_file="${TEST_TEMP_DIR}/config.toml"

  run run_configure --style minimal --write "$output_file"

  [ "$status" -eq 0 ]
  grep -q '# Minimal Text Template' "$output_file"
  grep -q '\[directory\]' "$output_file"
}

@test "configure.sh: bubbles style uses bubbles-nerd template" {
  local output_file="${TEST_TEMP_DIR}/config.toml"

  run run_configure --style bubbles --nerdfont --write "$output_file"

  [ "$status" -eq 0 ]
  [ -f "$output_file" ]

  # Verify template structure matches bubbles-nerd
  verify_template_match "$output_file" \
    "${STARSHIP_CLAUDE_PLUGIN_ROOT}/templates/bubbles-nerd.toml" 15
}

@test "configure.sh: rejects invalid style" {
  run run_configure --style invalid_style

  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid style 'invalid_style'"* ]]
  [[ "$output" == *"Valid styles: minimal, bubbles"* ]]
}

@test "configure.sh: --palette requires argument" {
  run run_configure --palette

  [ "$status" -eq 1 ]
  [[ "$output" == *"Option --palette requires an argument"* ]]
}

@test "configure.sh: --style requires argument" {
  run run_configure --style

  [ "$status" -eq 1 ]
  [[ "$output" == *"Option --style requires an argument"* ]]
}

@test "configure.sh: --config requires argument" {
  run run_configure --config

  [ "$status" -eq 1 ]
  [[ "$output" == *"Option --config requires an argument"* ]]
}

@test "configure.sh: --path requires argument" {
  run run_configure --path

  [ "$status" -eq 1 ]
  [[ "$output" == *"Option --path requires an argument"* ]]
}

@test "configure.sh: --write defaults to ~/.claude/starship.toml" {
  # Create test directory for default location
  local default_dir="${TEST_TEMP_DIR}/.claude"
  mkdir -p "$default_dir"

  # Temporarily override HOME to use TEST_TEMP_DIR
  local saved_home="$HOME"
  export HOME="$TEST_TEMP_DIR"

  run run_configure --write

  # Restore HOME
  export HOME="$saved_home"

  [ "$status" -eq 0 ]
  [ -f "${default_dir}/starship.toml" ]

  # Verify it wrote the config
  grep -q 'palette = "catppuccin_mocha"' "${default_dir}/starship.toml"
  [[ "$output" == *"Wrote config to:"* ]]
  [[ "$output" == *".claude/starship.toml"* ]]
}

@test "configure.sh: rejects unknown option" {
  run run_configure --unknown-option

  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --unknown-option"* ]]
}

@test "configure.sh: rejects unexpected positional argument" {
  run run_configure unexpected_arg

  [ "$status" -eq 1 ]
  [[ "$output" == *"Unexpected argument: unexpected_arg"* ]]
}

@test "configure.sh: uses minimal-nerd template with --nerdfont" {
  local output_file="${TEST_TEMP_DIR}/config.toml"

  run run_configure --nerdfont --write "$output_file"

  [ "$status" -eq 0 ]
  [ -f "$output_file" ]

  # Verify minimal-nerd template was used
  grep -q '# Minimal Nerd Template' "$output_file"
  grep -q 'palette = "catppuccin_mocha"' "$output_file"
}

@test "configure.sh: applies nord palette correctly" {
  local output_file="${TEST_TEMP_DIR}/config.toml"

  run run_configure --palette nord --write "$output_file"

  [ "$status" -eq 0 ]
  grep -q 'palette = "nord"' "$output_file"
  grep -q '\[palettes.nord\]' "$output_file"
}

@test "configure.sh: minimal-text template structure matches source" {
  local output_file="${TEST_TEMP_DIR}/config.toml"

  run run_configure --write "$output_file"

  [ "$status" -eq 0 ]

  # First 10 lines should match template (except palette line)
  verify_template_match "$output_file" \
    "${STARSHIP_CLAUDE_PLUGIN_ROOT}/templates/minimal-text.toml" 10
}

@test "configure.sh: --config passes through custom config" {
  local custom_config="${TEST_TEMP_DIR}/custom.toml"
  cat > "$custom_config" << 'EOF'
"$schema" = "https://starship.rs/config-schema.json"
add_newline = false
format = "$directory"
[directory]
style = "fg:blue"
EOF

  # With custom config, should skip template generation
  # Just verify it doesn't error and accepts the option
  run run_configure --config "$custom_config" 2>&1

  [ "$status" -eq 0 ]
}

@test "configure.sh: --write saves config to file" {
  local output_file="${TEST_TEMP_DIR}/saved-config.toml"

  run run_configure --write "$output_file"

  [ "$status" -eq 0 ]
  [ -f "$output_file" ]

  # Should contain palette setting
  grep -q 'palette = "catppuccin_mocha"' "$output_file"

  # Should have written config message
  [[ "$output" == *"Wrote config to:"* ]]
}

@test "configure.sh: --write creates valid TOML with all sections" {
  local output_file="${TEST_TEMP_DIR}/saved-config.toml"

  run run_configure --palette gruvbox_dark --write "$output_file"

  [ "$status" -eq 0 ]
  [ -f "$output_file" ]

  # Verify all key sections exist
  grep -q '"$schema" = "https://starship.rs/config-schema.json"' "$output_file"
  grep -q 'palette = "gruvbox_dark"' "$output_file"
  grep -q '\[directory\]' "$output_file"
  grep -q '\[env_var.CLAUDE_MODEL\]' "$output_file"
  grep -q '\[palettes.gruvbox_dark\]' "$output_file"
}

@test "configure.sh: --compare-styles shows both styles" {
  run run_configure --compare-styles

  [ "$status" -eq 0 ]
  [[ "$output" == *"MINIMAL:"* ]]
  [[ "$output" == *"POWERLINE:"* ]]
}

@test "configure.sh: --all-palettes shows all 6 palettes" {
  run run_configure --all-palettes

  [ "$status" -eq 0 ]

  # Should show all palette names
  [[ "$output" == *"catppuccin_mocha:"* ]]
  [[ "$output" == *"catppuccin_frappe:"* ]]
  [[ "$output" == *"dracula:"* ]]
  [[ "$output" == *"gruvbox_dark:"* ]]
  [[ "$output" == *"nord:"* ]]
  [[ "$output" == *"solarized_dark:"* ]]
}

@test "configure.sh: combines multiple options correctly" {
  local output_file="${TEST_TEMP_DIR}/config.toml"

  run run_configure --palette solarized_dark --nerdfont --style minimal --write "$output_file"

  [ "$status" -eq 0 ]
  grep -q 'palette = "solarized_dark"' "$output_file"
  grep -q '# Minimal Nerd Template' "$output_file"
}

@test "configure.sh: all six palettes are valid" {
  local output_file="${TEST_TEMP_DIR}/config.toml"
  local palettes=(catppuccin_mocha catppuccin_frappe dracula gruvbox_dark nord solarized_dark)

  for palette in "${palettes[@]}"; do
    run run_configure --palette "$palette" --write "$output_file"

    [ "$status" -eq 0 ]
    grep -q "palette = \"$palette\"" "$output_file"
    rm "$output_file"
  done
}

@test "configure.sh: error if starship-claude binary not found" {
  # Temporarily break PLUGIN_ROOT to make starship-claude unfindable
  export STARSHIP_CLAUDE_PLUGIN_ROOT="${TEST_TEMP_DIR}/nonexistent"

  run run_configure

  # Exit code will be 1 (our error) or 127 (command not found)
  [ "$status" -ne 0 ]
  [[ "$output" == *"starship-claude not found"* ]]
}

@test "configure.sh: error if template directory not found" {
  # Create a plugin root with bin/starship-claude but no templates
  local fake_plugin="${TEST_TEMP_DIR}/fake-plugin"
  mkdir -p "${fake_plugin}/bin"
  # Copy the real starship-claude so it exists but templates don't
  cp "${PROJECT_ROOT}/plugin/bin/starship-claude" "${fake_plugin}/bin/"

  export STARSHIP_CLAUDE_PLUGIN_ROOT="${fake_plugin}"

  run run_configure

  [ "$status" -eq 1 ]
  [[ "$output" == *"Template not found"* ]]
}
