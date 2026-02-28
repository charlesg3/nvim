# Neovim Config

Personal Neovim configuration for macOS and Linux, managed as a git repo at `~/.config/nvim`. Plugins are tracked as git submodules under `bundle/` (pathogen-style). Config is primarily Vimscript (`init.vim`) with Lua embedded inline and in `after/ftplugin/` for filetype-specific behaviour.

## Guidelines

- **No `Co-Authored-By` lines in commits.** Never add `Co-Authored-By: Claude` or any AI attribution to commit messages.
- **Cross-platform**: changes should work on both macOS and Linux. Use `uname -s` / `$OSTYPE` checks where behaviour must differ.
- **Prefer editing `init.vim`** for global config. Use `after/ftplugin/<ft>.lua` for filetype-specific Lua (e.g. `yaml.lua`).
- **Plugins are submodules**: adding or removing a plugin means adding/removing a submodule under `bundle/`, not copying files.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/install.sh` | Install system dependencies (ctags, node, tree-sitter CLI, treesitter parsers, Nerd Font). Flags: `--python`, `--clojure`, `--go` for language-specific extras. Run on a fresh machine before first use. |
| `scripts/update.sh` | Update nvim itself and all submodule plugins to latest, then commit and push the pinned SHAs. |
| `scripts/copy-to.sh [user@host]` | Rsync the full config to a remote machine and set up shallow `.git` dirs for each plugin so `update.sh` works there too. |
| `scripts/package.sh` | Create a self-contained `.tar.gz` of the config (shallow-clones each plugin) for distribution without git access. |
| `scripts/copy-from.sh` | Pull config back from a remote machine. |

## Custom configurations

- **Taglist / outline** (`<C-e>`): toggles a symbol outline sidebar. Uses universal-ctags with custom settings for Clojure (`tlist_clojure_settings`) and Markdown (`tlist_markdown_settings`). For YAML files, `<C-e>` is overridden in `after/ftplugin/yaml.lua` with a treesitter-based outline that shows top-level and second-level keys in a left vertical split.
- **nvim-tree**: file explorer on `<C-t>`. `update_focused_file` is enabled so the tree always focuses on the current file when opened. `ff` reveals the current file. Inside the tree, `<C-t>` closes it.
- **EasyMotion**: `s` jumps to any visible location across all panes (2-char target).
- **render-markdown**: rich Markdown rendering in normal mode with treesitter highlighting.
- **ALE**: linting on save (not on text change). LSP navigation via `gd`, `gr`, `gh`.
- **Clojure / REPL**: fireplace + paredit. `<C-s>e` sends the current s-expression to a terminal REPL; `<C-s>s` sends a visual selection.
- **Treesitter parsers**: installed to `~/.local/share/nvim/site/parser/`. Currently: `markdown`, `markdown_inline`, `yaml`. Add new parsers via `install.sh` using the `install_ts_parser` helper.

## Keymap reference

`doc/keymap.md` is the human-readable keymap reference, opened with `km` inside nvim.

**Regenerate it whenever you add or change key bindings or install something that adds new keys.** Keep it accurate — it is the primary reference for what keys do what.

## claude-watcher (active development)

`bundle/claude-watcher/` is a **plain git repo**, not a submodule. `scripts/update.sh`
skips it to avoid `--depth=1 --force` wiping uncommitted changes.

Work directly inside `bundle/claude-watcher/`. Once development stabilises it will be
converted to a proper submodule tracked by this repo.
