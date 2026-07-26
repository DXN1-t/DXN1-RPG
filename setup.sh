#!/usr/bin/env bash
# ============================================================
# DXN1-RPG — Auto Setup Script
# Works on Termux, Linux, macOS
# ============================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║   🎮 DXN1-RPG — Auto Setup Script       ║"
echo "║   Made with ❤️  by DXN1                  ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── Detect environment ──
IS_TERMUX=false
if [ -d "/data/data/com.termux" ] || [ -n "$TERMUX_VERSION" ] || [ -f "/data/data/com.termux/files/usr/bin/pkg" ]; then
    IS_TERMUX=true
    echo -e "${YELLOW}📱 Detected: Termux${NC}"
else
    echo -e "${GREEN}💻 Detected: Standard Linux/macOS${NC}"
fi

# ── Detect Python ──
PYTHON=""
if command -v python3 &>/dev/null; then
    PYTHON="python3"
elif command -v python &>/dev/null; then
    PYTHON="python"
else
    echo -e "${RED}❌ Python not found. Installing...${NC}"
    if $IS_TERMUX; then
        pkg update -y
        pkg install -y python
    elif [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y python3 python3-pip
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y python3
    elif command -v brew &>/dev/null; then
        brew install python3
    else
        echo -e "${RED}❌ Could not auto-install Python. Please install Python 3.10+ manually.${NC}"
        exit 1
    fi
    PYTHON="python3"
fi

PY_VER=$($PYTHON -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
echo -e "${GREEN}✅ Python ${PY_VER} found at: $(which $PYTHON)${NC}"

# ── Install Termux system packages if needed ──
if $IS_TERMUX; then
    echo -e "${CYAN}📦 Installing Termux system packages...${NC}"
    pkg update -y 2>/dev/null || true
    pkg install -y python libjpeg-turbo libpng freetype 2>/dev/null || true

    # Ensure pip is available
    if ! $PYTHON -m pip --version &>/dev/null; then
        echo -e "${YELLOW}⚠️  pip not found, bootstrapping...${NC}"
        $PYTHON -m ensurepip --upgrade 2>/dev/null || {
            curl -sS https://bootstrap.pypa.io/get-pip.py | $PYTHON
        }
    fi
fi

# ── Install Python dependencies ──
echo -e "${CYAN}📦 Installing Python dependencies...${NC}"
$PYTHON -m pip install --upgrade pip 2>/dev/null || true

DEPS=("discord.py" "Pillow")
for dep in "${DEPS[@]}"; do
    if $PYTHON -c "import importlib; importlib.import_module('discord' if '$dep' == 'discord.py' else 'PIL')" 2>/dev/null; then
        echo -e "  ${GREEN}✅ $dep already installed${NC}"
    else
        echo -e "  ${YELLOW}📥 Installing $dep...${NC}"
        $PYTHON -m pip install "$dep" --break-system-packages 2>/dev/null || \
        $PYTHON -m pip install "$dep"
    fi
done

# ── Install fonts on Termux ──
if $IS_TERMUX; then
    echo -e "${CYAN}🔤 Installing fonts for item cards...${NC}"
    pkg install -y font-dejavu 2>/dev/null || true
fi

# ── Verify everything works ──
echo -e "\n${CYAN}🔍 Verifying installation...${NC}"
ERRORS=0

$PYTHON -c "import discord; print(f'  ✅ discord.py {discord.__version__}')" 2>/dev/null || {
    echo -e "  ${RED}❌ discord.py failed to import${NC}"
    ERRORS=$((ERRORS+1))
}

$PYTHON -c "from PIL import Image, ImageDraw, ImageFont; print('  ✅ Pillow (PIL) loaded')" 2>/dev/null || {
    echo -e "  ${RED}❌ Pillow failed to import${NC}"
    ERRORS=$((ERRORS+1))
}

$PYTHON -c "import sqlite3; print(f'  ✅ sqlite3 {sqlite3.sqlite_version}')" 2>/dev/null || {
    echo -e "  ${RED}❌ sqlite3 failed to import${NC}"
    ERRORS=$((ERRORS+1))
}

# ── Check fonts ──
FONT_OK=false
for FONT_PATH in \
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" \
    "$PREFIX/share/fonts/TTF/DejaVuSans-Bold.ttf" \
    "$PREFIX/share/fonts/dejavu/DejaVuSans-Bold.ttf" \
    "/data/data/com.termux/files/usr/share/fonts/TTF/DejaVuSans-Bold.ttf" \
    "$HOME/.local/share/fonts/DejaVuSans-Bold.ttf" \
    "$HOME/fonts/DejaVuSans-Bold.ttf"; do
    if [ -f "$FONT_PATH" ]; then
        echo -e "  ✅ Font found: $FONT_PATH"
        FONT_OK=true
        break
    fi
done

if ! $FONT_OK; then
    echo -e "  ${YELLOW}⚠️  No DejaVu fonts found — item cards will use default font (lower quality)${NC}"
    if $IS_TERMUX; then
        echo -e "  ${YELLOW}   Fix: pkg install font-dejavu${NC}"
    else
        echo -e "  ${YELLOW}   Fix: sudo apt install fonts-dejavu-core${NC}"
    fi
fi

echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Setup completed with ${ERRORS} error(s). Check above.${NC}"
    exit 1
fi

echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ All good! Ready to launch.          ║${NC}"
echo -e "${GREEN}║                                          ║${NC}"
echo -e "${GREEN}║   Run:  python3 bot_upgraded.py          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
