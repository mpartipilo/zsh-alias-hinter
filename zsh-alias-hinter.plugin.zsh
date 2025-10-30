#!/usr/bin/env zsh
# zsh-alias-hinter - Find aliases that match a command
# Main plugin file that sources the modular components

# Get the directory of this plugin file
typeset -g ZSH_ALIAS_HINTER_PLUGIN_DIR="${0:A:h}"

# Source the debug functionality
source "${ZSH_ALIAS_HINTER_PLUGIN_DIR}/zsh-alias-hinter-debug.zsh"

# Source the core functionality (cache and findalias)
source "${ZSH_ALIAS_HINTER_PLUGIN_DIR}/zsh-alias-hinter-core.zsh"

# Source the inline expansion display (optional - shows alias expansion as you type)
# Comment this out if you don't want inline hints
source "${ZSH_ALIAS_HINTER_PLUGIN_DIR}/zsh-alias-hinter-inline.zsh"

# Source the native completion display (optional - shows aliases in ZSH completion menu)
# Comment this out if you don't want completion-style display
source "${ZSH_ALIAS_HINTER_PLUGIN_DIR}/zsh-alias-hinter-completion.zsh"

# Source the fzf interactive selection (optional - requires fzf to be installed)
# Comment this out if you don't want fzf integration or don't have fzf
source "${ZSH_ALIAS_HINTER_PLUGIN_DIR}/zsh-alias-hinter-fzf.zsh"

# Source the cycling functionality (optional - cycle through matches with a keybinding)
source "${ZSH_ALIAS_HINTER_PLUGIN_DIR}/zsh-alias-hinter-cycle.zsh"

# Source the ZLE hooks
source "${ZSH_ALIAS_HINTER_PLUGIN_DIR}/zsh-alias-hinter-ui.zsh"
