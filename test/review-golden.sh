#!/usr/bin/env bash
#
# review-golden.sh - Review and manage golden test files
#
# Usage:
#   test/review-golden.sh list              # List all golden files
#   test/review-golden.sh show <name>       # Show a specific golden file with colors
#   test/review-golden.sh update            # Update all golden files
#   test/review-golden.sh update <pattern>  # Update golden files matching pattern
#   test/review-golden.sh diff              # Show what would change if updated
#

set -o errexit
set -o nounset
set -o pipefail

# Script location and derived paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly GOLDEN_DIR="${PROJECT_ROOT}/test/golden"

show_help() {
  cat <<'EOF'
Usage: test/review-golden.sh <command> [options]

Commands:
  list                  List all golden files with preview
  show <name>           Show a specific golden file with ANSI colors rendered
  show-all [pattern]    Show all golden files with ANSI colors rendered
  update [pattern]      Update golden files (all or matching pattern)
  diff [pattern]        Show what would change if golden files were updated
  help                  Show this help message

Examples:
  test/review-golden.sh list
  test/review-golden.sh show minimal-text-mocha-high-cost
  test/review-golden.sh show-all
  test/review-golden.sh show-all bubbles
  test/review-golden.sh update
  test/review-golden.sh update minimal
  test/review-golden.sh diff bubbles

Environment:
  Set BATS_UPDATE_GOLDEN=1 when running bats to update golden files during tests
EOF
}

# List all golden files with a preview
cmd_list() {
  if [ ! -d "$GOLDEN_DIR" ]; then
    echo "No golden files found (directory doesn't exist: $GOLDEN_DIR)"
    return 0
  fi

  local golden_files
  golden_files=$(find "$GOLDEN_DIR" -name "*.txt" -type f | sort)

  if [ -z "$golden_files" ]; then
    echo "No golden files found in: $GOLDEN_DIR"
    return 0
  fi

  echo "=== Golden Files ==="
  echo ""

  while IFS= read -r file; do
    local name
    name=$(basename "$file" .txt)

    printf "📄 %s\n" "$name"
    printf "   "
    # Show first line with ANSI codes rendered
    head -n 1 "$file" | cat -v
    printf "\n\n"
  done <<< "$golden_files"
}

# Show a specific golden file with colors
cmd_show() {
  local name="$1"
  local golden_file="${GOLDEN_DIR}/${name}.txt"

  if [ ! -f "$golden_file" ]; then
    # Try without .txt extension
    golden_file="${GOLDEN_DIR}/${name}"
    if [ ! -f "$golden_file" ]; then
      echo "Error: Golden file not found: ${name}" >&2
      echo "Available files:" >&2
      cmd_list
      return 1
    fi
  fi

  echo "=== Golden file: $(basename "$golden_file" .txt) ==="
  echo ""

  # Display with ANSI colors using cat (which preserves escape sequences in terminals)
  cat "$golden_file"
  echo ""
}

# Show all golden files with colors
cmd_show_all() {
  local pattern="${1:-}"

  if [ ! -d "$GOLDEN_DIR" ]; then
    echo "No golden files found (directory doesn't exist: $GOLDEN_DIR)"
    return 0
  fi

  local golden_files
  if [ -n "$pattern" ]; then
    golden_files=$(find "$GOLDEN_DIR" -name "*${pattern}*.txt" -type f | sort)
  else
    golden_files=$(find "$GOLDEN_DIR" -name "*.txt" -type f | sort)
  fi

  if [ -z "$golden_files" ]; then
    if [ -n "$pattern" ]; then
      echo "No golden files found matching pattern: $pattern"
    else
      echo "No golden files found in: $GOLDEN_DIR"
    fi
    return 0
  fi

  while IFS= read -r file; do
    local name
    name=$(basename "$file" .txt)

    echo "=== ${name} ==="
    cat "$file"
    echo ""
  done <<< "$golden_files"
}

# Update golden files
cmd_update() {
  local pattern="${1:-}"

  echo "Updating golden files..."
  echo ""

  if [ -n "$pattern" ]; then
    echo "Pattern: *${pattern}*"
    BATS_UPDATE_GOLDEN=1 bats "${SCRIPT_DIR}/conformance.bats" -f "$pattern"
  else
    echo "Updating all golden files"
    BATS_UPDATE_GOLDEN=1 bats "${SCRIPT_DIR}/conformance.bats"
  fi

  echo ""
  echo "✓ Golden files updated"
  echo ""
  echo "Review changes with: git diff test/golden/"
}

# Show diff of what would change
cmd_diff() {
  local pattern="${1:-}"

  # Create a temporary directory for new golden files
  local tmp_golden_dir
  tmp_golden_dir=$(mktemp -d)

  # Save original GOLDEN_DIR
  local original_golden_dir="${GOLDEN_DIR}"

  # Temporarily point to new directory and run tests
  echo "Generating new golden files in temp directory..."

  # We need to modify the helper to use a different directory
  # For now, run update and then git diff

  if [ -n "$pattern" ]; then
    echo "Pattern: *${pattern}*"
    BATS_UPDATE_GOLDEN=1 bats "${SCRIPT_DIR}/conformance.bats" -f "$pattern" --no-tempdir-cleanup 2>/dev/null || true
  else
    BATS_UPDATE_GOLDEN=1 bats "${SCRIPT_DIR}/conformance.bats" --no-tempdir-cleanup 2>/dev/null || true
  fi

  echo ""
  echo "=== Changes that would be made ==="
  echo ""

  # Show git diff for golden directory
  git -C "$PROJECT_ROOT" diff --color=always test/golden/ || echo "No changes"

  echo ""
  echo "To accept these changes, run:"
  echo "  git add test/golden/"
}

# Main command dispatcher
main() {
  local cmd="${1:-help}"

  case "$cmd" in
  list)
    cmd_list
    ;;
  show)
    if [ -z "${2:-}" ]; then
      echo "Error: 'show' command requires a golden file name" >&2
      echo "Usage: test/review-golden.sh show <name>" >&2
      exit 1
    fi
    cmd_show "$2"
    ;;
  show-all)
    cmd_show_all "${2:-}"
    ;;
  update)
    cmd_update "${2:-}"
    ;;
  diff)
    cmd_diff "${2:-}"
    ;;
  help | --help | -h)
    show_help
    ;;
  *)
    echo "Error: Unknown command: $cmd" >&2
    echo "" >&2
    show_help
    exit 1
    ;;
  esac
}

main "$@"
