#!/usr/bin/env zsh
# zsh-alias-hinter-completion - Auto-complete style display for aliases
# This module shows matching aliases in a list below the prompt

# Note: This file requires zsh-alias-hinter-core.zsh to be loaded first

# Configuration
: ${ZSH_ALIAS_HINTER_COMPLETION_ENABLED:=1}        # Enable completion display (0=off, 1=on)
: ${ZSH_ALIAS_HINTER_COMPLETION_MIN_CHARS:=2}     # Minimum characters before showing completions
: ${ZSH_ALIAS_HINTER_COMPLETION_MAX_DISPLAY:=10}  # Maximum number of matches to display

# Custom completion widget that shows alias matches
_zsh_alias_hinter_completion_widget() {
    # Extract the full last command segment using core function
    local current_cmd
    current_cmd="$(_zsh_alias_hinter_extract_last_command_segment)"
    
    # Don't show if too short
    if [[ ${#current_cmd} -lt $ZSH_ALIAS_HINTER_COMPLETION_MIN_CHARS ]]; then
        compstate[list]=
        return
    fi

    # Ensure cache is populated
    _zsh_alias_hinter_build_cache 2>/dev/null || true
        
    # Find matching aliases and store in global arrays
    _zsh_alias_hinter_get_matching_aliases "$current_cmd" "$ZSH_ALIAS_HINTER_COMPLETION_MAX_DISPLAY" >/dev/null

    # If we have matches, add them as completions
    if [[ ${#_ZSH_ALIAS_HINTER_MATCHES[@]} -gt 0 ]]; then
        local -a matches descriptions
        matches=( "${_ZSH_ALIAS_HINTER_MATCHES[@]}" )
        descriptions=()
        for match in "${matches[@]}"; do
            descriptions+=( "${_ZSH_ALIAS_HINTER_MATCH_VALUES[$match]}" )
        done
        compadd -U -d descriptions -a matches
    else
        compstate[list]=
    fi
}

# Widget to trigger the completion display
_zsh_alias_hinter_completion_update() {
    # Don't show if disabled
    if [[ $ZSH_ALIAS_HINTER_COMPLETION_ENABLED -ne 1 ]]; then
        return
    fi
    
    # Extract the full last command segment using core function
    local current_cmd
    current_cmd="$(_zsh_alias_hinter_extract_last_command_segment)"
        
    # Don't show if too short
    if [[ ${#current_cmd} -lt $ZSH_ALIAS_HINTER_COMPLETION_MIN_CHARS ]]; then
        zle -Rc 2>/dev/null || true
        return
    fi
    
    # Call our completion widget
    zle .autocomplete:alias-hinter:list-choices -w 2>/dev/null && zle -R 2>/dev/null
}

if [[ $ZSH_ALIAS_HINTER_COMPLETION_ENABLED -eq 1 ]]; then
    # Register as a ZLE completion widget
    if zle -l >/dev/null 2>&1; then
        # Create the list-choices widget for display
        zle -C .autocomplete:alias-hinter:list-choices list-choices _zsh_alias_hinter_completion_widget
        
        # Register the update widget (shows the list)
        zle -N _zsh_alias_hinter_completion_update
    fi
fi

