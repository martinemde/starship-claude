#!/usr/bin/env bats
# Test model name extraction and formatting

load test_helper

@test "extracts Sonnet model name with icon" {
  output=$(run_with_fixture "active_session_with_context.json")
  model=$(get_env_var "CLAUDE_MODEL" "$output")

  # Should contain "sonnet" (the nerdfonts icon may vary)
  [[ "$model" == *"sonnet"* ]]
}

@test "handles display_name field for model" {
  output=$(run_with_fixture "active_session_with_context.json")
  model=$(get_env_var "CLAUDE_MODEL" "$output")

  # Should contain "sonnet" (case-insensitive match in original)
  [[ "$model" == *"sonnet"* ]]
}

@test "sets STARSHIP_SHELL to sh" {
  output=$(run_with_fixture "active_session_with_context.json")
  assert_env_equals "STARSHIP_SHELL" "sh" "$output"
}

@test "sets STARSHIP_CONFIG path" {
  output=$(run_with_fixture "active_session_with_context.json")

  config=$(get_env_var "STARSHIP_CONFIG" "$output")
  [[ "$config" == *"/.claude/starship.toml" ]]
}
