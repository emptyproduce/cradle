#!/usr/bin/env bash
# ---
# @file_name: jarm.sh
# @version: 1.0.0
# @description: Lazy script for mounting rclone
# @author: Jamie Albert (empty_produce)
# @author_contact: <mailto:empty.produce@flatmail.me>
# @license: GNU Affero General Public License v3.0 (Included in LICENSE)
# Copyright (C) 2025, Jamie Albert
# ---
set -euo pipefail

# ---
# @usage: error <exit_code> <message>
# @description: Print an error message to stderr and exit with a specific code.
# @arg: $1 - The exit code to use.
# @arg: $* - The error message to print.
# @return_code: [N] The specified exit code.
# ---
error() {
  declare error_msg exit_code="$1"
  shift
  printf -v error_msg 'error[%d]: %s\n' "$exit_code" "$*"
  printf '%s' "$error_msg" >&2
  exit "${exit_code}"
}

# ---
# @description: Print an informational message to stdout.
# @arg: $* - The message to print.
# ---
info() {
  declare info_msg
  printf -v info_msg '%s\n' "$*"
  printf '%s' "$info_msg"
}

# ---
# @description: Mount koofr_vault to location
# ---
rclone_mount_koofr() {
  info "Mounting koofr..."
  /usr/bin/rclone mount koofr: /home/jamie/dao/storage/koofr &
}

# ---
# @description: Mount koofr_vault to location
# ---
rclone_mount_koofr_vault() {
  info "Mounting vault..."
  /usr/bin/rclone mount koofr_vault: /home/jamie/dao/storage/vault &
}
# ---
# @description: main function call
# @return_code: [2] Failed to mount koofr to dir.
# @return_code: [3] Failed to mount vault to dir.

main() {
  rclone_mount_koofr || error 2 "Failed to mount koofr."
  rclone_mount_koofr_vault || error 3 "Failed to mount vault."
}

main "$@"