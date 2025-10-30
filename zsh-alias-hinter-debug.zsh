#!/usr/bin/env zsh

: ${ZSH_ALIAS_HINTER_DEBUG:=0}              # Enable debug output (0=off, 1=on)
: ${ZSH_ALIAS_HINTER_DEBUG_LOG:=/tmp/zsh-alias-hinter-debug.log}

# Debug helper function
_zsh_alias_hinter_debug() {
    if [[ $ZSH_ALIAS_HINTER_DEBUG -eq 1 ]]; then
        if [[ ! -f "$ZSH_ALIAS_HINTER_DEBUG_LOG" ]]; then
            touch "$ZSH_ALIAS_HINTER_DEBUG_LOG"
        fi
        echo "[DEBUG] $*" >> "$ZSH_ALIAS_HINTER_DEBUG_LOG"
    fi
}

_zsh_alias_hinter_debug "Debugging enabled. ZSH_ALIAS_HINTER_DEBUG=$ZSH_ALIAS_HINTER_DEBUG, LOG=$ZSH_ALIAS_HINTER_DEBUG_LOG"