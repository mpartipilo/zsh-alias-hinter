#!/usr/bin/env zsh
# zsh-alias-hinter-inline - Inline alias expansion display (like zsh-autosuggestions)
# This module shows the alias expansion to the right of the cursor when typing

# Note: This file requires zsh-alias-hinter-core.zsh to be loaded first

# Configuration for inline display
: ${ZSH_ALIAS_HINTER_INLINE_ENABLED:=1}     # Enable inline expansion display (0=off, 1=on)
: ${ZSH_ALIAS_HINTER_INLINE_MIN_CHARS:=2}   # Minimum characters before showing inline expansion
: ${ZSH_ALIAS_HINTER_INLINE_COLOR:=8}       # Color for inline text (8=gray, or use color codes)

# Track inline display state
typeset -g _ZSH_ALIAS_HINTER_INLINE_VISIBLE=0
typeset -g _ZSH_ALIAS_HINTER_INLINE_HL=""  # Exact region_highlight entry we added

# Function to clear inline expansion hint
_zsh_alias_hinter_clear_inline() {
    if [[ $_ZSH_ALIAS_HINTER_INLINE_VISIBLE -eq 1 ]]; then
        _zsh_alias_hinter_debug "inline: clearing POSTDISPLAY='$POSTDISPLAY'"
        POSTDISPLAY=""
        # Remove only the exact highlight entry we added
        if [[ -n "$_ZSH_ALIAS_HINTER_INLINE_HL" ]]; then
            region_highlight=("${(@)region_highlight:#$_ZSH_ALIAS_HINTER_INLINE_HL}")
        fi
        _ZSH_ALIAS_HINTER_INLINE_HL=""
        _ZSH_ALIAS_HINTER_INLINE_VISIBLE=0
    fi
}

# Function to show inline expansion (zsh-autosuggestions style)
_zsh_alias_hinter_show_inline() {
    local alias_name="$1"
    local expansion="$2"
    
    # Clear any existing inline hint first
    _zsh_alias_hinter_clear_inline
    
    # Calculate available width
    local buffer_len=${#BUFFER}
    local term_width=${COLUMNS:-80}
    local hint_text=" → $expansion"
    
    # Calculate available width (buffer + hint + some padding)
    local available_width=$((term_width - buffer_len - 5))
    
    # Truncate expansion if needed
    if [[ ${#hint_text} -gt $available_width ]]; then
        # Account for " → " (3 chars) and "..." (3 chars)
        local max_expansion_len=$((available_width - 6))
        if (( max_expansion_len > 0 )); then
            expansion="${expansion:0:$max_expansion_len}..."
            hint_text=" → $expansion"
        else
            # Not enough space, skip display
            return
        fi
    fi
    
    # Display the expansion right after the current buffer
    local spaces=$((term_width - buffer_len - ${#hint_text}))
    
    # Only show if there's enough space
    if (( spaces > 5 )); then
        # Use POSTDISPLAY to show the hint
        POSTDISPLAY="$hint_text"
        _zsh_alias_hinter_debug "inline: set POSTDISPLAY='$hint_text' for BUFFER='$BUFFER'"
        
        # Use region_highlight to color it
        local suggestion_start=$buffer_len
        local suggestion_end=$((buffer_len + ${#hint_text}))
        _ZSH_ALIAS_HINTER_INLINE_HL="$suggestion_start $suggestion_end fg=${ZSH_ALIAS_HINTER_INLINE_COLOR}"
        region_highlight+=("$_ZSH_ALIAS_HINTER_INLINE_HL")
        
        _ZSH_ALIAS_HINTER_INLINE_VISIBLE=1
    fi
}

_zsh_alias_hinter_update_inline() {
    # Skip if inline display is disabled
    [[ $ZSH_ALIAS_HINTER_INLINE_ENABLED -eq 0 ]] && return

    # Check if cache is populated, build if needed
    if [[ ${#_ZSH_ALIAS_HINTER_CACHE_NAMES[@]} -eq 0 ]]; then
        _zsh_alias_hinter_build_cache
    fi

    # Forward direction: the typed command IS an alias name -> show its expansion
    # e.g. typing "gsw" shows "gsw → git switch"
    local cmd_name="$(_zsh_alias_hinter_extract_current_command)"
    if [[ -n "$cmd_name" ]] && [[ ${#cmd_name} -ge $ZSH_ALIAS_HINTER_INLINE_MIN_CHARS ]]; then
        if _zsh_alias_hinter_is_exact_alias_match "$cmd_name"; then
            _zsh_alias_hinter_show_inline "$cmd_name" "${_ZSH_ALIAS_HINTER_CACHE[$cmd_name]}"
            return
        fi
    fi

    # Reverse direction: the typed command matches an alias expansion -> suggest the alias
    # e.g. typing "git switch" shows "git switch → gsw"
    local segment="$(_zsh_alias_hinter_extract_last_command_segment)"
    if [[ -n "$segment" ]] && [[ ${#segment} -ge $ZSH_ALIAS_HINTER_INLINE_MIN_CHARS ]]; then
        _zsh_alias_hinter_get_matching_aliases "$segment" 1 >/dev/null
        if [[ ${#_ZSH_ALIAS_HINTER_MATCHES[@]} -gt 0 ]]; then
            _zsh_alias_hinter_show_inline "$segment" "${_ZSH_ALIAS_HINTER_MATCHES[1]}"
            return
        fi
    fi

    # No match in either direction, clear any existing inline hint
    _zsh_alias_hinter_clear_inline
}

# ZLE widget to update inline display
_zsh_alias_hinter_inline_widget() {
    _zsh_alias_hinter_update_inline
}

# Register the widget
zle -N _zsh_alias_hinter_inline_widget

# Clear inline hint when command is finished
_zsh_alias_hinter_inline_clear_on_finish() {
    _zsh_alias_hinter_clear_inline
}

zle -N _zsh_alias_hinter_inline_clear_on_finish

if (( $+functions[add-zle-hook-widget] )) || autoload -Uz add-zle-hook-widget 2>/dev/null; then
	add-zle-hook-widget zle-line-finish _zsh_alias_hinter_inline_clear_on_finish
fi