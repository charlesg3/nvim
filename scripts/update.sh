#!/usr/bin/env bash
# Updates nvim itself and all submodule plugins, then pins and pushes.

NVIM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OS="$(uname -s)"

# ── Update nvim ───────────────────────────────────────────────────────────────

echo "=== Updating nvim ==="
CURRENT=$(nvim --version 2>/dev/null | head -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
LATEST=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    https://github.com/neovim/neovim/releases/latest 2>/dev/null \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')

if [[ -z "$LATEST" ]]; then
    echo "  nvim: could not fetch latest version (no internet?)"
elif [[ "$CURRENT" == "$LATEST" ]]; then
    echo "  nvim: already up to date ($CURRENT)"
elif [[ "$OS" == "Darwin" ]]; then
    echo "  nvim: updating $CURRENT → $LATEST via brew..."
    brew upgrade neovim 2>/dev/null && echo "  nvim: updated" || echo "  nvim: FAILED"
else
    echo "  nvim: updating $CURRENT → $LATEST..."
    TMP=$(mktemp -d)
    ARCH=$(uname -m)
    if curl -fsSLo "$TMP/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz"; then
        sudo tar -xzf "$TMP/nvim.tar.gz" -C /usr/local --strip-components=1
        echo "  nvim: updated to $(nvim --version | head -1)"
    else
        echo "  nvim: FAILED to download"
    fi
    rm -rf "$TMP"
fi

# ── Update plugins ────────────────────────────────────────────────────────────

echo ""
echo "=== Updating plugins ==="

cd "$NVIM_DIR"

# Record SHAs before update
declare -A BEFORE
while IFS= read -r line; do
    sha="${line:1:40}"
    name="$(basename "$(echo "$line" | awk '{print $2}')")"
    BEFORE[$name]="$sha"
done < <(git submodule status)

# Pull each submodule to latest on origin
git submodule update --remote --depth=1 2>/dev/null

# Report and collect updated plugins
UPDATED=()
while IFS= read -r line; do
    sha="${line:1:40}"
    name="$(basename "$(echo "$line" | awk '{print $2}')")"
    if [[ "${BEFORE[$name]}" != "$sha" ]]; then
        echo "  $name: updated"
        UPDATED+=("$name")
    else
        echo "  $name: already up to date"
    fi
done < <(git submodule status)

# ── Pin and push ──────────────────────────────────────────────────────────────

echo ""
if [ ${#UPDATED[@]} -gt 0 ]; then
    echo "Pinning updated plugins..."
    git add bundle/
    git commit -m "chore: update plugins ($(date +%Y-%m-%d))"
    git push
    echo "Pushed."
else
    echo "All plugins up to date."
fi
