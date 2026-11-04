#!/usr/bin/env bash

# keyCD Bash completion
#
# Author: TerminallyBlunt
#         https://github.com/terminallyblunt
# Project: https://github.com/terminallyblunt/keycd
#
# SPDX-License-Identifier: MIT
# See LICENSE for the full license text.
#
# Provides tab completion for the c() command:
#   - keyCD shortcut keys from the database
#   - keyCD command-line options
#   - regular filesystem directories
#
# The file is sourced by .bashrc and is not intended to be
# executed directly.

_keycd_complete() {
    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"

    local db="$HOME/.config/keycd/keycd_db.txt"

    local keys=""
    [[ -f "$db" ]] && keys=$(cut -d'|' -f1 "$db" | grep -v '^#')

    if [[ "$cur" == -* ]]; then
        mapfile -t COMPREPLY < <(compgen -W "-a --add -r --remove -l --list -h --help" -- "$cur")
    else
        mapfile -t COMPREPLY < <(compgen -W "$keys" -- "$cur")

        local -a dir_compl
        # Read whole directory names without splitting spaces or expanding globs.
        mapfile -t dir_compl < <(compgen -d -- "$cur")
        if [[ ${#dir_compl[@]} -gt 0 ]]; then
            # Let Bash quote filenames and allow continued directory completion.
            compopt -o filenames -o nospace
            COMPREPLY+=( "${dir_compl[@]}" )
        fi
    fi
}

complete -F _keycd_complete c
