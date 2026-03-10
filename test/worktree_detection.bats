#!/usr/bin/env bats
# Tests for git worktree detection and caching

bats_require_minimum_version 1.5.0
load test_helper

@test "worktree: CLAUDE_WORKTREE is empty in normal repo" {
  output=$(run_with_fixture "active_session_with_context.json")
  assert_env_empty "CLAUDE_WORKTREE" "$output"
}

@test "worktree: cache directory is created" {
  run_with_fixture "active_session_with_context.json" >/dev/null 2>&1
  cache_dir="${TMPDIR:-/tmp}/starship-claude-cache"
  [ -d "$cache_dir" ]
}

@test "worktree: cache file is created for current directory" {
  run_with_fixture "active_session_with_context.json" >/dev/null 2>&1
  cache_dir="${TMPDIR:-/tmp}/starship-claude-cache"
  # At least one cache file should exist
  [ -n "$(ls "$cache_dir"/wt_* 2>/dev/null)" ]
}
