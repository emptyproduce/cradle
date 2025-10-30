#!/usr/bin/env bash
# ---
# @file_name: jau.sh
# @version: 1.0.0
# @description: Full system update handler for Fedora-based systems with DNF and Flatpak
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
  declare exit_code="$1"
  shift
  declare error_msg
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
# @description: Perform initial setup checks. Verifies required base commands (dnf, sudo) are available.
# @return_code: [2] Required tool 'sudo' not found.
# @return_code: [3] Required tool 'dnf' not found.
# ---
setup() {
  command -v sudo >/dev/null || error 2 "sudo not found"
  sudo sh -c 'command -v dnf >/dev/null' || error 3 "dnf not found (script requires a DNF-based system)"
}

# ---
# @description: Install package if missing.
# @arg: $1 - The name of the package/command to check and install.
# @return_code: [1] General error (inherits from set -e).
# @return_code: [4] Failed to install the specified package.
# ---
install_if_missing() {
  declare pkg="$1"
  if ! command -v "$pkg" &>/dev/null; then
    info "Installing missing dependency: $pkg"
    sudo dnf install -y "$pkg" || error 4 "Failed to install $pkg"
  else
    info "Dependency satisfied: $pkg"
  fi
}

# ---
# @description: Refresh DNF cache and update all packages.
# @return_code: [1] General error (inherits from set -e).
# @return_code: [5] Failed to refresh DNF cache.
# @return_code: [6] DNF update failed.
# ---
run_dnf_update() {
  info "Refreshing DNF cache..."
  sudo dnf -y makecache --refresh || error 5 "Failed to refresh DNF cache"

  info "Updating all packages..."
  sudo dnf -y update || error 6 "DNF update failed"
}

# ---
# @description: Handle leftover RPM configuration files.
# @return_code: [1] General error (inherits from set -e).
# @return_code: [7] rpmconf execution failed.
# ---
handle_rpmconf() {
  if command -v rpmconf &>/dev/null; then
    info "Handling leftover RPM configuration files..."
    sudo rpmconf -a || error 7 "rpmconf execution failed"
  else
    info "rpmconf not available; skipping config file handling"
  fi
}

# ---
# @description: Install security updates if any exist.
# @return_code: [1] General error (inherits from set -e).
# @return_code: [8] Security update failed.
# ---
install_security_updates() {
  info "Checking for security updates..."
  # dnf check-update returns 100 if updates are available, 1 on error, 0 if not.
  # We only want to proceed if it returns 100 (success with updates) or 0 (no updates).
  # Using || true prevents set -e from triggering on exit code 100.
  if sudo dnf check-update --security &>/dev/null || [[ $? -eq 100 ]]; then
    info "Installing security updates..."
    sudo dnf -y update --security || error 8 "Security update failed"
  else
    info "No security updates available."
  fi
}

# ---
# @description: Remove unused packages and clean cache.
# @return_code: [1] General error (inherits from set -e).
# @return_code: [9] DNF autoremove failed.
# @return_code: [10] DNF clean failed.
# ---
cleanup_packages() {
  info "Removing unused dependencies..."
  sudo dnf -y autoremove || error 9 "DNF autoremove failed"

  info "Cleaning cached package data..."
  sudo dnf clean all || error 10 "DNF clean failed"
}

# ---
# @description: Update Flatpak applications and remove unused runtimes.
# @return_code: [1] General error (inherits from set -e).
# @return_code: [11] Flatpak update failed.
# @return_code: [12] Flatpak cleanup failed.
# ---
update_flatpak() {
  if command -v flatpak &>/dev/null; then
    info "Updating Flatpak applications..."
    flatpak update -y || error 11 "Flatpak update failed"

    info "Removing unused Flatpak runtimes..."
    flatpak uninstall --unused -y || error 12 "Flatpak cleanup failed"
  else
    info "Flatpak not installed; skipping Flatpak updates"
  fi
}

# ---
# @description: Main routine.
# @arg: $@ - Command-line arguments (currently unused).
# @return_code: [1] General error (inherits from set -e).
# @return_code: [N] Errors from called functions (e.g., setup, install_if_missing, etc.).
# ---
main() {
  setup
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

main "$@"