#!/usr/bin/env bash
# Installs system dependencies for nvim plugins.
#
# Usage:
#   ./install.sh [--python] [--clojure] [--go]
#
# Flags:
#   --python    Install Python-specific dependencies (python3, ruff, pyright)
#   --clojure   Install Clojure-specific dependencies (java, clojure cli, clojure-lsp)
#   --go        Install Go-specific dependencies (go, gopls, vim-go binaries)
#
# Only core dependencies are installed by default.

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

INSTALL_PYTHON=false
INSTALL_CLOJURE=false
INSTALL_GO=false

for arg in "$@"; do
    case $arg in
        --python)  INSTALL_PYTHON=true ;;
        --clojure) INSTALL_CLOJURE=true ;;
        --go)      INSTALL_GO=true ;;
        *)
            echo -e "${RED}Unknown option: $arg${RESET}"
            echo "Usage: $0 [--python] [--clojure] [--go]"
            exit 1
            ;;
    esac
done

# ── OS detection ─────────────────────────────────────────────────────────────

OS="$(uname -s)"

install_pkg() {
    local pkg="$1"
    echo -e "  ${DIM}Installing $pkg...${RESET}"
    if [[ "$OS" == "Darwin" ]]; then
        brew install "$pkg"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$pkg"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$pkg"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    else
        echo -e "  ${RED}✗ Cannot install $pkg — no supported package manager found${RESET}"
        return 1
    fi
}

check_or_install() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} $cmd"
    else
        echo -e "  ${YELLOW}~${RESET} $cmd not found, installing..."
        install_pkg "$pkg"
        echo -e "  ${GREEN}✓${RESET} $cmd installed"
    fi
}

# ── Header ────────────────────────────────────────────────────────────────────

echo -e "${BOLD}nvim dependency installer${RESET}"
echo -e "${DIM}OS: $OS${RESET}"
echo -e "${DIM}Options: python=$INSTALL_PYTHON, clojure=$INSTALL_CLOJURE, go=$INSTALL_GO${RESET}\n"

# ── Core ──────────────────────────────────────────────────────────────────────

echo -e "${CYAN}${BOLD}Core${RESET}"
check_or_install git
# universal-ctags (supports markdown; macOS is keg-only so check explicit path)
if [[ "$OS" == "Darwin" ]]; then
    if [[ -x /opt/homebrew/opt/universal-ctags/bin/ctags || -x /usr/local/opt/universal-ctags/bin/ctags ]]; then
        echo -e "  ${GREEN}✓${RESET} universal-ctags"
    else
        echo -e "  ${YELLOW}~${RESET} universal-ctags not found, installing..."
        brew install universal-ctags
        echo -e "  ${GREEN}✓${RESET} universal-ctags installed"
    fi
else
    UCTAGS=$( (command -v ctags && ctags --version 2>&1 | grep -qi universal && echo yes) 2>/dev/null || true)
    if [[ -n "$UCTAGS" ]]; then
        echo -e "  ${GREEN}✓${RESET} universal-ctags"
    else
        echo -e "  ${YELLOW}~${RESET} universal-ctags not found, installing..."
        install_pkg universal-ctags
        echo -e "  ${GREEN}✓${RESET} universal-ctags installed"
    fi
fi

# Node: require v18+
NODE_MIN=22
install_node_linux() {
    echo -e "  ${YELLOW}~${RESET} Installing Node.js v${NODE_MIN} via NodeSource..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MIN}.x" | sudo -E bash - 2>/dev/null
    sudo apt-get install -y nodejs
    echo -e "  ${GREEN}✓${RESET} node $(node --version) installed"
}
if command -v node &>/dev/null; then
    NODE_VER=$(node -e "process.exit(parseInt(process.versions.node))" 2>/dev/null; echo $?)
    if [[ $NODE_VER -lt $NODE_MIN ]]; then
        echo -e "  ${YELLOW}~${RESET} node $(node --version) is too old (need v${NODE_MIN}+)"
        if [[ "$OS" != "Darwin" ]]; then
            install_node_linux
        else
            echo -e "  ${RED}✗${RESET} Run: brew upgrade node"
            exit 1
        fi
    else
        echo -e "  ${GREEN}✓${RESET} node $(node --version)"
    fi
else
    if [[ "$OS" == "Darwin" ]]; then
        install_pkg node
    else
        install_node_linux
    fi
fi
check_or_install npm
if ! command -v tree-sitter &>/dev/null; then
    echo -e "  ${YELLOW}~${RESET} tree-sitter CLI not found, installing via npm..."
    sudo npm install -g tree-sitter-cli
    echo -e "  ${GREEN}✓${RESET} tree-sitter CLI installed"
else
    echo -e "  ${GREEN}✓${RESET} tree-sitter"
fi

# ── Python ────────────────────────────────────────────────────────────────────

if [[ "$INSTALL_PYTHON" == true ]]; then
    echo -e "\n${CYAN}${BOLD}Python${RESET}"
    check_or_install python3
    if command -v ruff &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} ruff"
    else
        echo -e "  ${YELLOW}~${RESET} ruff not found, installing via standalone installer..."
        curl -LsSf https://astral.sh/ruff/install.sh | sudo sh
        echo -e "  ${GREEN}✓${RESET} ruff installed"
    fi

    if ! command -v pyright-langserver &>/dev/null; then
        echo -e "  ${YELLOW}~${RESET} pyright not found, installing via npm..."
        sudo npm install -g pyright
        echo -e "  ${GREEN}✓${RESET} pyright installed"
    else
        echo -e "  ${GREEN}✓${RESET} pyright"
    fi
fi

# ── Go ────────────────────────────────────────────────────────────────────────

if [[ "$INSTALL_GO" == true ]]; then
    echo -e "\n${CYAN}${BOLD}Go${RESET}"
    check_or_install go golang

    echo -e "  ${DIM}Installing vim-go binaries (gopls, etc.)...${RESET}"
    nvim +GoInstallBinaries +qa
    echo -e "  ${GREEN}✓${RESET} vim-go binaries"
fi

# ── Clojure ───────────────────────────────────────────────────────────────────

if [[ "$INSTALL_CLOJURE" == true ]]; then
    echo -e "\n${CYAN}${BOLD}Clojure${RESET}"
    check_or_install java openjdk

    check_or_install clojure

    if ! command -v clojure-lsp &>/dev/null; then
        echo -e "  ${YELLOW}~${RESET} clojure-lsp not found, installing..."
        if [[ "$OS" == "Darwin" ]]; then
            brew install clojure-lsp/brew/clojure-lsp
        else
            curl -sLo /tmp/clojure-lsp.zip "https://github.com/clojure-lsp/clojure-lsp/releases/latest/download/clojure-lsp-native-linux-amd64.zip"
            sudo unzip -o /tmp/clojure-lsp.zip -d /usr/local/bin/
            sudo chmod +x /usr/local/bin/clojure-lsp
            rm /tmp/clojure-lsp.zip
        fi
        echo -e "  ${GREEN}✓${RESET} clojure-lsp installed"
    else
        echo -e "  ${GREEN}✓${RESET} clojure-lsp"
    fi
fi

# ── Treesitter parsers ───────────────────────────────────────────────────────

echo -e "\n${CYAN}${BOLD}Treesitter parsers${RESET}"

PARSER_DIR="$HOME/.local/share/nvim/site/parser"
mkdir -p "$PARSER_DIR"
CACHE_DIR="$HOME/.cache/nvim"

install_ts_parser() {
    local name="$1"
    local src_dir="$2"

    if [ -f "$PARSER_DIR/${name}.so" ]; then
        echo -e "  ${GREEN}✓${RESET} $name parser already installed"
        return
    fi

    echo -e "  ${YELLOW}~${RESET} Installing $name parser..."
    nvim --headless -c "TSInstall! $name" -c "sleep 20" -c "qa!" 2>/dev/null
    # Build manually from cached source if nvim didn't finish
    if [ ! -f "$PARSER_DIR/${name}.so" ] && [ -d "$CACHE_DIR/$src_dir" ]; then
        tree-sitter build -o "$PARSER_DIR/${name}.so" "$CACHE_DIR/$src_dir" 2>/dev/null
    fi

    if [ -f "$PARSER_DIR/${name}.so" ]; then
        echo -e "  ${GREEN}✓${RESET} $name parser installed"
    else
        echo -e "  ${RED}✗${RESET} $name parser failed to install"
    fi
}

install_ts_parser "markdown" "tree-sitter-markdown/tree-sitter-markdown"
install_ts_parser "markdown_inline" "tree-sitter-markdown_inline/tree-sitter-markdown-inline"
install_ts_parser "yaml" "tree-sitter-yaml/tree-sitter-yaml"

# ── Nerd Font (required for airline arrows + nvim-tree icons) ────────────────

echo -e "\n${CYAN}${BOLD}Nerd Font${RESET}"

FONT_NAME="JetBrainsMono"

if [[ "$OS" == "Darwin" ]]; then
    if ls "$HOME/Library/Fonts"/JetBrainsMonoNerdFont* &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} $FONT_NAME Nerd Font already installed"
    else
        echo -e "  ${YELLOW}~${RESET} Installing $FONT_NAME Nerd Font via brew..."
        brew tap homebrew/cask-fonts 2>/dev/null || true
        brew install --cask font-jetbrains-mono-nerd-font
        echo -e "  ${GREEN}✓${RESET} $FONT_NAME Nerd Font installed"
    fi
else
    FONT_DIR="/usr/local/share/fonts/NerdFonts"
    if ls "$FONT_DIR"/JetBrainsMonoNerdFont* &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} $FONT_NAME Nerd Font already installed"
    else
        echo -e "  ${YELLOW}~${RESET} Downloading $FONT_NAME Nerd Font..."
        sudo mkdir -p "$FONT_DIR"
        TMP=$(mktemp -d)
        curl -fLo "$TMP/${FONT_NAME}.zip" \
            "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
        sudo unzip -q "$TMP/${FONT_NAME}.zip" '*.ttf' -d "$FONT_DIR"
        rm -rf "$TMP"
        sudo fc-cache -f "$FONT_DIR"
        echo -e "  ${GREEN}✓${RESET} $FONT_NAME Nerd Font installed"
    fi
fi

echo -e "  ${DIM}Remember to set your terminal font to '${FONT_NAME} Nerd Font'${RESET}"

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}All done!${RESET}"
