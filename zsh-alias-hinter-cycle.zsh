# zsh-alias-hinter-cycle.zsh - Cycling logic for alias matches
# This module provides functions to cycle through found alias matches

# Note: This file requires zsh-alias-hinter-core.zsh to be loaded first
# Note: This file requires zsh-alias-hinter-completion.zsh to be loaded first

# Configuration
: ${ZSH_ALIAS_HINTER_CYCLING_ENABLED:=1}        # Enable alias completion cycling (0=off, 1=on)
: ${ZSH_ALIAS_HINTER_CYCLING_KEY:="^N"}         # Keybinding to cycle through aliases (default: Ctrl+N)

# Local copy of matches for cycling
typeset -ga _ZSH_ALIAS_HINTER_CYCLE_MATCHES=()

# Rotates the _ZSH_ALIAS_HINTER_COMPLETION_MATCHES array
_zsh_alias_hinter_rotate_completion_matches() {
    if [[ ${#_ZSH_ALIAS_HINTER_CYCLE_MATCHES[@]} -gt 1 ]]; then
        local first="${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[1]}"
        _ZSH_ALIAS_HINTER_CYCLE_MATCHES=( "${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[@]:1}" "$first" )
    fi
}

# Widget to cycle through matching aliases
_zsh_alias_hinter_completion_cycle() {
    local current_cmd="$(_zsh_alias_hinter_extract_current_command)"

    # Initialize local copy of the buffer if it's empty
    if [[ ${#_ZSH_ALIAS_HINTER_CYCLE_MATCHES[@]} -eq 0 ]]; then
        _ZSH_ALIAS_HINTER_CYCLE_MATCHES=( "${_ZSH_ALIAS_HINTER_MATCHES[@]}" )
    fi    

    _zsh_alias_hinter_debug "Ctrl+N pressed. current_cmd='$current_cmd' BUFFER='$BUFFER' matches='${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[@]}'"

    if ! _zsh_alias_hinter_is_exact_alias_match "$current_cmd"; then
        # When the current command is not an alias, replace it with the first match

        _zsh_alias_hinter_debug "Current command is not an alias, replacing with first match: ${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[1]}"

        # If the current command is not in the matches, reset the cycle matches
        _ZSH_ALIAS_HINTER_CYCLE_MATCHES=( "${_ZSH_ALIAS_HINTER_MATCHES[@]}" )

        _zsh_alias_hinter_replace_current_command "${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[1]}"

        return
    fi

    if _zsh_alias_hinter_is_exact_alias_match "$current_cmd"; then
        _zsh_alias_hinter_debug "Current command is an alias"

        if [[ "$current_cmd" != "${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[1]}" ]]; then
            _ZSH_ALIAS_HINTER_CYCLE_MATCHES=()
            return
        fi

        # Only cycle if matches exist and current_cmd matches the first alias
        if [[ "$current_cmd" == "${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[1]}" ]]; then
            _zsh_alias_hinter_rotate_completion_matches

            if [[ ${#_ZSH_ALIAS_HINTER_CYCLE_MATCHES[@]} -gt 0 ]]; then
                _zsh_alias_hinter_debug "Setting current command to ${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[1]}"
                _zsh_alias_hinter_replace_current_command "${_ZSH_ALIAS_HINTER_CYCLE_MATCHES[1]}"
            fi
        fi
    fi
}

if [[ $ZSH_ALIAS_HINTER_CYCLING_ENABLED -eq 1 ]]; then
    # Register as a ZLE completion widget
    if zle -l >/dev/null 2>&1; then

        # Register the cycle widget
        zle -N _zsh_alias_hinter_completion_cycle
                
        # Bind the cycle key
        bindkey "$ZSH_ALIAS_HINTER_CYCLING_KEY" _zsh_alias_hinter_completion_cycle
    fi
fi
