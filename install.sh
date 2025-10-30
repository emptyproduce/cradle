#!/usr/bin/env bash
# ---
# @file_name: install.sh
# @version: 1.0.0
# @description: Install local scripts
# @author: Jamie Albert (empty_produce)
# @author_contact: <mailto:empty.produce@flatmail.me>
# @license: GNU Affero General Public License v3.0 (Included in LICENSE)
# Copyright (C) 2025, Jamie Albert
# ---
# Requires: Bash 4.0+
set -euo pipefail

# Global configuration variables
declare -gr INSTALL_DIR="/usr/local/bin"
declare -gr SCRIPTS_DIR="scripts"
declare -gr CONFIG_DIR="config"
declare -gr DICT_DIR="dict"
declare -ga TOOLS=("japg.sh" "jade.sh" "jau.sh" "jarm.sh")
declare -gr JADE_CONFIG_DIR="/usr/local/etc/jade.sh"

# ---
# @usage: error <exit_code> <message>
# @description: Print an error message to stderr and exit with a specific code.
# @arg: $1 - The exit code to use.
# @arg: $* - The error message to print.
# @return_code: [N] The specified exit code.
# ---
error() {
  declare exit_code="$1"
  shift
  # Use printf -v for efficient string assignment (Bash 4+)
  declare error_msg
  # Include the exit code in the error message
  printf -v error_msg 'error[%d]: %s\n' "$exit_code" "$*"
  printf '%s' "$error_msg" >&2
  exit "${exit_code}"
}

# ---
# @description: Print an informational message to stdout.
# @arg: $* - The message to print.
# ---
info() {
  # Use printf -v for efficient string assignment (Bash 4+)
  declare info_msg
  printf -v info_msg '%s\n' "$*"
  printf '%s' "$info_msg"
}

# ---
# @description: Perform initial setup checks. Verifies required directories exist.
# @global: INSTALL_DIR - The target directory for installed scripts.
# @global: SCRIPTS_DIR - Path to the local scripts directory.
# @global: CONFIG_DIR - Path to the local config directory.
# @global: DICT_DIR - Path to the local dict directory.
# @return_code: [2] Scripts directory not found.
# @return_code: [3] Config directory not found.
# @return_code: [4] Dict directory not found.
# ---
setup() {
	[[ -d $INSTALL_DIR ]] || sudo mkdir -p "$INSTALL_DIR" || error 1 "Failed to create installation directory $INSTALL_DIR"
  [[ -d "${SCRIPTS_DIR}" ]] || error 2 "Scripts directory not found: ${SCRIPTS_DIR}"
  [[ -d "${CONFIG_DIR}" ]]  || error 3 "Config directory not found: ${CONFIG_DIR}"
  [[ -d "${DICT_DIR}" ]]    || error 4 "Dict directory not found: ${DICT_DIR}"
}

# ---
# @description: Copy a single tool and make it executable.
# @arg: $1 - The name of the tool/script to install.
# @global: INSTALL_DIR - The target directory for installed scripts.
# @global: SCRIPTS_DIR - The source directory for scripts.
# @global: CONFIG_DIR - The source directory for config files.
# @global: DICT_DIR - The source directory for dict files.
# @global: JADE_CONFIG_DIR - The target directory for jade.sh config.
# @return_code: [1] General error (inherits from set -e).
# @return_code: [5] Source file not found.
# @return_code: [6] Copy failed for the tool.
# @return_code: [7] chmod failed for the tool.
# @return_code: [8] Failed to create jade config directory.
# @return_code: [9] Failed to copy config for jade.sh.
# @return_code: [10] Config template not found for jade.sh.
# @return_code: [11] Copy failed for japg.list.
# ---
install_tool() {
  declare tool="$1"
  declare src_path
  src_path=$(realpath "${SCRIPTS_DIR}/${tool}")

  [[ -f $src_path ]] || error 5 "Source file not found: $tool"

  sudo cp "$src_path" "$INSTALL_DIR/" || error 6 "Copy failed for $tool"
  sudo chmod 755 "$INSTALL_DIR/$tool" || error 7 "chmod failed for $tool"
  info "Installed: $INSTALL_DIR/$tool"

  case ${tool} in
    japg.sh)
      declare dict_src="${DICT_DIR}/japg.list"
      if [[ -f "${dict_src}" ]]; then
        sudo cp -f "${dict_src}" /usr/share/dict/ || error 11 "Copy failed for japg.list"
        info "	[info]: Installed /usr/share/dict/japg.list"
      else
          info "	[warn]: Dict file not found at '${dict_src}', skipping installation of /usr/share/dict/japg.list"
      fi
      ;;
    jade.sh)
      declare jade_config_src="${CONFIG_DIR}/jade.conf"
      declare jade_config_dest="${JADE_CONFIG_DIR}/jade.conf"
      if [[ -f "${jade_config_src}" ]]; then
        if [[ ! -f "${jade_config_dest}" ]]; then
          sudo mkdir -p "${JADE_CONFIG_DIR}" || error 8 "Failed to create jade config directory"
          sudo cp -f "${jade_config_src}" "${jade_config_dest}" || error 9 "Failed to copy config for jade.sh"
          info "	Installed: ${jade_config_dest} - manually set variables within this file."
        else
           info "	[info]: ${jade_config_dest} already exists, not overwriting."
        fi
      else
        error 10 "	Config template not found: '${jade_config_src}'"
      fi
      ;;
     *) info "	[info]: No specific install steps for $tool" ;;
  esac
}

# ---
# @description: Main routine to install all specified tools.
# @arg: $@ - Command-line arguments (currently unused).
# @global: TOOLS - Array of tool names to install.
# @return_code: [N] Errors from called functions (e.g., setup, install_tool).
# ---
main() {
  setup 

  declare tool
  for tool in "${TOOLS[@]}"; do
    install_tool "$tool"
  done

  info "All tools installed successfully."
}

main "$@"