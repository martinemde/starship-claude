#!/usr/bin/env bats
# Test cost formatting and display

load test_helper

@test "formats low cost with two decimals" {
  output=$(run_with_fixture "low_cost_session.json")
  cost=$(get_env_var "CLAUDE_COST" "$output")

  # Should be formatted as $X.XX
  [[ "$cost" =~ ^\$[0-9]+\.[0-9]{2}$ ]]
}

@test "formats medium cost correctly" {
  output=$(run_with_fixture "medium_cost.json")
  cost=$(get_env_var "CLAUDE_COST" "$output")

  # Should be formatted as $X.XX
  [[ "$cost" =~ ^\$[0-9]+\.[0-9]{2}$ ]]
}

@test "formats high cost correctly" {
  output=$(run_with_fixture "high_cost.json")
  cost=$(get_env_var "CLAUDE_COST" "$output")

  # Should be formatted as $X.XX
  [[ "$cost" =~ ^\$[0-9]+\.[0-9]{2}$ ]]
}

@test "handles zero cost" {
  output=$(run_with_fixture "zero_cost.json")
  cost=$(get_env_var "CLAUDE_COST" "$output")

  # Zero should format as $0.00
  [ "$cost" = "\$0.00" ] || [ -z "$cost" ]
}

@test "handles null cost gracefully" {
  # Create a minimal fixture without cost field
  echo '{"session_id":"test","model":{"display_name":"Sonnet 4.5"}}' > "${TEST_TEMP_DIR}/no_cost.json"

  output=$(STARSHIP_CMD="${TEST_TEMP_DIR}/print-env" "${BIN_DIR}/starship-claude" < "${TEST_TEMP_DIR}/no_cost.json")

  # CLAUDE_COST should be empty
  cost=$(get_env_var "CLAUDE_COST" "$output")
  [ -z "$cost" ]
}
