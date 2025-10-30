#!/usr/bin/env zsh
# zsh-alias-hinter-ui - Centralized ZLE hook and redraw handler for all UI modules

# Unified redraw handler for all modules
_zsh_alias_hinter_redraw_handler() {
    # Call completion update first (if defined)
    if (( $+functions[_zsh_alias_hinter_completion_update] )); then
        _zsh_alias_hinter_completion_update
    fi
    # Call inline update next (if defined)
    if (( $+functions[_zsh_alias_hinter_inline_widget] )); then
        _zsh_alias_hinter_inline_widget
    fi
    # Add more module update calls here as needed
}

# Register the unified redraw handler only once
if (( $+functions[add-zle-hook-widget] )) || autoload -Uz add-zle-hook-widget 2>/dev/null; then
	add-zle-hook-widget -d zle-line-pre-redraw _zsh_alias_hinter_redraw_handler 2>/dev/null
	add-zle-hook-widget zle-line-pre-redraw _zsh_alias_hinter_redraw_handler
fi