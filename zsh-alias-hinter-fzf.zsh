#!/usr/bin/env zsh
# zsh-alias-hinter-fzf - Interactive alias selection using fzf
# This module provides a keybinding to search and select aliases interactively

# Note: This file requires zsh-alias-hinter-core.zsh to be loaded first
# Note: This module requires fzf to be installed

# Configuration
: ${ZSH_ALIAS_HINTER_FZF_ENABLED:=1}           # Enable fzf selection (0=off, 1=on)
: ${ZSH_ALIAS_HINTER_FZF_KEY:="^F"}            # Keybinding (default: Ctrl+F)
: ${ZSH_ALIAS_HINTER_FZF_HEIGHT:=40%}          # fzf window height
: ${ZSH_ALIAS_HINTER_FZF_PROMPT:="Aliases ❯ "} # fzf prompt text

# Additional fzf options (can be overridden by user)
: ${ZSH_ALIAS_HINTER_FZF_OPTS:="--reverse --border --info=inline"}

# Function to launch fzf with all cached aliases
_zsh_alias_hinter_fzf_select() {
    # Check if fzf is available
    if ! command -v fzf >/dev/null 2>&1; then
        zle -M "fzf is not installed. Please install fzf to use this feature."
        return 1
    fi
    
    # Idempotently build cache if needed
    _zsh_alias_hinter_build_cache
    
    # Check if we have any aliases
    if [[ ${#_ZSH_ALIAS_HINTER_CACHE_NAMES[@]} -eq 0 ]]; then
        zle -M "No aliases found in cache"
        return 1
    fi
    
    # Build list of aliases in format: "alias_name -> expansion"
    local -a alias_list
    local alias_name
    for alias_name in "${_ZSH_ALIAS_HINTER_CACHE_NAMES[@]}"; do
        alias_list+=("${alias_name} -> ${_ZSH_ALIAS_HINTER_CACHE[$alias_name]}")
    done
    
    # Launch fzf and get selection
    local selected
    selected=$(printf '%s\n' "${alias_list[@]}" | \
        fzf --height="$ZSH_ALIAS_HINTER_FZF_HEIGHT" \
            --prompt="$ZSH_ALIAS_HINTER_FZF_PROMPT" \
            $=ZSH_ALIAS_HINTER_FZF_OPTS)
    
    # Always redraw the prompt to restore display state
    zle reset-prompt
    
    # If something was selected, extract the alias name and insert it
    if [[ -n "$selected" ]]; then
        # Extract just the alias name (before " -> ")
        local alias_name="${selected%% ->*}"
        
    # Replace only the last command segment in the buffer
    _zsh_alias_hinter_replace_current_command "$alias_name"
    fi
}

# Function to search aliases based on current buffer content
_zsh_alias_hinter_fzf_search_current() {
    # Check if fzf is available
    if ! command -v fzf >/dev/null 2>&1; then
        zle -M "fzf is not installed. Please install fzf to use this feature."
        return 1
    fi
    
    # Idempotently build cache if needed
    _zsh_alias_hinter_build_cache
    
    # Get query from last command segment
    local query
    query="$(_zsh_alias_hinter_extract_last_command_segment)"
    
    # Build list of aliases
    local -a alias_list
    local alias_name
    for alias_name in "${_ZSH_ALIAS_HINTER_CACHE_NAMES[@]}"; do
        alias_list+=("${alias_name} -> ${_ZSH_ALIAS_HINTER_CACHE[$alias_name]}")
    done
    
    # Launch fzf with current buffer as initial query
    local selected
    selected=$(printf '%s\n' "${alias_list[@]}" | \
        fzf --height="$ZSH_ALIAS_HINTER_FZF_HEIGHT" \
            --prompt="$ZSH_ALIAS_HINTER_FZF_PROMPT" \
            --query="$query" \
            $=ZSH_ALIAS_HINTER_FZF_OPTS)
    
    # Always redraw the prompt to restore display state
    zle reset-prompt
    
    # If something was selected, extract the alias name and replace buffer
    if [[ -n "$selected" ]]; then
        # Extract just the alias name (before " -> ")
        local alias_name="${selected%% ->*}"
        
    # Replace only the last command segment in the buffer
    _zsh_alias_hinter_replace_current_command "$alias_name"
    fi
}

# Register ZLE widgets
zle -N _zsh_alias_hinter_fzf_select
zle -N _zsh_alias_hinter_fzf_search_current

# Bind the key if enabled
if [[ $ZSH_ALIAS_HINTER_FZF_ENABLED -eq 1 ]]; then
    # Bind to the configured key
    bindkey "$ZSH_ALIAS_HINTER_FZF_KEY" _zsh_alias_hinter_fzf_search_current
    
    # Also provide alternative widget name for manual binding
    # Users can bind this to any key they want:
    # bindkey '^G' _zsh_alias_hinter_fzf_select
fi

# Print info message on load (only if enabled)
if [[ $ZSH_ALIAS_HINTER_FZF_ENABLED -eq 1 ]]; then
    # Only show if this is an interactive shell
    if [[ -o interactive ]]; then
        # Use a function that runs after the prompt is loaded to avoid interference
        _zsh_alias_hinter_fzf_show_info() {
            # Only show once
            if [[ -z "$_ZSH_ALIAS_HINTER_FZF_INFO_SHOWN" ]]; then
                typeset -g _ZSH_ALIAS_HINTER_FZF_INFO_SHOWN=1
                # Show binding info (optional - comment out if too noisy)
                # echo "zsh-alias-hinter: Press $ZSH_ALIAS_HINTER_FZF_KEY to search aliases with fzf"
            fi
            
            # Remove this function from precmd hooks
            add-zsh-hook -d precmd _zsh_alias_hinter_fzf_show_info
        }
        
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _zsh_alias_hinter_fzf_show_info
    fi
fi
