# BATS test helper for starship-claude tests

# Load bats support libraries
# If using bats-core with support libraries:
# load 'test_helper/bats-support/load'
# load 'test_helper/bats-assert/load'

# Project root directory
PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

# Paths
BIN_DIR="${PROJECT_ROOT}"
FIXTURES_DIR="${PROJECT_ROOT}/test/fixtures"

# Test helpers
setup() {
  # Set PATH to include bin directory
  export PATH="${BIN_DIR}:${PATH}"

  # Create temp directory for test output
  export TEST_TEMP_DIR="$(mktemp -d)"

  # Create env printer script for all tests
  local env_printer="${TEST_TEMP_DIR}/print-env"
  cat > "$env_printer" << 'EOF'
#!/usr/bin/env bash
# Print relevant env vars for testing

# Formatted/computed values
printf "CLAUDE_MODEL=%s\n" "${CLAUDE_MODEL:-}"
printf "CLAUDE_MODEL_NAME=%s\n" "${CLAUDE_MODEL_NAME:-}"
printf "CLAUDE_COST=%s\n" "${CLAUDE_COST:-}"
printf "CLAUDE_CONTEXT=%s\n" "${CLAUDE_CONTEXT:-}"
printf "CLAUDE_SUMMARY=%s\n" "${CLAUDE_SUMMARY:-}"
printf "CLAUDE_CURRENT_TOKENS=%s\n" "${CLAUDE_CURRENT_TOKENS:-}"
printf "CLAUDE_PERCENT_RAW=%s\n" "${CLAUDE_PERCENT_RAW:-}"
printf "CLAUDE_WORKTREE=%s\n" "${CLAUDE_WORKTREE:-}"

# Raw session/workspace values
printf "CLAUDE_SESSION_ID=%s\n" "${CLAUDE_SESSION_ID:-}"
printf "CLAUDE_TRANSCRIPT_PATH=%s\n" "${CLAUDE_TRANSCRIPT_PATH:-}"
printf "CLAUDE_CWD=%s\n" "${CLAUDE_CWD:-}"
printf "CLAUDE_WORKSPACE_CURRENT_DIR=%s\n" "${CLAUDE_WORKSPACE_CURRENT_DIR:-}"
printf "CLAUDE_WORKSPACE_PROJECT_DIR=%s\n" "${CLAUDE_WORKSPACE_PROJECT_DIR:-}"

# Raw version and style
printf "CLAUDE_VERSION=%s\n" "${CLAUDE_VERSION:-}"
printf "CLAUDE_OUTPUT_STYLE=%s\n" "${CLAUDE_OUTPUT_STYLE:-}"

# Raw model values
printf "CLAUDE_MODEL_ID=%s\n" "${CLAUDE_MODEL_ID:-}"
printf "CLAUDE_MODEL_DISPLAY_NAME=%s\n" "${CLAUDE_MODEL_DISPLAY_NAME:-}"

# Raw cost metrics
printf "CLAUDE_COST_RAW=%s\n" "${CLAUDE_COST_RAW:-}"
printf "CLAUDE_TOTAL_DURATION_MS=%s\n" "${CLAUDE_TOTAL_DURATION_MS:-}"
printf "CLAUDE_API_DURATION_MS=%s\n" "${CLAUDE_API_DURATION_MS:-}"
printf "CLAUDE_LINES_ADDED=%s\n" "${CLAUDE_LINES_ADDED:-}"
printf "CLAUDE_LINES_REMOVED=%s\n" "${CLAUDE_LINES_REMOVED:-}"

# Raw context window totals
printf "CLAUDE_TOTAL_INPUT_TOKENS=%s\n" "${CLAUDE_TOTAL_INPUT_TOKENS:-}"
printf "CLAUDE_TOTAL_OUTPUT_TOKENS=%s\n" "${CLAUDE_TOTAL_OUTPUT_TOKENS:-}"
printf "CLAUDE_CONTEXT_SIZE=%s\n" "${CLAUDE_CONTEXT_SIZE:-}"
printf "CLAUDE_EXCEEDS_200K=%s\n" "${CLAUDE_EXCEEDS_200K:-}"

# Raw current usage values
printf "CLAUDE_INPUT_TOKENS=%s\n" "${CLAUDE_INPUT_TOKENS:-}"
printf "CLAUDE_OUTPUT_TOKENS=%s\n" "${CLAUDE_OUTPUT_TOKENS:-}"
printf "CLAUDE_CACHE_CREATION=%s\n" "${CLAUDE_CACHE_CREATION:-}"
printf "CLAUDE_CACHE_READ=%s\n" "${CLAUDE_CACHE_READ:-}"

# Starship config
printf "STARSHIP_CONFIG=%s\n" "${STARSHIP_CONFIG:-}"
printf "STARSHIP_SHELL=%s\n" "${STARSHIP_SHELL:-}"
EOF
  chmod +x "$env_printer"
}

teardown() {
  # Clean up temp directory
  if [ -n "${TEST_TEMP_DIR:-}" ] && [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# Helper to run claude-statusline with a fixture and capture env vars
# Usage: run_with_fixture <fixture_name>
run_with_fixture() {
  local fixture_name="$1"
  local fixture_path="${FIXTURES_DIR}/${fixture_name}"

  if [ ! -f "$fixture_path" ]; then
    echo "Fixture not found: $fixture_path" >&2
    return 1
  fi

  # Substitute FIXTURES_DIR placeholder with actual path for transcript_path testing
  local processed_fixture="${TEST_TEMP_DIR}/processed_fixture.json"
  sed "s|FIXTURES_DIR|${FIXTURES_DIR}|g" "$fixture_path" > "$processed_fixture"

  # Run starship-claude with our env printer (created in setup)
  # Capture full output including OSC sequences
  STARSHIP_CMD="${TEST_TEMP_DIR}/print-env" "${BIN_DIR}/starship-claude" < "$processed_fixture" 2>&1
}

# Helper to extract a specific env var from captured output
# Usage: get_env_var <var_name> <captured_output>
get_env_var() {
  local var_name="$1"
  local output="$2"

  # Extract env var, handling OSC sequences that might be on same line
  echo "$output" | grep "${var_name}=" | sed 's/.*\('"${var_name}"'=.*\)/\1/' | cut -d= -f2-
}

# Helper to assert env var equals expected value
# Usage: assert_env_equals <var_name> <expected_value> <captured_output>
assert_env_equals() {
  local var_name="$1"
  local expected="$2"
  local output="$3"

  local actual
  actual="$(get_env_var "$var_name" "$output")"

  if [ "$actual" != "$expected" ]; then
    echo "Expected ${var_name}='${expected}' but got '${actual}'" >&2
    return 1
  fi
}

# Helper to assert env var is set (non-empty)
# Usage: assert_env_set <var_name> <captured_output>
assert_env_set() {
  local var_name="$1"
  local output="$2"

  local actual
  actual="$(get_env_var "$var_name" "$output")"

  if [ -z "$actual" ]; then
    echo "Expected ${var_name} to be set but it was empty" >&2
    return 1
  fi
}

# Helper to assert env var is empty or unset
# Usage: assert_env_empty <var_name> <captured_output>
assert_env_empty() {
  local var_name="$1"
  local output="$2"

  local actual
  actual="$(get_env_var "$var_name" "$output")"

  if [ -n "$actual" ]; then
    echo "Expected ${var_name} to be empty but got '${actual}'" >&2
    return 1
  fi
}
