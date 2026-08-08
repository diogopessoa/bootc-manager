#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Installing Bootc-Manager...${NC}"

IS_ROOT=false
if [ "$(id -u)" -eq 0 ]; then
  IS_ROOT=true
fi

USER_HOME="${HOME:-/root}"
BIN_PATH="/usr/local/bin/bootc-manager"

if [ "$IS_ROOT" = true ]; then
  DESKTOP_PATH="/usr/share/applications/bootc-manager.desktop"
  ICON_DIR="/usr/share/icons/hicolor/scalable/apps"
else
  DESKTOP_PATH="$USER_HOME/.local/share/applications/bootc-manager.desktop"
  ICON_DIR="$USER_HOME/.local/share/icons"
fi

ICON_PATH="$ICON_DIR/bootc-manager.svg"

mkdir -p "$ICON_DIR"
mkdir -p "$(dirname "$DESKTOP_PATH")"

SUDO=""
[ "$IS_ROOT" = false ] && SUDO="sudo"

$SUDO mkdir -p "$(dirname "$BIN_PATH")"

echo "Downloading main script..."
if ! $SUDO curl -fsSL "https://raw.githubusercontent.com/diogopessoa/bootc-manager/main/bootc-manager.sh" -o "$BIN_PATH"; then
    echo -e "${RED}Error downloading bootc-manager.sh${NC}"
    exit 1
fi
$SUDO chmod +x "$BIN_PATH"

echo "Downloading icon..."
curl -fsSL "https://raw.githubusercontent.com/diogopessoa/bootc-manager/main/bootc-manager.svg" -o "$ICON_PATH" || true

echo "Creating menu shortcut..."
cat <<EOF > "$DESKTOP_PATH"
[Desktop Entry]
Name=Bootc-Manager
Comment=Bootc Manager with Ease
Exec=$BIN_PATH
Icon=bootc-manager
Terminal=true
Type=Application
Categories=System;
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
  if [ "$IS_ROOT" = true ]; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
  else
    update-desktop-database "$USER_HOME/.local/share/applications" 2>/dev/null || true
  fi
fi

echo -e "${GREEN}Installation completed successfully!${NC}"
echo "You can launch it by typing 'bootc-manager' in your terminal."
