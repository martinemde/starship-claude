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

  # Create isolated git repo with deterministic state so Starship's
  # git_branch and git_status modules produce consistent output regardless
  # of the real repository's current state.
  export TEST_GIT_REPO="${TEST_TEMP_DIR}/test-project"
  mkdir -p "$TEST_GIT_REPO"
  git -C "$TEST_GIT_REPO" init -b main --quiet
  git -C "$TEST_GIT_REPO" config user.email "test@example.com"
  git -C "$TEST_GIT_REPO" config user.name "Test"
  echo "test" > "$TEST_GIT_REPO/file.txt"
  git -C "$TEST_GIT_REPO" add .
  git -C "$TEST_GIT_REPO" commit -m "Initial commit" --quiet

  # Create env printer script for all tests
  local env_printer="${TEST_TEMP_DIR}/print-env"
  cat >"$env_printer" <<'EOF'
#!/usr/bin/env bash
# Print relevant env vars for testing

# Formatted/computed values
printf "CLAUDE_MODEL=%s\n" "${CLAUDE_MODEL:-}"
printf "CLAUDE_MODEL_NERD=%s\n" "${CLAUDE_MODEL_NERD:-}"
printf "CLAUDE_COST=%s\n" "${CLAUDE_COST:-}"
printf "CLAUDE_CONTEXT=%s\n" "${CLAUDE_CONTEXT:-}"
printf "CLAUDE_SUMMARY=%s\n" "${CLAUDE_SUMMARY:-}"
printf "CLAUDE_CURRENT_TOKENS=%s\n" "${CLAUDE_CURRENT_TOKENS:-}"
printf "CLAUDE_PERCENT_RAW=%s\n" "${CLAUDE_PERCENT_RAW:-}"

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
  sed "s|FIXTURES_DIR|${FIXTURES_DIR}|g" "$fixture_path" >"$processed_fixture"

  # Run starship-claude with our env printer (created in setup)
  # Capture full output including OSC sequences
  STARSHIP_CMD="${TEST_TEMP_DIR}/print-env" "${BIN_DIR}/starship-claude" <"$processed_fixture" 2>&1
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

# ============================================================================
# Golden File Testing Helpers
# ============================================================================

# Golden files directory
GOLDEN_DIR="${PROJECT_ROOT}/test/golden"

# Configure script path
CONFIGURE_SCRIPT="${PROJECT_ROOT}/plugin/bin/configure.sh"

# starship-claude binary
STARSHIP_CLAUDE_BIN="${PROJECT_ROOT}/starship-claude"

# Helper to run configure.sh with arguments
# Usage: run_configure [--style STYLE] [--palette PALETTE] [--nerdfont] [--write FILE]
# Runs inside the isolated test git repo so Starship picks up deterministic
# git state (branch: main, clean status, directory: test-project).
run_configure() {
  (cd "$TEST_GIT_REPO" && "${CONFIGURE_SCRIPT}" "$@")
}

# Helper to get prompt output from a specific config and JSON input
# Usage: get_prompt_from_config <config_file> [json_input]
#   config_file: Path to starship.toml config
#   json_input: JSON string (default: use fixture from SAMPLE_JSON)
get_prompt_from_config() {
  local config_file="$1"
  local json_input="${2:-}"

  if [ -z "$json_input" ]; then
    # Use default sample JSON from configure.sh
    json_input='{"model":{"display_name":"Opus 4.5"},"cost":{"total_cost_usd":7.89},"context_window":{"context_window_size":200000,"current_usage":{"input_tokens":12000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}'
  fi

  # Rewrite workspace paths to point at isolated test repo
  json_input="$(printf '%s' "$json_input" | jq --arg dir "$TEST_GIT_REPO" \
    '.cwd = $dir | .workspace.current_dir = $dir | .workspace.project_dir = $dir')"

  # Run starship-claude with the config and JSON input
  printf '%s' "$json_input" | "${STARSHIP_CLAUDE_BIN}" --no-progress --config "$config_file"
}

# Helper to get prompt output from a fixture file
# Usage: get_prompt_from_config_with_fixture <config_file> <fixture_name>
get_prompt_from_config_with_fixture() {
  local config_file="$1"
  local fixture_name="$2"
  local fixture_path="${FIXTURES_DIR}/${fixture_name}"

  if [ ! -f "$fixture_path" ]; then
    echo "Fixture not found: $fixture_path" >&2
    return 1
  fi

  # Rewrite workspace paths to point at isolated test repo
  jq --arg dir "$TEST_GIT_REPO" \
    '.cwd = $dir | .workspace.current_dir = $dir | .workspace.project_dir = $dir' \
    "$fixture_path" \
    | "${STARSHIP_CLAUDE_BIN}" --no-progress --config "$config_file"
}

# Helper to get prompt output WITH progress bar sequences
# Usage: get_prompt_with_progress <config_file> <fixture_name>
get_prompt_with_progress() {
  local config_file="$1"
  local fixture_name="$2"
  local fixture_path="${FIXTURES_DIR}/${fixture_name}"

  if [ ! -f "$fixture_path" ]; then
    echo "Fixture not found: $fixture_path" >&2
    return 1
  fi

  # Rewrite workspace paths to point at isolated test repo
  # Run starship-claude WITHOUT --no-progress to capture OSC 9;4 sequences
  jq --arg dir "$TEST_GIT_REPO" \
    '.cwd = $dir | .workspace.current_dir = $dir | .workspace.project_dir = $dir' \
    "$fixture_path" \
    | "${STARSHIP_CLAUDE_BIN}" --config "$config_file"
}

# Helper to compare output against golden file
# Usage: assert_golden_match <golden_name> <actual_output>
#   golden_name: Name of golden file (without .txt extension)
#   actual_output: The actual output to compare
#
# Set BATS_UPDATE_GOLDEN=1 to update golden files instead of comparing
assert_golden_match() {
  local golden_name="$1"
  local actual_output="$2"
  local golden_file="${GOLDEN_DIR}/${golden_name}.txt"

  # Create golden directory if it doesn't exist
  mkdir -p "${GOLDEN_DIR}"

  # If UPDATE mode, write the golden file
  if [ "${BATS_UPDATE_GOLDEN:-0}" = "1" ]; then
    printf '%s' "$actual_output" >"$golden_file"
    echo "Updated golden file: $golden_file" >&2
    return 0
  fi

  # Compare mode: check if golden file exists
  if [ ! -f "$golden_file" ]; then
    echo "Golden file not found: $golden_file" >&2
    echo "Run with BATS_UPDATE_GOLDEN=1 to create it" >&2
    echo "Actual output:" >&2
    echo "$actual_output" >&2
    return 1
  fi

  # Compare actual output with golden file
  local expected
  expected="$(cat "$golden_file")"

  if [ "$actual_output" != "$expected" ]; then
    echo "Output does not match golden file: $golden_file" >&2
    echo "Expected:" >&2
    echo "$expected" >&2
    echo "Actual:" >&2
    echo "$actual_output" >&2
    echo "" >&2
    echo "To update golden file, run:" >&2
    echo "  BATS_UPDATE_GOLDEN=1 bats test/conformance.bats -f '$golden_name'" >&2
    return 1
  fi
}

# Helper to display prompt with colors for visual review
# Usage: show_prompt_colored <output>
show_prompt_colored() {
  local output="$1"

  # Use printf with -e to interpret ANSI escape sequences
  printf '%b\n' "$output"
}

# Helper to review a golden file visually
# Usage: review_golden <golden_name>
review_golden() {
  local golden_name="$1"
  local golden_file="${GOLDEN_DIR}/${golden_name}.txt"

  if [ ! -f "$golden_file" ]; then
    echo "Golden file not found: $golden_file" >&2
    return 1
  fi

  echo "=== Golden file: $golden_name ===" >&2
  show_prompt_colored "$(cat "$golden_file")"
}
