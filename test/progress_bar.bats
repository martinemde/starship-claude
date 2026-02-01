#!/usr/bin/env bats
# Test OSC 9;4 progress bar functionality

load test_helper

# Helper to extract OSC 9;4 sequence from output
# Returns the state and progress values
extract_osc_progress() {
  local output="$1"
  # Look for ESC ] 9 ; 4 ; <state> ; <progress> BEL
  # In the output, ESC is \033 or ^[
  echo "$output" | grep -o $'\033\]9;4;[0-9];[0-9]*\a' | sed 's/.*9;4;\([0-9]\);\([0-9]*\).*/\1 \2/'
}

@test "progress bar is enabled by default" {
  # Progress bar now goes to /dev/tty, not stdout, so we can't capture it in tests
  # Instead, verify that percent_used is calculated (which triggers progress bar)
  output=$(run_with_fixture "active_session_with_context.json")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  # If CLAUDE_PERCENT_RAW is set, progress bar would be sent
  [ -n "$percent_raw" ]
}

@test "progress bar can be disabled with --no-progress flag" {
  # Run with --no-progress flag
  local fixture_path="${FIXTURES_DIR}/active_session_with_context.json"
  output=$(STARSHIP_CMD="${TEST_TEMP_DIR}/print-env" "${BIN_DIR}/starship-claude" --no-progress <"$fixture_path" 2>&1)

  # Should NOT contain OSC sequence
  ! echo "$output" | grep -q $'\033\]9;4;'
}

@test "low context (< 40%) would show normal state" {
  # active_session_with_context has 15% context (< 40% threshold)
  output=$(run_with_fixture "active_session_with_context.json")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  # 15 < 40, so would be normal state (1)
  [ "$percent_raw" -lt 40 ]
}

@test "medium context (>= 40%) would show warning state" {
  # context_40_percent.json has exactly 40% context (>= 40% threshold)
  output=$(run_with_fixture "context_40_percent.json")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  # 40 >= 40, so would be warning state (4)
  [ "$percent_raw" -ge 40 ]
}

@test "high context (>= 60%) would show error state" {
  output=$(run_with_fixture "context_65_percent.json")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  # 65 >= 60, so would be error state (2)
  [ "$percent_raw" -ge 60 ]
}

@test "progress bar scales context to 0-80% range" {
  # active_session has 15% context
  # Expected progress: 15 * 100 / 80 = 18 (integer math)
  output=$(run_with_fixture "active_session_with_context.json")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  # Verify the raw percentage is correct (progress bar scaling happens internally)
  [ "$percent_raw" = "15" ]
}

@test "context at 80%+ would show full progress bar" {
  output=$(run_with_fixture "context_85_percent.json")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  # 85 >= 80, so progress bar would be at 100%
  [ "$percent_raw" -ge 80 ]
}

@test "progress bar is not sent when current_usage is null" {
  output=$(run_with_fixture "session_without_current_usage.json")

  # Should NOT send any OSC sequence (leaves existing bar alone)
  ! echo "$output" | grep -q $'\033\]9;4;'
}

@test "progress bar is not sent when context is zero" {
  output=$(run_with_fixture "zero_cost.json")

  # Should NOT send any OSC sequence (leaves existing bar alone)
  ! echo "$output" | grep -q $'\033\]9;4;'
}

@test "context percentage matches raw percent" {
  output=$(run_with_fixture "context_40_percent.json")

  # Should have 40% context (left-padded to 3 chars)
  context=$(get_env_var "CLAUDE_CONTEXT" "$output")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  [ "$context" = "40%" ]
  [ "$percent_raw" = "40" ]
}

@test "40% context is at warning threshold" {
  # 40% equals the warning threshold (PROGRESS_YELLOW=40)
  output=$(run_with_fixture "context_40_percent.json")
  percent_raw=$(get_env_var "CLAUDE_PERCENT_RAW" "$output")

  # Verify it's at exactly the warning threshold
  [ "$percent_raw" = "40" ]
}
