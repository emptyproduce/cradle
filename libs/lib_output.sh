#!/usr/bin/env bash
# ---
# @file_name: jalibs.sh
# @version: 1.0.0
# @description: lib files
# @author: Jamie Albert (empty_produce)
# @author_contact: <mailto:empty.produce@flatmail.me>
# @license: GNU Affero General Public License v3.0 (Included in LICENSE)
# Copyright (C) 2025, Jamie Albert
# ---
set -euo pipefail

# ---
# Output
# ---

text::error() {
  declare error_msg exit_code="$1"
  shift
  printf -v error_msg 'error[%d]: %s\n' "$exit_code" "$*"
  printf '%s' "$error_msg" >&2
  exit "${exit_code}"
}

text::info() {
  declare info_msg
  printf -v info_msg '%s\n' "$*"
  printf '%s' "$info_msg"
}
