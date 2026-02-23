#!/usr/bin/env bash
# Pulls nvim config FROM a remote machine to this machine.
# Useful when you can SSH *to* the remote but it cannot SSH back to you.
#
# Usage:
#   ./copy-from.sh [user@]host
#
# To use on a machine that has no copy of this config yet:
#   scp [user@]source:.config/nvim/scripts/copy-from.sh ~/
#   ~/copy-from.sh [user@]source

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [user@]host"
    exit 1
fi

REMOTE="$1"
REMOTE_PATH=".config/nvim"
LOCAL_PATH="$HOME/.config/nvim"

echo -e "${BOLD}Pulling nvim config from ${CYAN}${REMOTE}${RESET}${BOLD}...${RESET}\n"

mkdir -p "$LOCAL_PATH/bundle"

# ── Rsync config + plugin source files (no .git) ─────────────────────────────

echo -e "${CYAN}${BOLD}Transferring files...${RESET}"
rsync -az --progress --delete \
    --exclude='.git' \
    --include='init.vim' \
    --include='after'      --include='after/**' \
    --include='autoload'   --include='autoload/**' \
    --include='plugin'     --include='plugin/**' \
    --include='colors'     --include='colors/**' \
    --include='scripts'    --include='scripts/**' \
    --include='bin'        --include='bin/**' \
    --include='macros'     --include='macros/**' \
    --include='doc'        --include='doc/**' \
    --include='bundle'     --include='bundle/**' \
    --exclude='*' \
    "${REMOTE}:${REMOTE_PATH}/" "$LOCAL_PATH/"

# ── Set up shallow .git dirs locally ─────────────────────────────────────────

echo -e "\n${CYAN}${BOLD}Setting up git remotes...${RESET}"

# Query remote for each plugin's origin URL
PLUGIN_URLS=$(ssh "$REMOTE" 'bash -s' << 'ENDSSH'
for dir in ~/.config/nvim/bundle/*/; do
    [ -d "$dir/.git" ] || continue
    name="$(basename "$dir")"
    url=$(git -C "$dir" remote get-url origin 2>/dev/null || true)
    [[ -n "$url" ]] && echo "$name $url"
done
ENDSSH
)

while IFS=' ' read -r name url; do
    [[ -z "$name" ]] && continue
    dest="$LOCAL_PATH/bundle/$name"
    if [ -d "$dest/.git" ]; then
        git -C "$dest" remote set-url origin "$url" 2>/dev/null
        echo -e "  ✓ $name (already has .git)"
    else
        echo -e "  ~ $name: cloning shallow .git..."
        tmp=$(mktemp -d)
        if git clone --depth=1 --no-checkout --quiet "$url" "$tmp" 2>/dev/null; then
            mv "$tmp/.git" "$dest/.git"
            echo -e "  ✓ $name"
        else
            echo -e "  ✗ $name: clone failed (no internet?)"
        fi
        rm -rf "$tmp"
    fi
done <<< "$PLUGIN_URLS"

echo -e "\n${BOLD}${GREEN}Done!${RESET} Config pulled from ${CYAN}${REMOTE}:~/${REMOTE_PATH}${RESET}"
echo -e "${CYAN}Tip:${RESET} Run ${BOLD}~/${REMOTE_PATH}/scripts/install.sh${RESET} to install dependencies."
