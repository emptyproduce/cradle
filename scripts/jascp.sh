#!/usr/bin/env bash
# ---
# @file_name: jascp.sh
# @version: 1.2.0
# @project_name: jascp (Just Another SCP)
# @description: Download-only, upload-only, or download-edit-upload helper.
# @author: Jamie Albert (empty_produce)
# @author_contact: <mailto:empty.produce@flatmail.me>
# @license: GNU Affero General Public License v3.0 (Included in LICENSE)
# Copyright (C) 2025, Jamie Albert
# ---
set -euo pipefail
REMOTE_HOST='root@hephaestus'
REMOTE_PATH='/home/oc/docker_config/compose.yml'
LOCAL_PATH='/tmp/compose.yml'
EDITOR="codium"
error() { printf 'Error: %s\n' "$*" >&2; exit 1; }
info()  { printf '%s\n' "$*"; }

# ---
# Description: Download remote file to local path.
# Globals: REMOTE_HOST, REMOTE_PATH, LOCAL_PATH
# ---
download_file() {
  scp -q "${REMOTE_HOST}:${REMOTE_PATH}" "$LOCAL_PATH" || error 'Download failed'
  info "Downloaded → $LOCAL_PATH"
}

# ---
# Description: Upload local file to remote host.
# Globals: REMOTE_HOST, REMOTE_PATH, LOCAL_PATH
# ---
upload_file() {
  [[ -f $LOCAL_PATH ]] || error "Local file missing: $LOCAL_PATH"
  scp -q "$LOCAL_PATH" "${REMOTE_HOST}:${REMOTE_PATH}" || error 'Upload failed'
  info "Uploaded ← $LOCAL_PATH"
}

# ---
# Description: Download, edit, then upload.
# Globals: REMOTE_HOST, REMOTE_PATH, LOCAL_PATH, EDITOR
# ---
edit_cycle() {
  download_file
  command -v "$EDITOR" >/dev/null || error "Editor '$EDITOR' not found"
  "$EDITOR" "$LOCAL_PATH"
}

# ---
# Description: Parse flags and run chosen mode.
# Return Code: 0 on success
# ---
main() {
  local mode=''
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d) mode='download'; shift ;;
      -u) mode='upload';   shift ;;
      *)  error "Unknown option: $1 (use -d or -u)" ;;
    esac
  done

  command -v scp >/dev/null || error 'scp not found'

  case "$mode" in
    download) download_file ;;
    upload)   upload_file ;;
    '')       edit_cycle ;;
    *)        error "Unexpected mode: $mode" ;;
}

main "$@"
