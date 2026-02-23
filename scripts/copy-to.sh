#!/usr/bin/env bash
# Syncs nvim config to a remote machine via rsync.
#
# Usage:
#   ./copy-to.sh [user@]host
#
# Config files are rsynced (only changed files transferred, compressed).
# Bundle plugins are rsynced without .git history, then shallow .git dirs
# are set up on the remote so update.sh works there too.

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
NVIM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE_PATH=".config/nvim"

echo -e "${BOLD}Syncing nvim config to ${CYAN}${REMOTE}${RESET}${BOLD}...${RESET}\n"

# Ensure destination exists on remote
ssh "$REMOTE" "mkdir -p ~/${REMOTE_PATH}/bundle"

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
    "$NVIM_DIR/" "${REMOTE}:${REMOTE_PATH}/"

# ── Set up shallow .git dirs on remote ───────────────────────────────────────

echo -e "\n${CYAN}${BOLD}Setting up git remotes on ${REMOTE}...${RESET}"

# Build a remote script that shallow-clones each plugin's .git if missing
REMOTE_SCRIPT="set -e"$'\n'
for dir in "$NVIM_DIR"/bundle/*/; do
    name="$(basename "$dir")"
    if [ ! -d "$dir/.git" ]; then
        continue
    fi
    url=$(git -C "$dir" remote get-url origin 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        continue
    fi
    REMOTE_SCRIPT+="
name='$name'
url='$url'
dest=\"\$HOME/.config/nvim/bundle/\$name\"
if [ -d \"\$dest/.git\" ]; then
    git -C \"\$dest\" remote set-url origin \"\$url\" 2>/dev/null
    echo '  ✓ '\$name' (already has .git)'
else
    echo '  ~ '\$name': cloning shallow .git...'
    tmp=\$(mktemp -d)
    if git clone --depth=1 --no-checkout --quiet \"\$url\" \"\$tmp\" 2>/dev/null; then
        mv \"\$tmp/.git\" \"\$dest/.git\"
        echo '  ✓ '\$name
    else
        echo '  ✗ '\$name': clone failed (no internet on remote?)'
    fi
    rm -rf \"\$tmp\"
fi"
done

ssh "$REMOTE" "bash -s" <<< "$REMOTE_SCRIPT"

echo -e "\n${BOLD}${GREEN}Done!${RESET} Config synced to ${CYAN}${REMOTE}:~/${REMOTE_PATH}${RESET}"
echo -e "${CYAN}Tip:${RESET} On a fresh machine run ${BOLD}~/${REMOTE_PATH}/scripts/install.sh${RESET} first."
