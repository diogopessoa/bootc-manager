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

# Diretório e caminho do ícone fixados no HOME do usuário real
ICON_DIR="$USER_HOME/.local/share/icons"
ICON_PATH="$ICON_DIR/bootc-manager.svg"

if [ "$IS_ROOT" = true ]; then
  DESKTOP_PATH="/usr/share/applications/bootc-manager.desktop"
else
  DESKTOP_PATH="$USER_HOME/.local/share/applications/bootc-manager.desktop"
fi

# Criar diretórios de destino
mkdir -p "$ICON_DIR"
mkdir -p "$(dirname "$DESKTOP_PATH")"

# Ajustar permissão do diretório do ícone caso tenha sido criado como root via sudo
if [ "$IS_ROOT" = true ] && [ -n "${SUDO_USER:-}" ]; then
  chown -R "$REAL_USER:" "$ICON_DIR"
fi

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
if [ "$IS_ROOT" = true ] && [ -n "${SUDO_USER:-}" ]; then
  # Baixa o ícone com a identidade do usuário comum para evitar conflito de permissão no HOME
  sudo -u "$REAL_USER" curl -fsSL "https://raw.githubusercontent.com/diogopessoa/bootc-manager/main/bootc-manager.svg" -o "$ICON_PATH" || true
else                                       
  curl -fsSL "https://raw.githubusercontent.com/diogopessoa/bootc-manager/main/bootc-manager.svg" -o "$ICON_PATH" || true
fi

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
