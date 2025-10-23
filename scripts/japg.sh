#!/usr/bin/env bash
# ---
# @file_name: japg.sh
# @version: 1.0.0
# @description: Generate a passphrase
# @author: Jamie Albert (empty_produce)
# @author_contact: <mailto:empty.produce@flatmail.me>
# @license: GNU Affero General Public License v3.0 (Included in LICENSE)
# Copyright (C) 2025, Jamie Albert
# ---
set -euo pipefail

declare -gr WORD_LIST='/usr/share/dict/japg.list'
declare -gr DEFAULT_DELIM='-'
declare -gi DEFAULT_WORDS=5

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
  printf 'error: %s\n' "$*" >&2
  exit "${exit_code}"
}

# ---
# @description: Print an informational message to stdout.
# @arg: $* - The message to print.
# ---
info() {
  printf '%s\n' "$*"
}

# ---
# @description: Perform initial setup checks.
#              Verifies the word list file exists and xclip is installed.
# @global: WORD_LIST - Path to the word list file.
# @return_code: [2] Word-list file not found.
# @return_code: [3] Required tool 'xclip' not found.
# ---
setup() {
  [[ -f "${WORD_LIST}" ]] || error 2 "Word-list not found: $WORD_LIST"
  command -v xclip >/dev/null || error 3 "xclip not found (install xclip)"
}

# ---
# @description: Main routine to generate and copy the passphrase.
# @arg: $1 - Number of words (optional, defaults to DEFAULT_WORDS).
# @arg: $2 - Delimiter (optional, defaults to DEFAULT_DELIM).
# @global: WORD_LIST - Path to the word list file.
# @global: DEFAULT_WORDS - Default number of words.
# @global: DEFAULT_DELIM - Default delimiter.
# @return_code: [1] General error (inherits from set -e).
# @return_code: [4] Invalid number of words provided.
# @return_code: [2] Word-list not found (inherited from setup).
# @return_code: [3] xclip not found (inherited from setup).
# ---
main() {
  setup

  declare num_words="${1:-$DEFAULT_WORDS}"
  declare delim="${2:-$DEFAULT_DELIM}"

  [[ "${num_words}" =~ ^[1-9][0-9]*$ ]] || error 4 "num_words must be a positive integer"

  declare -a words
  mapfile -t words < <(shuf -n "$num_words" "$WORD_LIST") || error 1 "Failed to read words from list"

  declare i
  for i in "${!words[@]}"; do
    words[i]="${words[i]^}"
  done

  declare dig_idx=$(( RANDOM % num_words ))
  words[dig_idx]+=$(( RANDOM % 10 ))

  declare pass
  IFS="$delim"
  printf -v pass '%s' "${words[*]}" || error 1 "Failed to construct passphrase"

  printf '%s' "$pass" | xclip -selection clipboard || error 1 "Failed to copy passphrase to clipboard"
  info "Generated password: $pass"
  info "Password copied to clipboard."
}

main "$@"
