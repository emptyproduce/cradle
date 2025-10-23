#!/usr/bin/env bash
# ---
# @file_name: jade.sh
# @version: 1.3.1
# @description: Lazy script for modifying docker files
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
# @description: Load the jade configuration file.
# @return_code: [2] Unable to source.
# shellcheck source=/usr/local/etc/jade.sh/jade.conf
# shellcheck disable=2015
# ---
setup() {
  declare -r conf="/usr/local/etc/jade.sh/jade.conf"
  [[ -f "${conf}" ]] && . "${conf}" || error 2 "unable to source '${conf}'"
}

# ---
# @description: Download a remote file to the local path.
# @global: REMOTE_HOST - The remote host to connect to.
# @global: REMOTE_PATH - The path to the file on the remote host.
# @global: LOCAL_PATH - The local path to save the file to.
# @return_code: [3] Download failed.
# ---
download_file() {
  scp -q "${REMOTE_HOST}:${REMOTE_PATH}" "$LOCAL_PATH" || error 3 'Download failed'
  info "Downloaded: $LOCAL_PATH"
}

# ---
# @description: Upload a local file to the remote host, backing up the remote file first.
# @global: REMOTE_HOST - The remote host to connect to.
# @global: REMOTE_PATH - The path to the file on the remote host.
# @global: LOCAL_PATH - The local path of the file to upload.
# @return_code: [4] Local file missing.
# @return_code: [5] Failed to create remote backup.
# @return_code: [6] Upload failed.
# ---
upload_file() {
  [[ -f "$LOCAL_PATH" ]] || error 4 "Local file missing: $LOCAL_PATH"
  ssh -q "${REMOTE_HOST}" "[[ -f '${REMOTE_PATH}' ]] && cp -f '${REMOTE_PATH}' '${REMOTE_PATH}.bak'" || error 5 'Failed to create remote backup'
  scp -q "$LOCAL_PATH" "${REMOTE_HOST}:${REMOTE_PATH}" || error 6 'Upload failed'
  info "Uploaded: $LOCAL_PATH"
  info "Remote file backed up to: ${REMOTE_PATH}.bak"
}

# ---
# @description: Download a file and open it in the configured editor.
# @global: REMOTE_HOST - The remote host to connect to.
# @global: REMOTE_PATH - The path to the file on the remote host.
# @global: LOCAL_PATH - The local path to save the file to.
# @global: EDITOR - The editor command to use.
# @return_code: [7] Editor command not found.
# @return_code: [3] Download failed (inherited from download_file).
# ---
edit_file() {
  download_file
  if ! command -v "$EDITOR" >/dev/null; then
    error 7 "Editor not found: '$EDITOR'"
  fi
  "$EDITOR" "$LOCAL_PATH"
}

# ---
# @description: Upload a file and run 'docker compose up -d' on the remote host.
# @global: REMOTE_HOST - The remote host to connect to.
# @global: REMOTE_PATH - The path to the docker-compose.yml file on the remote host.
# @return_code: [6] Upload failed (inherited from upload_file).
# @return_code: [8] Remote docker compose up failed.
# ---
upload_compose() {
  upload_file
  ssh -q "${REMOTE_HOST}" \
    "cd '$(dirname "$REMOTE_PATH")' && exec docker compose up -d" \
    || error 8 'Remote docker compose up failed'
  info 'Remote docker compose up -d completed'
}

# ---
# @description: Run 'docker compose down', upload a file, then run 'docker compose up -d' on the remote host.
# @global: REMOTE_HOST - The remote host to connect to.
# @global: REMOTE_PATH - The path to the docker-compose.yml file on the remote host.
# @return_code: [9] Remote docker compose down failed.
# @return_code: [6] Upload failed (inherited from upload_file).
# @return_code: [11] Remote docker compose up failed during restart.
# ---
upload_restart() {
  ssh -q "${REMOTE_HOST}" \
    "cd '$(dirname "$REMOTE_PATH")' && exec docker compose down" \
    || error 9 'Remote docker compose down failed'
  upload_file
  ssh -q "${REMOTE_HOST}" \
    "cd '$(dirname "$REMOTE_PATH")' && exec docker compose up -d" \
    || error 11 'Remote docker compose up failed during restart'
  info 'Remote docker compose restart completed'
}

# ---
# @description: Parse command-line flags and execute the chosen mode.
# @arg: $@ - Command-line arguments.
# @return_code: [2] Configuration file not found (inherited from setup).
# @return_code: [10] Unknown command-line option.
# @return_code: [12] Required tool 'scp' not found.
# @return_code: [13] Required tool 'ssh' not found.
# @return_code: [14] Unexpected execution mode.
# @return_code: [N] Errors from called functions (e.g., download_file, upload_file, etc.).
# ---
main() {
  setup
  declare mode=''
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d) mode='download' ; shift ;;
      -u) mode='upload'   ; shift ;;
      -uc) mode='up'      ; shift ;;
      -ur) mode='restart' ; shift ;;
      *) error 10 "Unknown option: $1 (use -d, -u, -uc, -ur)" ;;
    esac
  done

  command -v scp >/dev/null || error 12 "'scp' not found"
  command -v ssh >/dev/null || error 13 "'ssh' not found"

  case "$mode" in
    download) download_file ;;
    upload)   upload_file ;;
    up)       upload_compose ;;
    restart)  upload_restart ;;
    '')       edit_file ;;
    *)        error 14 "Unexpected mode: $mode" ;;
  esac
}

main "$@"