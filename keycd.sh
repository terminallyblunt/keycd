#!/usr/bin/env bash
# -------------------------------------------------------------
# keycd.sh - Directory shortcut script for Bash - NameSpaced
#
# Author: TerminallyBlunt
#         https://github.com/terminallyblunt
# Project: https://github.com/terminallyblunt/keycd
# Version: 0.1.0
#
# SPDX-License-Identifier: MIT
# See LICENSE for the full license text.
#
# Features:
#   - Quickly jump to directories via keys (stored in DB file)
#   - Fallback to normal cd if argument is a valid path
#   - -a / --add [key]: add current directory to DB
#   - -r / --remove [key]: remove entry (by key or current dir)
#   - --list / -l: show all keys with paths (flags missing dirs)
#   - --help / -h: show usage
#   - Colors for readability and [NOT FOUND] labels
#
# DB format:
#   key|/absolute/path
#   - one entry per line
#   - ignore empty lines and comments (#)
#   - keys and paths must be unique
#
# Example usage:
#   c mango        # cd via key
#   c /etc         # fallback to real directory
#   c -a           # add current directory (prompt for key)
#   c -a mango     # add current directory with key
#   c -r           # remove entry for current directory
#   c -r mango     # remove entry by key
#   c --list       # list all keys
# -------------------------------------------------------------

# ------------------------------
# Config
# ------------------------------
KEYCD_DB_DIR="$HOME/.config/keycd"
KEYCD_DB="$KEYCD_DB_DIR/keycd_db.txt"

# ------------------------------
# Colors / styles
# ------------------------------
KEYCD_RED="\e[91m"
KEYCD_GREEN="\e[92m"
KEYCD_YELLOW="\e[93m"
KEYCD_BLUE="\e[94m"
KEYCD_MAGENTA="\e[95m"
KEYCD_CYAN="\e[96m"
KEYCD_ORANGE="\e[38;5;208m"
KEYCD_BOLD="\e[1m"
KEYCD_RESET="\e[0m"

# ------------------------------
# Init DB (safe + silent)
# ------------------------------
if ! mkdir -p -- "$KEYCD_DB_DIR"; then
    echo -e "${KEYCD_RED}Error: Cannot create database directory${KEYCD_RESET}" >&2
    return 1 2>/dev/null || exit 1
fi

if [[ ! -e "$KEYCD_DB" && ! -L "$KEYCD_DB" ]]; then
    # Create a private empty file without overwriting an existing one.
    if ! (set -o noclobber; umask 077; : > "$KEYCD_DB"); then
        echo -e "${KEYCD_RED}Error: Cannot create database${KEYCD_RESET}" >&2
        return 1 2>/dev/null || exit 1
    fi
fi

if [[ ! -f "$KEYCD_DB" || ! -r "$KEYCD_DB" ]]; then
    echo -e "${KEYCD_RED}Error: Database is not a readable regular file${KEYCD_RESET}" >&2
    return 1 2>/dev/null || exit 1
fi

# ------------------------------
# Helper: trim whitespace
# ------------------------------
keycd_trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# ------------------------------
# Load DB into associative array
# ------------------------------
declare -A KEYCD_DIRS

keycd_load_db() {
    local key path

    KEYCD_DIRS=()

    # Read the final entry even if it has no trailing newline.
    # Preserve path whitespace because it can be part of a directory name.
    if ! while IFS='|' read -r key path || [[ -n "$key" || -n "$path" ]]; do
        key="$(keycd_trim "$key")"

        [[ -z "$key" || "$key" =~ ^# ]] && continue

        KEYCD_DIRS["$key"]="$path"
    done < "$KEYCD_DB"; then
        echo -e "${KEYCD_RED}Error: Cannot load database${KEYCD_RESET}" >&2
        return 1
    fi
}

keycd_load_db || { return 1 2>/dev/null || exit 1; }

# ------------------------------
# Validation helpers
# ------------------------------

keycd_key_exists() {
    [[ -n "${KEYCD_DIRS[$1]}" ]]
}

keycd_path_exists() {
    local search="$1"
    local k
    for k in "${!KEYCD_DIRS[@]}"; do
        [[ "${KEYCD_DIRS[$k]}" == "$search" ]] && return 0
    done
    return 1
}

keycd_valid_key() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]]
}

# ------------------------------
# DB write (deterministic order)
# ------------------------------
keycd_write_db() {
    local k temp_file

    # Write beside the database so the final rename stays on one filesystem.
    if ! temp_file="$(mktemp "$KEYCD_DB_DIR/.keycd_db.XXXXXX")"; then
        echo -e "${KEYCD_RED}Error: Cannot create temporary database file${KEYCD_RESET}" >&2
        return 1
    fi

    # Check the complete write, including sorting, before replacing the DB.
    if ! (
        set -o pipefail
        printf '%s\n' "${!KEYCD_DIRS[@]}" | sort |
            while IFS= read -r k; do
                [[ -z "$k" ]] && continue
                printf '%s|%s\n' "$k" "${KEYCD_DIRS[$k]}" || exit 1
            done
    ) > "$temp_file"; then
        rm -f -- "$temp_file"
        echo -e "${KEYCD_RED}Error: Cannot write database; original preserved${KEYCD_RESET}" >&2
        return 1
    fi

    if ! mv -f -- "$temp_file" "$KEYCD_DB"; then
        rm -f -- "$temp_file"
        echo -e "${KEYCD_RED}Error: Cannot replace database${KEYCD_RESET}" >&2
        return 1
    fi
}

# ------------------------------
# Add current directory
# ------------------------------
keycd_add() {
    local key="$1"
    local path="$PWD"

    if keycd_path_exists "$path"; then
        echo -e "${KEYCD_YELLOW}Warning: Directory already exists in DB${KEYCD_RESET}"
        return 1
    fi

    if [[ -z "$key" ]]; then
        read -rp "Enter shortcut key: " key || return 1
    fi

    key="$(keycd_trim "$key")"

    if ! keycd_valid_key "$key"; then
        echo -e "${KEYCD_RED}Error: Invalid key (use letters, numbers, _ or -)${KEYCD_RESET}"
        return 1
    fi

    if keycd_key_exists "$key"; then
        echo -e "${KEYCD_RED}Error: Key already exists${KEYCD_RESET}"
        return 1
    fi

    # These characters cannot be represented by the line-based DB format.
    if [[ "$path" == *'|'* || "$path" == *$'\n'* ]]; then
        echo -e "${KEYCD_RED}Error: Directory paths cannot contain | or newline characters${KEYCD_RESET}"
        return 1
    fi

    KEYCD_DIRS["$key"]="$path"
    if ! keycd_write_db; then
        unset 'KEYCD_DIRS[$key]'
        return 1
    fi

    echo -e "${KEYCD_GREEN}Added:${KEYCD_RESET} $key → $path"
}

# ------------------------------
# Remove entry
# ------------------------------
keycd_remove() {
    local key="$1"
    local path="$PWD"
    local k old_path

    if [[ -n "$key" ]]; then
        if ! keycd_key_exists "$key"; then
            echo -e "${KEYCD_RED}Error: Key not found${KEYCD_RESET}"
            return 1
        fi
        old_path="${KEYCD_DIRS[$key]}"
        unset 'KEYCD_DIRS[$key]'
        if ! keycd_write_db; then
            KEYCD_DIRS["$key"]="$old_path"
            return 1
        fi
        echo -e "${KEYCD_GREEN}Removed:${KEYCD_RESET} $key"
        return 0
    fi

    # Remove by current directory
    for k in "${!KEYCD_DIRS[@]}"; do
        if [[ "${KEYCD_DIRS[$k]}" == "$path" ]]; then
            unset 'KEYCD_DIRS[$k]'
            if ! keycd_write_db; then
                KEYCD_DIRS["$k"]="$path"
                return 1
            fi
            echo -e "${KEYCD_GREEN}Removed:${KEYCD_RESET} $k"
            return 0
        fi
    done

    echo -e "${KEYCD_RED}Error: Current directory not found in DB${KEYCD_RESET}"
    return 1
}

# ------------------------------
# Help / list (unchanged style)
# ------------------------------
keycd_show_help() {
    echo -e "${KEYCD_BOLD}Usage:${KEYCD_RESET} c <key> | <path> | [options]"
    echo
    echo -e "${KEYCD_BOLD}Options:${KEYCD_RESET}"
    echo -e "  ${KEYCD_BLUE}-a, --add [key]${KEYCD_RESET}      Add current directory"
    echo -e "  ${KEYCD_BLUE}-r, --remove [key]${KEYCD_RESET}   Remove entry"
    echo -e "  ${KEYCD_BLUE}-l, --list${KEYCD_RESET}           List all entries"
    echo -e "  ${KEYCD_BLUE}-h, --help${KEYCD_RESET}           Show this help"
}

keycd_list_keys() {
    local k path color label

    printf "${KEYCD_BOLD}%-15s %s${KEYCD_RESET}\n" "KEY" "DIRECTORY"
    printf "${KEYCD_BOLD}%-15s %s${KEYCD_RESET}\n" "---" "---------"

    for k in $(printf "%s\n" "${!KEYCD_DIRS[@]}" | sort); do
        path="${KEYCD_DIRS[$k]}"
        if [[ -d "$path" ]]; then
            color="$KEYCD_GREEN"
            label=""
        else
            color="$KEYCD_RED"
            label=" [NOT FOUND]"
        fi

        printf "${KEYCD_BOLD}%-15s${KEYCD_RESET} %b%s%b%b\n" \
            "$k" "$color" "$path" "$KEYCD_RESET" "$label"
    done
}

# ------------------------------
# Main logic
# ------------------------------
case "${1-}" in
    -a|--add)
        keycd_add "${2-}"
        KEYCD_STATUS=$?
        return "$KEYCD_STATUS" 2>/dev/null || exit "$KEYCD_STATUS"
        ;;
    -r|--remove)
        keycd_remove "${2-}"
        KEYCD_STATUS=$?
        return "$KEYCD_STATUS" 2>/dev/null || exit "$KEYCD_STATUS"
        ;;
    -l|--list)
        keycd_list_keys
        KEYCD_STATUS=$?
        return "$KEYCD_STATUS" 2>/dev/null || exit "$KEYCD_STATUS"
        ;;
    -h|--help)
        keycd_show_help
        KEYCD_STATUS=$?
        return "$KEYCD_STATUS" 2>/dev/null || exit "$KEYCD_STATUS"
        ;;
    "")
        cd "$HOME" || return 1 2>/dev/null || exit 1
        ;;
    *)
        if [[ -n "${KEYCD_DIRS[$1]}" ]]; then
            cd "${KEYCD_DIRS[$1]}" || return 1 2>/dev/null || exit 1
        elif [[ -d "$1" ]]; then
            cd "$1" || return 1 2>/dev/null || exit 1
        else
            echo -e "${KEYCD_RED}Error: '$1' not a key or directory${KEYCD_RESET}"
            return 1 2>/dev/null || exit 1
        fi
        ;;
esac
