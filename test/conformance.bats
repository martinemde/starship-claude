#!/usr/bin/env bats
#
# conformance.bats - Black-box acceptance tests for starship-claude
#
# These tests verify the complete user experience by testing actual prompt
# output against golden files. No mocks, no checking for specific strings or
# implementation details - just comparing final rendered output.
#
# Philosophy:
# - Test from the outside, like a user experiences it
# - Generate configs using configure.sh --write
# - Run starship-claude with those configs
# - Compare actual output to expected golden files
#
# Usage:
#   bats test/conformance.bats                    # Run all tests
#   bats test/conformance.bats -f "minimal"       # Run tests matching "minimal"
#   BATS_UPDATE_GOLDEN=1 bats test/conformance.bats  # Update all golden files
#

load test_helper

# ============================================================================
# Basic Format Tests - Verify each style generates valid output
# ============================================================================

@test "conformance: minimal text style with catppuccin_mocha palette" {
  local config="${TEST_TEMP_DIR}/minimal-text-mocha.toml"

  # Generate config
  run_configure --style minimal --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output using high_cost fixture
  output=$(get_prompt_from_config_with_fixture "$config" "high_cost.json")

  # Compare against golden file
  assert_golden_match "minimal-text-mocha-high-cost" "$output"
}

@test "conformance: minimal nerdfont style with catppuccin_mocha palette" {
  local config="${TEST_TEMP_DIR}/minimal-nerd-mocha.toml"

  # Generate config
  run_configure --style minimal --nerdfont --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output using high_cost fixture
  output=$(get_prompt_from_config_with_fixture "$config" "high_cost.json")

  # Compare against golden file
  assert_golden_match "minimal-nerd-mocha-high-cost" "$output"
}

@test "conformance: bubbles style with nord palette" {
  local config="${TEST_TEMP_DIR}/bubbles-nord.toml"

  # Generate config
  run_configure --style bubbles --palette nord --write "$config" >/dev/null 2>&1

  # Get prompt output using context_85_percent fixture
  output=$(get_prompt_from_config_with_fixture "$config" "context_85_percent.json")

  # Compare against golden file
  assert_golden_match "bubbles-nord-context-85" "$output"
}

@test "conformance: powerline style with dracula palette" {
  local config="${TEST_TEMP_DIR}/powerline-dracula.toml"

  # Generate config
  run_configure --style powerline --palette dracula --write "$config" >/dev/null 2>&1

  # Get prompt output using low_cost_session fixture
  output=$(get_prompt_from_config_with_fixture "$config" "low_cost_session.json")

  # Compare against golden file
  assert_golden_match "powerline-dracula-low-cost" "$output"
}

# ============================================================================
# Boundary Tests - Edge cases
# ============================================================================

@test "conformance: minimal text - very low cost (< $0.01)" {
  local config="${TEST_TEMP_DIR}/minimal-text-mocha.toml"

  # Generate config
  run_configure --style minimal --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output using low_cost fixture
  output=$(get_prompt_from_config_with_fixture "$config" "low_cost_session.json")

  # Compare against golden file
  assert_golden_match "minimal-text-mocha-low-cost" "$output"
}

@test "conformance: minimal text - zero cost" {
  local config="${TEST_TEMP_DIR}/minimal-text-mocha.toml"

  # Generate config
  run_configure --style minimal --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output using zero_cost fixture
  output=$(get_prompt_from_config_with_fixture "$config" "zero_cost.json")

  # Compare against golden file
  assert_golden_match "minimal-text-mocha-zero-cost" "$output"
}

@test "conformance: bubbles - high context usage (85%)" {
  local config="${TEST_TEMP_DIR}/bubbles-mocha.toml"

  # Generate config
  run_configure --style bubbles --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output using context_85_percent fixture
  output=$(get_prompt_from_config_with_fixture "$config" "context_85_percent.json")

  # Compare against golden file
  assert_golden_match "bubbles-mocha-context-85" "$output"
}

@test "conformance: powerline - medium context usage (65%)" {
  local config="${TEST_TEMP_DIR}/powerline-mocha.toml"

  # Generate config
  run_configure --style powerline --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output using context_65_percent fixture
  output=$(get_prompt_from_config_with_fixture "$config" "context_65_percent.json")

  # Compare against golden file
  assert_golden_match "powerline-mocha-context-65" "$output"
}

# ============================================================================
# Cross-Style Consistency Tests
# ============================================================================

@test "conformance: all styles with tokyonight palette - same input" {
  # Test that all three styles work correctly with the same palette and input
  local fixture="medium_cost.json"

  # Minimal text
  local config_minimal="${TEST_TEMP_DIR}/minimal-text-tokyo.toml"
  run_configure --style minimal --palette tokyonight --write "$config_minimal" >/dev/null 2>&1
  output=$(get_prompt_from_config_with_fixture "$config_minimal" "$fixture")
  assert_golden_match "minimal-text-tokyonight-medium-cost" "$output"

  # Bubbles
  local config_bubbles="${TEST_TEMP_DIR}/bubbles-tokyo.toml"
  run_configure --style bubbles --palette tokyonight --write "$config_bubbles" >/dev/null 2>&1
  output=$(get_prompt_from_config_with_fixture "$config_bubbles" "$fixture")
  assert_golden_match "bubbles-tokyonight-medium-cost" "$output"

  # Powerline
  local config_powerline="${TEST_TEMP_DIR}/powerline-tokyo.toml"
  run_configure --style powerline --palette tokyonight --write "$config_powerline" >/dev/null 2>&1
  output=$(get_prompt_from_config_with_fixture "$config_powerline" "$fixture")
  assert_golden_match "powerline-tokyonight-medium-cost" "$output"
}

# ============================================================================
# Palette Coverage Tests
# ============================================================================

@test "conformance: bubbles with all palettes" {
  local fixture="active_session_with_context.json"

  # Test each palette
  for palette in catppuccin_mocha catppuccin_frappe dracula gruvbox_dark nord tokyonight; do
    local config="${TEST_TEMP_DIR}/bubbles-${palette}.toml"
    run_configure --style bubbles --palette "$palette" --write "$config" >/dev/null 2>&1
    output=$(get_prompt_from_config_with_fixture "$config" "$fixture")
    assert_golden_match "bubbles-${palette}-active-session" "$output"
  done
}

# ============================================================================
# Regression Tests - Prevent specific bugs from reoccurring
# ============================================================================

@test "conformance: config files don't contain test artifacts" {
  local config="${TEST_TEMP_DIR}/test-artifacts.toml"

  # Generate config
  run_configure --style minimal --palette nord --write "$config" >/dev/null 2>&1

  # Verify config file doesn't contain test-specific strings
  config_content=$(cat "$config")

  # Should not contain fixture paths or test directory references
  [[ ! "$config_content" =~ /tmp ]]
  [[ ! "$config_content" =~ fixtures ]]
  [[ ! "$config_content" =~ test/ ]]
}

@test "conformance: preview output matches written config output" {
  # Verify that --write produces configs that generate identical output to preview

  # Get preview output (configure.sh adds a trailing newline in preview mode)
  preview_output=$(run_configure --style minimal --palette catppuccin_mocha)

  # Write config and get output from that config
  local config="${TEST_TEMP_DIR}/preview-test.toml"
  run_configure --style minimal --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Use same sample JSON that configure.sh uses for preview
  local sample_json='{"model":{"display_name":"Opus 4.5"},"cost":{"total_cost_usd":0.05},"context_window":{"context_window_size":200000,"current_usage":{"input_tokens":10000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}'
  config_output=$(get_prompt_from_config "$config" "$sample_json")

  # Strip trailing newline from preview for comparison (preview adds \n, config doesn't)
  preview_stripped="${preview_output%$'\n'}"

  # Core prompt content should match
  [[ "$preview_stripped" == "$config_output" ]]
}

@test "conformance: no session data produces empty prompt segments" {
  local config="${TEST_TEMP_DIR}/minimal-text-mocha.toml"

  # Generate config
  run_configure --style minimal --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output with no current_usage
  output=$(get_prompt_from_config_with_fixture "$config" "session_without_current_usage.json")

  # Compare against golden file
  assert_golden_match "minimal-text-mocha-no-usage" "$output"
}

# ============================================================================
# Progress Bar Tests - Capture OSC 9;4 sequences
# ============================================================================

@test "conformance: minimal text with progress bar - high cost" {
  local config="${TEST_TEMP_DIR}/minimal-text-mocha.toml"

  # Generate config
  run_configure --style minimal --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output WITH progress bar sequences (no --no-progress)
  output=$(get_prompt_with_progress "$config" "high_cost.json")

  # Compare against golden file (should include OSC 9;4 sequences)
  assert_golden_match "minimal-text-mocha-high-cost-with-progress" "$output"
}

@test "conformance: bubbles with progress bar - context 85%" {
  local config="${TEST_TEMP_DIR}/bubbles-mocha.toml"

  # Generate config
  run_configure --style bubbles --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output WITH progress bar sequences
  output=$(get_prompt_with_progress "$config" "context_85_percent.json")

  # Compare against golden file (should include OSC 9;4 sequences)
  assert_golden_match "bubbles-mocha-context-85-with-progress" "$output"
}

@test "conformance: powerline with progress bar - medium context" {
  local config="${TEST_TEMP_DIR}/powerline-mocha.toml"

  # Generate config
  run_configure --style powerline --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output WITH progress bar sequences
  output=$(get_prompt_with_progress "$config" "context_65_percent.json")

  # Compare against golden file (should include OSC 9;4 sequences)
  assert_golden_match "powerline-mocha-context-65-with-progress" "$output"
}

@test "conformance: minimal text with progress bar - zero cost" {
  local config="${TEST_TEMP_DIR}/minimal-text-mocha.toml"

  # Generate config
  run_configure --style minimal --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output WITH progress bar sequences
  output=$(get_prompt_with_progress "$config" "zero_cost.json")

  # Compare against golden file (should include OSC 9;4 sequences)
  assert_golden_match "minimal-text-mocha-zero-cost-with-progress" "$output"
}

@test "conformance: minimal text with progress bar - context 50%" {
  local config="${TEST_TEMP_DIR}/minimal-text-mocha.toml"

  # Generate config
  run_configure --style minimal --palette catppuccin_mocha --write "$config" >/dev/null 2>&1

  # Get prompt output WITH progress bar sequences
  # 50% context should trigger OSC 9;4;4 (warning state)
  output=$(get_prompt_with_progress "$config" "context_50_percent.json")

  # Compare against golden file (should include OSC 9;4;4 sequence)
  assert_golden_match "minimal-text-mocha-context-50-with-progress" "$output"
}
