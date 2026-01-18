#!/usr/bin/env bash
#
# configure.sh - Generate starship-claude preview output with customizable options
#
# Usage: configure.sh [OPTIONS]
#
# Options:
#   --nerdfont              Use nerd font symbols (default: text only)
#   --palette PALETTE       Set color palette (catppuccin_mocha, catppuccin_frappe,
#                           dracula, gruvbox_dark, nord, solarized_dark)
#   --style STYLE           Choose style: minimal or bubbles (default: minimal)
#   --compare-styles        Show both minimal and bubbles styles
#   --all-palettes          Show all 6 color palettes in current style
#   --config CONFIG         Forward config path to starship-claude
#   --path PATH             Forward path to starship-claude
#   --write [FILE]          Write generated config to FILE (default: ~/.claude/starship.toml)
#   -h, --help              Show this help message
#

[[ -n "${DEBUG:-}" ]] && set -o xtrace
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

# Script location and derived paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Allow overriding plugin root for testing (default to parent of script dir)
PLUGIN_ROOT="${STARSHIP_CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
readonly PLUGIN_ROOT
readonly TEMPLATE_DIR="${PLUGIN_ROOT}/templates"
readonly STARSHIP_CLAUDE="${PLUGIN_ROOT}/bin/starship-claude"

# Available themes
readonly VALID_THEMES="catppuccin_mocha catppuccin_frappe dracula gruvbox_dark nord solarized_dark"

# Sample JSON for preview
readonly SAMPLE_JSON='{"model":{"display_name":"Sonnet 4"},"cost":{"total_cost_usd":0.05},"context_window":{"context_window_size":200000,"current_usage":{"input_tokens":10000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}'

# Default values
use_nerdfont=false
palette="catppuccin_mocha"
style="minimal"
config_passthrough=""
path_passthrough=""
write_file=""
compare_styles=false
all_palettes=false

show_help() {
  cat <<'EOF'
Usage: configure.sh [OPTIONS]

Generate starship-claude preview output with customizable options.

Options:
  --nerdfont              Use nerd font symbols (default: text only)
  --palette PALETTE       Set color palette. Available palettes:
                            catppuccin_mocha (default)
                            catppuccin_frappe
                            dracula
                            gruvbox_dark
                            nord
                            solarized_dark
  --style STYLE           Choose style: minimal (default) or bubbles
                          Note: bubbles style requires nerd fonts
  --compare-styles        Show both minimal and bubbles styles side by side
                          (automatically enables --nerdfont)
  --all-palettes          Show all available color palettes in current style
  --config CONFIG         Forward config path to starship-claude
  --path PATH             Forward path to starship-claude
  --write [FILE]          Write generated config to FILE (default: ~/.claude/starship.toml)
  -h, --help              Show this help message

Examples:
  configure.sh                           # Default minimal style with text symbols
  configure.sh --nerdfont                # Minimal style with nerd font symbols
  configure.sh --palette dracula         # Use Dracula color palette
  configure.sh --style bubbles --nerdfont
  configure.sh --compare-styles          # Show minimal vs bubbles
  configure.sh --all-palettes            # Show all 6 palettes
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

validate_palette() {
  local palette_to_check="$1"
  local valid_palette

  for valid_palette in ${VALID_THEMES}; do
    if [[ "${palette_to_check}" == "${valid_palette}" ]]; then
      return 0
    fi
  done

  die "Invalid palette '${palette_to_check}'. Valid palettes: ${VALID_THEMES}"
}

validate_style() {
  local style_to_check="$1"

  case "${style_to_check}" in
  minimal | bubbles)
    return 0
    ;;
  *)
    die "Invalid style '${style_to_check}'. Valid styles: minimal, bubbles"
    ;;
  esac
}

get_template_file() {
  local template_file

  case "${style}" in
  minimal)
    if [[ "${use_nerdfont}" == "true" ]]; then
      template_file="${TEMPLATE_DIR}/minimal-nerd.toml"
    else
      template_file="${TEMPLATE_DIR}/minimal-text.toml"
    fi
    ;;
  bubbles)
    template_file="${TEMPLATE_DIR}/bubbles-nerd.toml"
    ;;
  esac

  if [[ ! -f "${template_file}" ]]; then
    die "Template not found: ${template_file}"
  fi

  printf '%s' "${template_file}"
}

extract_palettes() {
  # Extract palette definitions from minimal-nerd.toml (starting from [palettes. line)
  local palette_source="${TEMPLATE_DIR}/minimal-nerd.toml"

  if [[ ! -f "${palette_source}" ]]; then
    die "Palette source not found: ${palette_source}"
  fi

  sed -n '/^\[palettes\./,$p' "${palette_source}"
}

create_temp_config() {
  local template_file="$1"
  local temp_file

  temp_file="$(mktemp)"

  # Read template and replace the palette line with the chosen palette
  sed "s/^palette = \"catppuccin_mocha\"/palette = \"${palette}\"/" \
    "${template_file}" >"${temp_file}"

  printf '%s' "${temp_file}"
}

cleanup() {
  if [[ -n "${temp_config:-}" && -f "${temp_config}" ]]; then
    rm -f "${temp_config}"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --nerdfont)
      use_nerdfont=true
      shift
      ;;
    --palette)
      if [[ -z "${2:-}" ]]; then
        die "Option $1 requires an argument"
      fi
      palette="$2"
      shift 2
      ;;
    --style)
      if [[ -z "${2:-}" ]]; then
        die "Option $1 requires an argument"
      fi
      style="$2"
      shift 2
      ;;
    --config)
      if [[ -z "${2:-}" ]]; then
        die "Option $1 requires an argument"
      fi
      config_passthrough="$2"
      shift 2
      ;;
    --path)
      if [[ -z "${2:-}" ]]; then
        die "Option $1 requires an argument"
      fi
      path_passthrough="$2"
      shift 2
      ;;
    --write)
      # Default to ~/.claude/starship.toml if no argument provided
      if [[ -n "${2:-}" && ! "${2}" =~ ^-- ]]; then
        write_file="$2"
        shift 2
      else
        write_file="~/.claude/starship.toml"
        shift
      fi
      ;;
    --compare-styles)
      compare_styles=true
      shift
      ;;
    --all-palettes)
      all_palettes=true
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      die "Unexpected argument: $1"
      ;;
    esac
  done
}

run_single_preview_internal() {
  local preview_style="$1"
  local preview_palette="$2"
  local template_file
  local temp_config_local
  local cmd_args=()

  # Validate inputs
  validate_palette "${preview_palette}"
  validate_style "${preview_style}"

  # Build command arguments
  cmd_args+=(--no-progress)

  if [[ -n "${path_passthrough}" ]]; then
    cmd_args+=(--path "${path_passthrough}")
  fi

  # Get appropriate template for this style
  local saved_style="${style}"
  style="${preview_style}"
  template_file="$(get_template_file)"
  style="${saved_style}"

  # Create temp config with palette applied
  local saved_palette="${palette}"
  palette="${preview_palette}"
  temp_config_local="$(create_temp_config "${template_file}")"
  palette="${saved_palette}"

  cmd_args+=(--config "${temp_config_local}")

  # Run starship-claude with sample JSON piped in
  printf '%s' "${SAMPLE_JSON}" | "${STARSHIP_CLAUDE}" "${cmd_args[@]}"

  # Clean up temp config
  rm -f "${temp_config_local}"
}

run_compare_styles() {
  printf 'MINIMAL:   '
  run_single_preview_internal "minimal" "${palette}"
  printf '\n'
  printf 'POWERLINE: '
  run_single_preview_internal "bubbles" "${palette}"
  printf '\n'
}

run_all_palettes() {
  local palettes=(catppuccin_mocha catppuccin_frappe dracula gruvbox_dark nord solarized_dark)
  local p

  for p in "${palettes[@]}"; do
    printf '%s:\n' "${p}"
    run_single_preview_internal "${style}" "${p}"
    printf '\n'
  done
}

run_preview() {
  local template_file
  local cmd_args=()

  # Check starship-claude binary exists
  if [[ ! -x "${STARSHIP_CLAUDE}" ]]; then
    die "starship-claude not found or not executable at: ${STARSHIP_CLAUDE}"
  fi

  # Handle comparison modes
  if [[ "${compare_styles}" == "true" ]]; then
    # Force nerd fonts for style comparison
    use_nerdfont=true
    run_compare_styles
    return 0
  fi

  if [[ "${all_palettes}" == "true" ]]; then
    run_all_palettes
    return 0
  fi

  # Build command arguments
  cmd_args+=(--no-progress)

  if [[ -n "${config_passthrough}" ]]; then
    # User provided their own config, use it directly
    cmd_args+=(--config "${config_passthrough}")
  else
    # Validate inputs and generate temp config
    validate_palette "${palette}"
    validate_style "${style}"

    # Get appropriate template
    template_file="$(get_template_file)"

    # Create temp config with theme applied
    temp_config="$(create_temp_config "${template_file}")"
    cmd_args+=(--config "${temp_config}")

    # Write config to file if requested
    if [[ -n "${write_file}" ]]; then
      local write_path
      write_path="${write_file/#\~/$HOME}"
      cp "${temp_config}" "${write_path}"
      printf 'Wrote config to: %s\n' "${write_path}" >&2
      return 0
    fi
  fi

  if [[ -n "${path_passthrough}" ]]; then
    cmd_args+=(--path "${path_passthrough}")
  fi

  # Run starship-claude with sample JSON piped in
  printf '%s' "${SAMPLE_JSON}" | "${STARSHIP_CLAUDE}" "${cmd_args[@]}"
  printf '\n'
}

main() {
  parse_args "$@"

  # Set up cleanup trap
  trap cleanup EXIT

  run_preview
}

main "$@"
