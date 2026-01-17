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
  output=$(run_with_fixture "active_session_with_context.json")

  # Should contain OSC sequence (use grep since regex might not match in all contexts)
  echo "$output" | grep -q $'\033\]9;4;'
}

@test "progress bar can be disabled with --no-progress flag" {
  # Run with --no-progress flag
  local fixture_path="${FIXTURES_DIR}/active_session_with_context.json"
  output=$(STARSHIP_CMD="${TEST_TEMP_DIR}/print-env" "${BIN_DIR}/starship-claude" --no-progress <"$fixture_path" 2>&1)

  # Should NOT contain OSC sequence
  ! echo "$output" | grep -q $'\033\]9;4;'
}

@test "progress bar shows normal state (1) for low context (< 45%)" {
  # active_session_with_context has 15% context
  output=$(run_with_fixture "active_session_with_context.json")

  osc=$(extract_osc_progress "$output")
  state=$(echo "$osc" | awk '{print $1}')

  [ "$state" = "1" ] # Normal state
}

@test "progress bar shows warning state (4) for medium context (45-65%)" {
  # Create a fixture with ~50% context
  # We'll need to find or create one
  skip "Need fixture with 45-65% context"
}

@test "progress bar shows error state (2) for high context (> 65%)" {
  # Create a fixture with > 65% context
  skip "Need fixture with > 65% context"
}

@test "progress bar scales 0-80% context to 0-100% bar" {
  # active_session has 15% context
  # 15 * 100 / 80 = 18.75 -> 18 (integer math)
  output=$(run_with_fixture "active_session_with_context.json")

  osc=$(extract_osc_progress "$output")
  progress=$(echo "$osc" | awk '{print $2}')

  [ "$progress" = "18" ]
}

@test "progress bar shows 100% when context >= 80%" {
  # Need a fixture with >= 80% context
  skip "Need fixture with >= 80% context"
}

@test "progress bar clears (0;0) when current_usage is null" {
  output=$(run_with_fixture "session_without_current_usage.json")

  # Should send clear sequence (state 0, progress 0)
  osc=$(extract_osc_progress "$output")
  state=$(echo "$osc" | awk '{print $1}')
  progress=$(echo "$osc" | awk '{print $2}')

  [ "$state" = "0" ]
  [ "$progress" = "0" ]
}

@test "progress bar clears (0;0) when context is zero" {
  output=$(run_with_fixture "zero_cost.json")

  # Should send clear sequence (state 0, progress 0)
  osc=$(extract_osc_progress "$output")
  state=$(echo "$osc" | awk '{print $1}')
  progress=$(echo "$osc" | awk '{print $2}')

  [ "$state" = "0" ]
  [ "$progress" = "0" ]
}

@test "context percentage calculation matches progress bar logic" {
  output=$(run_with_fixture "context_40_percent.json")

  # Should have 40% context
  context=$(get_env_var "CLAUDE_CONTEXT" "$output")
  [ "$context" = "40%" ]

  # Progress should be 40 * 100 / 80 = 50
  osc=$(extract_osc_progress "$output")
  progress=$(echo "$osc" | awk '{print $2}')

  [ "$progress" = "50" ]
}

@test "40% context shows warning state" {
  # 40% is at the warning threshold (>= 40%), so should be warning (state 4)
  output=$(run_with_fixture "context_40_percent.json")

  osc=$(extract_osc_progress "$output")
  state=$(echo "$osc" | awk '{print $1}')

  [ "$state" = "4" ] # Warning state (40 >= 40)
}
