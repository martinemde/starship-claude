# starship-claude Test Suite

This directory contains tests for starship-claude, organized into two complementary approaches:

## Test Philosophy

### 1. Implementation Tests (Unit/Integration Tests)

These tests verify the **internal behavior** and implementation details:

- **What they test**: "Does this env var get set?" "Is this value calculated correctly?"
- **Files**:
  - `context_calculation.bats` - Context window percentage calculation
  - `cost_formatting.bats` - Cost formatting logic (< $0.01, $X.XX)
  - `model_extraction.bats` - Model name parsing and icon selection
  - `progress_bar.bats` - OSC 9;4 progress bar output
  - `session_id.bats` - Session ID extraction
  - `integration.bats` - End-to-end pipeline tests

**Example**: Testing that `CLAUDE_COST` is set to "< $0.01" when `total_cost_usd` is 0.005

### 2. Conformance Tests (Black-Box Tests)

These tests verify the **external behavior** and observable output:

- **What they test**: "Does the final prompt look correct?" "Does this config produce the expected output?"
- **File**: `conformance.bats`
- **Philosophy**: Test from the outside, like a user would experience it

**Example**: Instead of checking if a config file contains specific TOML syntax, verify that when you run `configure.sh --write` and then use that config, you get the expected prompt output.

## Key Differences

| Aspect | Implementation Tests | Conformance Tests |
|--------|---------------------|-------------------|
| **Focus** | How it works internally | What the user sees |
| **Checks** | Env vars, calculations, parsing | Final prompt output |
| **Fragility** | Breaks on refactoring | Resilient to refactoring |
| **Purpose** | Verify correctness of logic | Verify user experience |
| **Example** | "Is CLAUDE_COST formatted?" | "Does the prompt show the cost?" |

## Conformance Test Categories

### Basic Format Tests
Verify that each style (minimal, bubbles, powerline) generates valid output with all required elements.

### Golden File Tests
Test specific known configurations against expected outputs. These serve as regression tests for exact behavior.

### Boundary Tests
Test edge cases like:
- Very low costs (< $0.01)
- Zero context usage
- High context usage (>= 80%)
- Cost formatting at exact boundaries ($0.01 vs $0.009)

### Regression Tests
Prevent specific bugs from reoccurring:
- Config files don't contain test artifacts
- All templates use the custom palette
- Default and custom paths produce identical output

### Cross-Cutting Tests
Test combinations of options:
- All styles work with all palettes
- Preview output matches written config output

## Running Tests

```bash
# Run all tests
bats test/*.bats

# Run specific test suite
bats test/conformance.bats
bats test/integration.bats

# Run specific test
bats test/conformance.bats -f "golden"

# Verbose output
bats test/conformance.bats --trace
```

## Writing New Tests

### When to use Implementation Tests
- Testing specific calculations or parsing logic
- Verifying environment variable handling
- Testing error conditions and edge cases in code
- When you need to verify internal state

### When to use Conformance Tests
- Testing complete user workflows
- Verifying visual output (prompts, formatting)
- Regression testing for user-facing behavior
- When refactoring implementation but keeping same output

### Golden File Pattern

Golden file tests compare actual prompt output against stored expected outputs:

```bash
@test "conformance: description of scenario" {
  # 1. Generate config with specific options
  local config="${TEST_TEMP_DIR}/test.toml"
  run_configure --style minimal --palette nord --write "$config" >/dev/null 2>&1

  # 2. Get actual output using a fixture
  output=$(get_prompt_from_config_with_fixture "$config" "high_cost.json")

  # 3. Compare against golden file
  assert_golden_match "minimal-nord-high-cost" "$output"
}
```

## Working with Golden Files

Golden files are stored in `test/golden/` and contain the exact expected output from starship prompts, including ANSI color codes.

### Running Conformance Tests

```bash
# Run all conformance tests
bats test/conformance.bats

# Run tests matching a pattern
bats test/conformance.bats -f "minimal"
bats test/conformance.bats -f "bubbles"

# Verbose output
bats test/conformance.bats --trace
```

### Updating Golden Files

When you change prompt output intentionally, update the golden files:

```bash
# Update all golden files
BATS_UPDATE_GOLDEN=1 bats test/conformance.bats

# Update specific tests matching a pattern
BATS_UPDATE_GOLDEN=1 bats test/conformance.bats -f "minimal"

# Review what changed
git diff test/golden/
```

### Reviewing Golden Files

Use the review script to visualize and manage golden files:

```bash
# List all golden files with previews
test/review-golden.sh list

# Show a specific golden file with colors rendered
test/review-golden.sh show minimal-text-mocha-high-cost

# Show all golden files with colors rendered (requires Nerd Font in terminal)
test/review-golden.sh show-all

# Show only golden files matching a pattern
test/review-golden.sh show-all bubbles
test/review-golden.sh show-all minimal
test/review-golden.sh show-all nord

# Show what would change if you updated
test/review-golden.sh diff

# Update all golden files
test/review-golden.sh update

# Update specific golden files
test/review-golden.sh update bubbles
```

**Note:** To see nerd font glyphs properly rendered (bubbles, powerline styles), your terminal must use a [Nerd Font](https://www.nerdfonts.com/). Without one, you'll see `<U+E0B6>` style placeholders, but the tests will still work correctly.

### Golden File Workflow

1. **Make changes** to prompt generation code
2. **Run tests** to see failures: `bats test/conformance.bats`
3. **Review changes** visually: `test/review-golden.sh diff`
4. **Accept changes** if correct: `BATS_UPDATE_GOLDEN=1 bats test/conformance.bats`
5. **Review golden files** visually: `test/review-golden.sh show <name>`
6. **Commit golden files** with your code changes

### Creating New Golden Tests

1. Add a new test in `test/conformance.bats`
2. Run with `BATS_UPDATE_GOLDEN=1` to create the golden file
3. Review the golden file visually: `test/review-golden.sh show <name>`
4. Commit the test and golden file together

## Test Helpers

Shared helpers are in `test_helper.bash`:

- `setup()` / `teardown()` - Test lifecycle
- `run_with_fixture(name)` - Run with JSON fixture file
- `get_env_var(name, output)` - Extract env var from output
- `assert_env_equals(name, expected, output)` - Assert env var value
- `assert_env_set(name, output)` - Assert env var is set
- `assert_env_empty(name, output)` - Assert env var is empty

Conformance-specific helpers in `conformance.bats`:

- `run_configure(args...)` - Run configure.sh with args
- `get_prompt_from_config(config, [json])` - Get prompt output from config

## Fixtures

Test fixtures are in `test/fixtures/`:

- `active_session_with_context.json` - Complete session data
- `context_40_percent.json` - 40% context usage
- `context_50_percent.json` - 50% context usage
- `context_65_percent.json` - 65% context usage
- `context_85_percent.json` - 85% context usage
- `high_cost.json` - High cost session
- `low_cost_session.json` - Low cost session
- `medium_cost.json` - Medium cost session
- `zero_cost.json` - Zero cost session
- `session_without_current_usage.json` - No context data

## CI Integration

Tests are designed to run in CI environments:

- Use temporary directories (never write to real paths)
- Use mock starship command (don't require starship installation)
- Clean up after themselves
- Use safe, fictional test data

## Future Enhancements

Potential additions to the conformance tests:

1. **Real Starship Integration**: Optionally use real starship binary if available for even more accurate testing
2. **Visual Regression**: Capture actual ANSI color codes and compare against golden snapshots
3. **Performance Tests**: Measure prompt generation time
4. **Fuzzing**: Generate random valid JSON to test edge cases
