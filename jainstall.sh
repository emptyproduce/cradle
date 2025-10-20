#!/usr/bin/env bash
# ---
# @file_name: jainstall.sh
# @version: 1.0.0
# @description: Install local scripts
# @author: Jamie Albert (empty_produce)
# @author_contact: <mailto:empty.produce@flatmail.me>
# @license: GNU Affero General Public License v3.0 (Included in LICENSE)
# Copyright (C) 2025, Jamie Albert
# ---
set -euo pipefail
INSTALL_DIR='/usr/local/bin'
TOOLS=(japg.sh jascp.sh jau.sh) 
error() { printf 'Error: %s\n' "$*" >&2; exit 1; }
info()  { printf '%s\n' "$*"; }

# ---
# Description: Copy a single tool and make it executable.
# Globals: INSTALL_DIR, SCRIPT_DIR
# ---
install_tool() {
    local tool=$1
    local src_path
    src_path=$(realpath "scripts/${tool}")

    [[ -f $src_path ]] || error "Source file not found: $tool"

    sudo cp "$src_path" "$INSTALL_DIR/" || error "Copy failed for $tool"
    sudo chmod 755 "$INSTALL_DIR/$tool" || error "chmod failed for $tool"
    info "Installed → $INSTALL_DIR/$tool"

    if [[ ${tool} == "japg.sh" ]]; then
        [[ -f "dict/japg.list" ]] && sudo cp -f "dict/japg.list" /usr/share/dict/ && info "Installed → /usr/share/dict/japg.list"
    fi
}

# ---
# Description: Main routine.
# Globals: INSTALL_DIR, TOOLS
# ---
main() {

    [[ -d $INSTALL_DIR ]] || mkdir -p "$INSTALL_DIR"

    for tool in "${TOOLS[@]}"; do
        install_tool "$tool"
    done

    info 'All tools installed successfully.'
}

main "$@"
