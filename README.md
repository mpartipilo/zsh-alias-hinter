
# ZSH Alias Hinter

ZSH Alias Hinter is a modular Zsh plugin that helps users discover, preview, and use shell aliases more efficiently. It provides multiple UI modes for alias hinting, inline expansion, completion, cycling, and interactive selection.

---

## What Does It Do?

ZSH Alias Hinter automatically detects your defined aliases and offers:

- **Inline Expansion:** Shows the expansion of an alias as you type, similar to zsh-autosuggestions, but for aliases.
- **Completion List:** Displays a list of matching aliases below the prompt, with descriptions, as you type.
- **Cycling:** Lets you cycle through available alias matches with a keybinding (default: Ctrl+N).
- **FZF Integration:** Interactive fuzzy search and selection of aliases using fzf (default key: Ctrl+F).
- **Space Reservation:** Prevents prompt scrolling by reserving space for alias hints.
- **Expansion Truncation:** Truncates long alias expansions to fit your terminal width.
- **Debug Logging:** Optional debug output to `/tmp/zsh-alias-hinter-debug.log` for troubleshooting.

---

## Module Overview

- **Core (`zsh-alias-hinter-core.zsh`):**
  - Caches all aliases and provides search/match logic.
  - Exposes the `findalias` CLI for searching aliases.
- **Inline (`zsh-alias-hinter-inline.zsh`):**
  - Displays alias expansions inline as you type.
  - Configurable minimum character threshold and color.
- **Completion (`zsh-alias-hinter-completion.zsh`):**
  - Shows a list of matching aliases below the prompt, with descriptions.
  - Configurable minimum characters and max display count.
- **Cycle (`zsh-alias-hinter-cycle.zsh`):**
  - Allows cycling through alias matches with a keybinding.
- **FZF (`zsh-alias-hinter-fzf.zsh`):**
  - Interactive fuzzy finder for alias selection (requires fzf).
  - Two widgets: search current buffer or select from all aliases.
- **Debug (`zsh-alias-hinter-debug.zsh`):**
  - Logs debug info to a file if enabled.
-- **Main Plugin (`zsh-alias-hinter.plugin.zsh`):**
  - Entry point that sources all modules. Comment/uncomment lines to enable/disable features.
- **UI (`zsh-alias-hinter-ui.zsh`):**
  - Centralizes ZLE hook registration and redraw logic for all UI modules. Should be sourced last.

---

## Configuration

All features are configurable via environment variables. Example:

```zsh
# Core
ZSH_ALIAS_HINTER_MAX_MATCHES=5

# Inline Expansion
ZSH_ALIAS_HINTER_INLINE_ENABLED=1
ZSH_ALIAS_HINTER_INLINE_MIN_CHARS=2
ZSH_ALIAS_HINTER_INLINE_COLOR=8

# Completion List
ZSH_ALIAS_HINTER_COMPLETION_ENABLED=1
ZSH_ALIAS_HINTER_COMPLETION_MIN_CHARS=2
ZSH_ALIAS_HINTER_COMPLETION_MAX_DISPLAY=10

# Cycling
ZSH_ALIAS_HINTER_CYCLING_ENABLED=1
ZSH_ALIAS_HINTER_CYCLING_KEY="^N"

# FZF
ZSH_ALIAS_HINTER_FZF_ENABLED=1
ZSH_ALIAS_HINTER_FZF_KEY="^F"
ZSH_ALIAS_HINTER_FZF_HEIGHT=40%
ZSH_ALIAS_HINTER_FZF_PROMPT="Aliases > "
ZSH_ALIAS_HINTER_FZF_OPTS="--reverse --border --info=inline"

# Space Reservation
ZSH_ALIAS_HINTER_RESERVE_SPACE=1
ZSH_ALIAS_HINTER_RESERVED_LINES=6

# Debug
ZSH_ALIAS_HINTER_DEBUG=1
ZSH_ALIAS_HINTER_DEBUG_LOG=/tmp/zsh-alias-hinter-debug.log
```

---

## Installation

### Requirements

- Zsh 5.9+
- fzf (optional, for interactive selection)
- zunit 0.8.2 (for running tests)

### Install zunit

```zsh
# Using antibody or similar
antibody bundle zunit-zsh/zunit

# Or manually
git clone https://github.com/zunit-zsh/zunit.git ~/.zunit
export PATH="$HOME/.zunit:$PATH"
```

---

## Usage

Source `zsh-alias-hinter.plugin.zsh` and then `zsh-alias-hinter-ui.zsh` in your `.zshrc` or plugin manager. Configure features as desired using the environment variables above.

---

## Running Tests

Run all tests:

```zsh
cd /Users/mpartipilo/.zsh-custom-plugins/zsh-alias-hinter
zunit
```

Run specific test file:

```zsh
zunit tests/extraction.zunit
zunit tests/cache.zunit
```

Run with verbose output:

```zsh
zunit --verbose
```

---

## Writing Tests

Each test file should:

1. Have a `@setup` block that sources the plugin
2. Use `@test` blocks for individual test cases
3. Use zunit assertions like `assert`, `same_as`, `equals`, etc.

Example:

```zsh
@test 'Description of test' {
        run some_command
        assert $state equals 0
        assert "$output" same_as "expected"
}
```

Enable debug mode in tests:

```zsh
@setup {
        export ZSH_ALIAS_HINTER_DEBUG=1
        source "${ZUNIT_SOURCE_DIR}/zsh-alias-hinter.plugin.zsh"
}
```

Check `/tmp/zsh-alias-hinter-debug.log` after running tests.

---

## Project Status


**Project Status (as of October 2025):**

- **Stable core and inline modules:** Core alias caching, search, and inline expansion are robust and well-tested.
- **Completion, cycling, and FZF modules:** All major UI modes are implemented and functional. FZF integration requires fzf to be installed.
- **Test coverage:** Most features are covered by zunit tests, but some edge cases and UI interactions may need more coverage.
- **Known limitations:**
  - Some advanced Zsh alias patterns may not be detected or displayed perfectly.
  - UI modules may behave differently depending on Zsh version and terminal emulator.
  - No support for remote alias sources or dynamic alias updates outside shell session.
- **Debugging:** Debug logging is available for troubleshooting, but not all errors are captured.
- **Next steps:**
  - Expand test coverage for edge cases and UI modules
  - Add more configuration options and user feedback integration
  - Optimize performance for large alias sets
  - Consider new UI features or integrations based on user requests

---

## License

MIT
