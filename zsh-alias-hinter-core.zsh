#!/usr/bin/env zsh
# zsh-alias-hinter-core - Core functionality for alias matching and caching

# Enable extended glob for pattern matching
setopt local_options extended_glob

# Configuration for match limiting
: ${ZSH_ALIAS_HINTER_MAX_MATCHES:=5}       # Overall maximum number of matches displayed

# Global alias cache (populated on load, refreshable)
typeset -gA _ZSH_ALIAS_HINTER_CACHE        # Maps alias_name -> alias_expansion
typeset -ga _ZSH_ALIAS_HINTER_CACHE_NAMES  # Array of all alias names for iteration
typeset -g _ZSH_ALIAS_HINTER_ALIAS_HASH=""  # Hash of all aliases for change detection

# Function to extract the current command being typed
_zsh_alias_hinter_extract_current_command() {
    # Use the last command segment extraction logic
    local last_cmd="$(_zsh_alias_hinter_extract_last_command_segment)"
    # Extract just the first word (command name) from the last command
    local cmd_name="${last_cmd%% *}"
    # Trim any remaining whitespace from command name
    cmd_name="${cmd_name##[[:space:]]##}"
    cmd_name="${cmd_name%%[[:space:]]##}"
    echo "$cmd_name"
}

# Function to extract the full last command segment (for completion)
_zsh_alias_hinter_extract_last_command_segment() {
    local current_buffer="$BUFFER"
    # Extract last command if there are multiple (separated by && or ;)
    if [[ "$current_buffer" == *'&&'* ]]; then
        current_buffer="${current_buffer##*&&}"
    elif [[ "$current_buffer" == *';'* ]]; then
        current_buffer="${current_buffer##*;}"
    fi
    # Trim whitespace
    current_buffer="${current_buffer##[[:space:]]##}"
    current_buffer="${current_buffer%%[[:space:]]##}"
    echo "$current_buffer"
}

# Function to check if a command matches an alias exactly
_zsh_alias_hinter_is_exact_alias_match() {
    local cmd_name="$1"
    [[ -n "$cmd_name" && -n ${_ZSH_ALIAS_HINTER_CACHE[$cmd_name]} ]]
}

# Function to replace the current command in the buffer
# This replaces the last command in the buffer with the given alias
_zsh_alias_hinter_replace_current_command() {
    local new_cmd="$1"
    local buffer="$BUFFER"
    local prefix=""
    local sep=""
    local trailing_ws=""

    # Find the last separator and its position
    if [[ "$buffer" == *'&&'* ]]; then
        sep='&&'
    elif [[ "$buffer" == *';'* ]]; then
        sep=';'
    elif [[ "$buffer" == *'||'* ]]; then
        sep='||'
    elif [[ "$buffer" == *'|'* && "$buffer" != *'||'* ]]; then
        sep='|'
    fi

    if [[ -n "$sep" ]]; then
        # Find the index of the last separator
        local last_sep_idx
        last_sep_idx=$(awk -v a="$buffer" -v b="$sep" 'BEGIN{print index(a, b)}')
        # Actually, we want the last occurrence, so use parameter expansion
        local prefix_and_sep="${buffer%${sep}*}${sep}"
        # Now, preserve any whitespace after the separator
        local after_sep="${buffer##*${sep}}"
        if [[ "$after_sep" =~ "^([[:space:]]*)" ]]; then
            trailing_ws="${match[1]}"
        fi
        BUFFER="${prefix_and_sep}${trailing_ws}${new_cmd}"
    else
        BUFFER="$new_cmd"
    fi
    CURSOR=${#BUFFER}
}

# Mock data for testing (set this variable to provide mock alias output)
typeset -g ZSH_ALIAS_HINTER_MOCK_ALIAS_OUTPUT=""
typeset -g ZSH_ALIAS_HINTER_MOCK_MODE=0  # Set to 1 to enable mock mode

# Get alias output - either from mock or real alias command
_zsh_alias_hinter_get_alias_output() {
    if [[ $ZSH_ALIAS_HINTER_MOCK_MODE -eq 1 ]]; then
        echo "$ZSH_ALIAS_HINTER_MOCK_ALIAS_OUTPUT"
    else
        alias
    fi
}

# Build or rebuild the alias cache
_zsh_alias_hinter_build_cache() {
    # Always rebuild cache in mock mode for tests
    if [[ $ZSH_ALIAS_HINTER_MOCK_MODE -eq 1 ]]; then
        _ZSH_ALIAS_HINTER_CACHE=()
        _ZSH_ALIAS_HINTER_CACHE_NAMES=()
    elif [[ ${#_ZSH_ALIAS_HINTER_CACHE_NAMES[@]} -ne 0 ]]; then
        return
    fi
    _ZSH_ALIAS_HINTER_CACHE=()
    _ZSH_ALIAS_HINTER_CACHE_NAMES=()
    # Parse all aliases (including global aliases)
    local alias_name alias_value
    while IFS='=' read -r alias_name alias_value; do
        # Clean up the alias name and value
        alias_name="${alias_name#alias }"
        alias_value="${alias_value#'}"
        alias_value="${alias_value%'}"
        # Skip if empty
        [[ -z "$alias_name" ]] && continue
        # Add to cache (no complexity filtering - keep all aliases simple or complex)
        _ZSH_ALIAS_HINTER_CACHE[$alias_name]="$alias_value"
        _ZSH_ALIAS_HINTER_CACHE_NAMES+=("$alias_name")
    done < <(_zsh_alias_hinter_get_alias_output)
    # Update hash for change detection
    _zsh_alias_hinter_update_hash
}

# Compute hash of current aliases for change detection
_zsh_alias_hinter_update_hash() {
    # Simple hash: concatenate sorted alias names and use md5/shasum
    local hash_cmd
    if command -v md5 >/dev/null 2>&1; then
        hash_cmd="md5"
    elif command -v md5sum >/dev/null 2>&1; then
        hash_cmd="md5sum"
    elif command -v shasum >/dev/null 2>&1; then
        hash_cmd="shasum"
    else
        # Fallback: just count aliases
        _ZSH_ALIAS_HINTER_ALIAS_HASH="${#_ZSH_ALIAS_HINTER_CACHE_NAMES[@]}"
        return
    fi
    
    _ZSH_ALIAS_HINTER_ALIAS_HASH=$(_zsh_alias_hinter_get_alias_output | $hash_cmd | cut -d' ' -f1)
}

# Check if aliases have changed and rebuild cache if needed
_zsh_alias_hinter_check_changes() {
    local current_hash
    local hash_cmd
    
    if command -v md5 >/dev/null 2>&1; then
        hash_cmd="md5"
    elif command -v md5sum >/dev/null 2>&1; then
        hash_cmd="md5sum"
    elif command -v shasum >/dev/null 2>&1; then
        hash_cmd="shasum"
    else
        # Fallback: count comparison
        local alias_count=$(_zsh_alias_hinter_get_alias_output | wc -l | tr -d ' ')
        if [[ "$alias_count" != "$_ZSH_ALIAS_HINTER_ALIAS_HASH" ]]; then
            _zsh_alias_hinter_build_cache
        fi
        return
    fi
    
    current_hash=$(_zsh_alias_hinter_get_alias_output | $hash_cmd | cut -d' ' -f1)
    
    if [[ "$current_hash" != "$_ZSH_ALIAS_HINTER_ALIAS_HASH" ]]; then
        _zsh_alias_hinter_build_cache
    fi
}

# User-callable function to reload the alias cache
zsh_alias_hinter_reload() {
    _zsh_alias_hinter_build_cache
    echo "Alias cache reloaded: ${#_ZSH_ALIAS_HINTER_CACHE_NAMES[@]} aliases cached"
}

# Function to find aliases matching a command
# Returns results via global arrays for easy testing and integration
typeset -ga _ZSH_ALIAS_HINTER_MATCHES        # Array of matching alias names
typeset -gA _ZSH_ALIAS_HINTER_MATCH_VALUES   # Map of alias name -> expansion


# Returns matching aliases and their expansions for a given command, up to a limit
_zsh_alias_hinter_get_matching_aliases() {
    local query="$1"
    local limit="$2"
    local -a matches
    local -a descriptions
    local count=0

    # Set default limit if not provided or invalid
    if [[ -z "$limit" ]] || [[ ! "$limit" =~ '^[0-9]+$' ]]; then
        limit="${ZSH_ALIAS_HINTER_MAX_MATCHES:-5}"
    fi

    # Check if cache is populated, build if needed
    if [[ ${#_ZSH_ALIAS_HINTER_CACHE_NAMES[@]} -eq 0 ]]; then
        _zsh_alias_hinter_build_cache
    fi

    local alias_name alias_value
    for alias_name in "${_ZSH_ALIAS_HINTER_CACHE_NAMES[@]}"; do
        alias_value="${_ZSH_ALIAS_HINTER_CACHE[$alias_name]}"
        if [[ "$alias_value" == "$query"* ]]; then
            matches+=("$alias_name")
            descriptions+=("$alias_name -> $alias_value")
            ((count++))
            if [[ $count -ge $limit ]]; then
                break
            fi
        fi
    done

    # Store results in global arrays
    typeset -gA _ZSH_ALIAS_HINTER_MATCH_VALUES
    typeset -ga _ZSH_ALIAS_HINTER_MATCHES
    _ZSH_ALIAS_HINTER_MATCHES=( "${matches[@]}" )
    _ZSH_ALIAS_HINTER_MATCH_VALUES=()
    for i in {1..${#matches[@]}}; do
        _ZSH_ALIAS_HINTER_MATCH_VALUES[${matches[$i]}]="${descriptions[$i]}"
    done

    # Output: matches and descriptions as arrays
    echo "${matches[@]}|${descriptions[@]}"
}

# CLI function to find aliases matching a command
findalias() {
    local query="$1"
    local limit="$2"
    if [[ -z "$query" ]]; then
        echo "Usage: findalias <command> [limit]"
        return 1
    fi
    _zsh_alias_hinter_get_matching_aliases "$query" "$limit" >/dev/null
    if [[ ${#_ZSH_ALIAS_HINTER_MATCHES[@]} -eq 0 ]]; then
        echo "No aliases found for: $query"
        return 0
    fi
    printf "Aliases for '%s':\n" "$query"
    local alias_name
    for alias_name in "${_ZSH_ALIAS_HINTER_MATCHES[@]}"; do
        local expansion="${_ZSH_ALIAS_HINTER_CACHE[$alias_name]}"
        printf "  %-20s → %s\n" "$alias_name" "$expansion"
    done
}

# Initialize cache on load (skip if mock is explicitly empty)
if [[ -z "$ZSH_ALIAS_HINTER_MOCK_ALIAS_OUTPUT" ]]; then
    _zsh_alias_hinter_build_cache
fi
