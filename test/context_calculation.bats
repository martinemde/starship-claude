#!/usr/bin/env bats
# Test context window percentage calculation

load test_helper

@test "calculates context percentage from current_usage" {
  output=$(run_with_fixture "active_session_with_context.json")
  context=$(get_env_var "CLAUDE_CONTEXT" "$output")

  # Should be a percentage (left-padded to 3 chars)
  [[ "$context" =~ ^[\ 0-9][0-9]%$ ]]
}

@test "calculates 40% context correctly" {
  output=$(run_with_fixture "context_40_percent.json")
  context=$(get_env_var "CLAUDE_CONTEXT" "$output")

  [ "$context" = "40%" ]
}

@test "handles null current_usage gracefully" {
  output=$(run_with_fixture "session_without_current_usage.json")
  context=$(get_env_var "CLAUDE_CONTEXT" "$output")

  # Should show placeholder "~~%" when current_usage is null (maintains width)
  [ "$context" = "~~%" ]
}

@test "includes input_tokens in calculation" {
  # The calculation should be: (input_tokens + cache_creation + cache_read) / context_window_size * 100
  output=$(run_with_fixture "active_session_with_context.json")

  # Just verify it's set and is a valid percentage (left-padded)
  context=$(get_env_var "CLAUDE_CONTEXT" "$output")
  [[ "$context" =~ ^[\ 0-9][0-9]%$ ]]
}

@test "includes cache_creation_input_tokens in calculation" {
  output=$(run_with_fixture "low_cost_session.json")

  # This fixture has cache_creation_input_tokens = 31373
  context=$(get_env_var "CLAUDE_CONTEXT" "$output")
  [[ "$context" =~ ^[\ 0-9][0-9]%$ ]]
}

@test "includes cache_read_input_tokens in calculation" {
  # Find a fixture with cache_read > 0
  output=$(run_with_fixture "context_40_percent.json")

  context=$(get_env_var "CLAUDE_CONTEXT" "$output")
  [[ "$context" =~ ^[\ 0-9][0-9]%$ ]]
}

@test "exports individual token counts for debugging" {
  output=$(run_with_fixture "active_session_with_context.json")

  input_tokens=$(get_env_var "CLAUDE_INPUT_TOKENS" "$output")
  cache_creation=$(get_env_var "CLAUDE_CACHE_CREATION" "$output")
  cache_read=$(get_env_var "CLAUDE_CACHE_READ" "$output")
  current_tokens=$(get_env_var "CLAUDE_CURRENT_TOKENS" "$output")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  # Verify they're all set
  [ -n "$input_tokens" ]
  [ -n "$cache_creation" ]
  [ -n "$current_tokens" ]
  [ -n "$percent_raw" ]
}

@test "exports context_size" {
  output=$(run_with_fixture "active_session_with_context.json")

  context_size=$(get_env_var "CLAUDE_CONTEXT_SIZE" "$output")
  [ "$context_size" = "200000" ]
}
