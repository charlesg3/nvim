#!/usr/bin/env bash
# Updates nvim itself and all plugins to latest, then commits the pinned SHAs.
# When run as part of the dotfiles repo, also bumps the dotfiles nvim pointer.
# Safe to run repeatedly.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NVIM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$SCRIPT_DIR/common.sh"

OS="$(uname -s)"

# Detect whether we're a submodule inside a dotfiles repo
DOTFILES_DIR="$(cd "$NVIM_DIR/.." && pwd)"
if git -C "$DOTFILES_DIR" rev-parse --git-dir &>/dev/null \
    && [[ "$DOTFILES_DIR" != "$NVIM_DIR" ]]; then
    DOTFILES="$DOTFILES_DIR"
else
    DOTFILES=""
fi

# ── Nvim binary ───────────────────────────────────────────────────────────────

header "Nvim"

CURRENT=$(nvim --version 2>/dev/null | head -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "")
_spin "nvim"
LATEST=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    https://github.com/neovim/neovim/releases/latest 2>/dev/null \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "")
_clear_spin

if [[ -z "$LATEST" ]]; then
    warn "nvim ${DIM}$CURRENT${RESET} (could not check latest)"
elif [[ "$CURRENT" == "$LATEST" ]]; then
    ok "nvim ${DIM}$CURRENT${RESET}"
elif [[ "$OS" == "Darwin" ]]; then
    warn "nvim ${YELLOW}$CURRENT → $LATEST${RESET}, upgrading via brew..."
    brew upgrade neovim 2>/dev/null \
        && updated "nvim ${YELLOW}$CURRENT → $LATEST${RESET}" \
        || err "nvim update failed"
else
    warn "nvim ${YELLOW}$CURRENT → $LATEST${RESET}, downloading..."
    TMP=$(mktemp -d)
    ARCH=$(uname -m)
    if curl -fsSLo "$TMP/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz"; then
        sudo tar -xzf "$TMP/nvim.tar.gz" -C /usr/local --strip-components=1
        updated "nvim ${YELLOW}$CURRENT → $LATEST${RESET}"
    else
        err "nvim download failed"
    fi
    rm -rf "$TMP"
fi

# ── Plugins ───────────────────────────────────────────────────────────────────

header "Nvim plugins"

updated_plugins=()

for bundle_path in "$NVIM_DIR/bundle"/*/; do
    [ -d "$bundle_path" ] || continue
    name="$(basename "$bundle_path")"

    before_sha="$(git -C "$bundle_path" rev-parse --short HEAD 2>/dev/null || echo "")"

    _spin "$name"
    if git -C "$NVIM_DIR" submodule update --init --remote --depth=1 --force -- "bundle/$name" &>/dev/null; then
        after_sha="$(git -C "$bundle_path" rev-parse --short HEAD 2>/dev/null || echo "?")"
        _clear_spin
        if [[ -z "$before_sha" ]]; then
            updated "$name ${DIM}$after_sha${RESET}"
            updated_plugins+=("$name")
        elif [[ "$before_sha" != "$after_sha" ]]; then
            updated "$name ${YELLOW}$before_sha → $after_sha${RESET}"
            updated_plugins+=("$name")
        else
            ok "$name ${DIM}$after_sha${RESET}"
        fi
    else
        _clear_spin
        warn "$name (could not update)"
    fi
done

if [[ ${#updated_plugins[@]} -gt 0 ]]; then
    plugin_list="$(IFS=", "; echo "${updated_plugins[*]}")"
    _spin "committing plugin updates"
    git -C "$NVIM_DIR" add bundle/
    git -C "$NVIM_DIR" commit -m "chore: update plugins ($(date +%Y-%m-%d))

Updated: $plugin_list" &>/dev/null || true
    _clear_spin; ok "committed ${#updated_plugins[@]} plugin update(s) to nvim repo"

    # Bump the dotfiles nvim pointer if we're running as a submodule
    if [[ -n "$DOTFILES" ]]; then
        git -C "$DOTFILES" add nvim
        git -C "$DOTFILES" commit -m "chore: bump nvim plugins ($(date +%Y-%m-%d))" &>/dev/null || true
        ok "dotfiles nvim pointer updated"
    fi
fi
