#!/usr/bin/env bash
# ---
# @file_name: jau.sh
# @version: 1.0.0
# @description: Full system update handler for Fedora-based systems with DNF and Flatpak
# @author: Jamie Albert (empty_produce)
# @author_contact: <mailto:empty.produce@flatmail.me>
#
# @license: GNU Affero General Public License v3.0 (Included in LICENSE)
# Copyright (C) 2025, Jamie Albert
# ---
set -euo pipefail
error() { printf 'Error: %s\n' "$*" >&2; exit 1; }
info()  { printf '%s\n' "$*"; }

# ---
# Description: Install package if missing.
# ---
install_if_missing() {
    local pkg=$1
    if ! command -v "$pkg" &>/dev/null; then
        info "Installing missing dependency: $pkg"
        sudo dnf install -y "$pkg" || error "Failed to install $pkg"
    else
        info "Dependency satisfied: $pkg"
    fi
}

# ---
# Description: Refresh DNF cache and update all packages.
# ---
run_dnf_update() {
    info "Refreshing DNF cache..."
    sudo dnf -y makecache --refresh || error "Failed to refresh DNF cache"

    info "Updating all packages..."
    sudo dnf -y update || error "DNF update failed"
}

# ---
# Description: Handle leftover RPM configuration files.
# ---
handle_rpmconf() {
    if command -v rpmconf &>/dev/null; then
        info "Handling leftover RPM configuration files..."
        sudo rpmconf -a || error "rpmconf execution failed"
    else
        info "rpmconf not available; skipping config file handling"
    fi
}

# ---
# Description: Install security updates if any exist.
# ---
install_security_updates() {
    info "Checking for security updates..."
    if sudo dnf check-update --security &>/dev/null; then
        info "Installing security updates..."
        sudo dnf -y update --security || error "Security update failed"
    else
        info "No security updates available."
    fi
}

# ---
# Description: Remove unused packages and clean cache.
# ---
cleanup_packages() {
    info "Removing unused dependencies..."
    sudo dnf -y autoremove || error "DNF autoremove failed"

    info "Cleaning cached package data..."
    sudo dnf clean all || error "DNF clean failed"
}

# ---
# Description: Update Flatpak applications and remove unused runtimes.
# ---
update_flatpak() {
    if command -v flatpak &>/dev/null; then
        info "Updating Flatpak applications..."
        flatpak update -y || error "Flatpak update failed"

        info "Removing unused Flatpak runtimes..."
        flatpak uninstall --unused -y || error "Flatpak cleanup failed"
    else
        info "Flatpak not installed; skipping Flatpak updates"
    fi
}

# ---
# Description: Main routine.
# Globals: FORCE_ROOT
# ---
main() {

    info "Starting system updates..."

    install_if_missing rpmconf
    install_if_missing flatpak

    run_dnf_update
    handle_rpmconf
    install_security_updates
    cleanup_packages
    update_flatpak

    info "System updates completed successfully."
}

trap 'error "Command failed at line $LINENO"' ERR
main "$@"
