#!/usr/bin/env bash
# -------------------------------------------------------------
# install.sh - Install keyCD for the current user
#
# Author: TerminallyBlunt
#         https://github.com/terminallyblunt
# Project: https://github.com/terminallyblunt/keycd
#
# SPDX-License-Identifier: MIT
# See LICENSE for the full license text.
#
# Installs:
#   keycd.sh                → ~/.local/share/keycd/
#   _keycd_completion.bash  → ~/.local/share/keycd/
#
# Existing script and completion files are updated.
#
# This installer does not modify .bashrc.
# Run as your normal user, without sudo.
# -------------------------------------------------------------

set -e

# ------------------------------
# Colors / styles
# ------------------------------
# Use colors only in a terminal and when NO_COLOR is not set.
GREEN=""
BOLD_YELLOW=""
CYAN=""
RESET=""

if [[ -t 1 && -z "${NO_COLOR+x}" && "${TERM:-}" != "dumb" ]]; then
    GREEN=$'\e[32m'
    BOLD_YELLOW=$'\e[1;33m'
    CYAN=$'\e[36m'
    RESET=$'\e[0m'
fi

# ------------------------------
# Paths
# ------------------------------
SOURCE_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="$HOME/.local/share/keycd"

# ------------------------------
# Check required source files
# ------------------------------
for file in keycd.sh _keycd_completion.bash; do
    if [[ ! -f "$SOURCE_DIR/$file" || ! -r "$SOURCE_DIR/$file" ]]; then
        printf 'Error: Missing or unreadable source file: %s\n' \
            "$SOURCE_DIR/$file" >&2
        exit 1
    fi
done

# ------------------------------
# Create working directories
# ------------------------------
mkdir -p -- "$INSTALL_DIR"

# ------------------------------
# Install shell files
# ------------------------------
# These files are sourced, so executable permission is unnecessary.
install -m 644 -- "$SOURCE_DIR/keycd.sh" \
    "$INSTALL_DIR/keycd.sh"

install -m 644 -- "$SOURCE_DIR/_keycd_completion.bash" \
    "$INSTALL_DIR/_keycd_completion.bash"

printf 'Installed shell files to: %s\n' "$INSTALL_DIR"

# ------------------------------
# Finished
# ------------------------------
printf '\n%skeyCD file installation complete.%s\n' "$GREEN" "$RESET"
printf '\n%sFirst-time setup: add these lines to ~/.bashrc:%s\n\n' \
    "$BOLD_YELLOW" "$RESET"

printf '%s' "$CYAN"
cat <<'EOF'
# keyCD: directory shortcuts with cd-style path fallback
c() { source "$HOME/.local/share/keycd/keycd.sh" "$@"; }

# keyCD Bash completion
source "$HOME/.local/share/keycd/_keycd_completion.bash"
EOF
printf '%s' "$RESET"

printf '\n%sThen open a new terminal to start using keyCD.%s\n' \
    "$BOLD_YELLOW" "$RESET"
printf 'If these lines are already configured, no .bashrc changes are needed.\n'
