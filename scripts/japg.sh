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
WORD_LIST='/usr/share/dict/japg.list'
DEFAULT_WORDS=5
DEFAULT_DELIM='-'
error() { printf 'Error: %s\n' "$*" >&2; exit 1; }
info()  { printf '%s\n' "$*"; }

# ---
# Description: Main routine.
# Globals: WORD_LIST, DEFAULT_WORDS, DEFAULT_DELIM
# ---
main() {
    local num_words=${1:-$DEFAULT_WORDS}
    local delim=${2:-$DEFAULT_DELIM}

    [[ "$num_words" =~ ^[1-9][0-9]*$ ]] || error "num_words must be a positive integer"
    [[ -f "$WORD_LIST" ]]              || error "Word-list not found: $WORD_LIST"
    command -v xclip >/dev/null        || error "xclip not found (install xclip)"

    # 1. Pick words
    local -a words
    mapfile -t words < <(shuf -n "$num_words" "$WORD_LIST")

    # 2. Capitalise every word
    local i
    for i in "${!words[@]}"; do
        words[i]=$(printf '%s' "${words[i]}" | sed 's/^\(.\)/\U\1/')
    done

    # 3. Append digit to one random word
    local dig_idx=$(( RANDOM % num_words ))
    words[dig_idx]+=$(( RANDOM % 10 ))

    # 4. Join with delimiter
    local pass
    pass=$(IFS="$delim"; printf '%s' "${words[*]}")

    # 5. Copy and report
    printf '%s' "$pass" | xclip -selection clipboard
    info "Generated password: $pass"
    info "Password copied to clipboard."
}

main "$@"
