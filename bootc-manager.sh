#!/usr/bin/env bash
# ==============================================================================
# PROJECT: Bootc Manager - Simple and Ease
# AUTHOR:  Diogo Pessoa (https://github.com/diogopessoa/bootc-manager/)
# LICENSE: MIT
# ==============================================================================

set -u

VERSION="0.3.0"
REPO_API_URL="https://api.github.com/repos/diogopessoa/bootc-manager/releases"
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
CONFIG_FILE="/etc/bootc-manager.conf"

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

UPDATE_STATUS=""
BACKEND=""
HAS_LAYERING=0
PREFER_DRY_RUN=0

# --- Terminal check (Ptyxis / GNOME Terminal) ---
SCRIPT_PATH=$(readlink -f "$0")
if [[ ! -t 0 ]]; then
    if command -v ptyxis &>/dev/null; then
        exec ptyxis -- bash -c "$SCRIPT_PATH; echo; read -p 'Press Enter to exit...' -n1"
    elif command -v gnome-terminal &>/dev/null; then
        exec gnome-terminal -- bash -c "$SCRIPT_PATH; echo; read -p 'Press Enter to exit...' -n1"
    fi
    exit 0
fi

# --- Config loading ---
load_config() {
    PREFER_DRY_RUN=0
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE" 2>/dev/null || true
    fi
}

# --- Update check do próprio script ---
check_update() {
    if ! command -v jq &>/dev/null || ! command -v curl &>/dev/null; then
        return
    fi

    local latest_version
    latest_version=$(curl -s --connect-timeout 2 "$REPO_API_URL" | jq -r '.[0].tag_name' 2>/dev/null | sed 's/v//' | xargs)

    if [[ -n "$latest_version" && "$latest_version" != "null" ]]; then
        if [[ "$latest_version" != "$VERSION" ]]; then
            UPDATE_STATUS="${PURPLE}${BOLD}New version available: v$latest_version${NC}\n${PURPLE}Update at: github.com/diogopessoa/bootc-manager${NC}"
        else
            UPDATE_STATUS="${GREEN}✔ Script up to date (v$VERSION)${NC}"
        fi
    fi
}

# --- Detecção de backend e mutações locais ---
detect_backend() {
    if command -v bootc &>/dev/null; then
        BACKEND="bootc"
    elif command -v rpm-ostree &>/dev/null; then
        BACKEND="rpm-ostree"
    else
        BACKEND="unknown"
    fi
}

check_local_mutations() {
    HAS_LAYERING=0

    if ! command -v rpm-ostree &>/dev/null; then
        return
    fi

    local status_json
    status_json=$(sudo rpm-ostree status --json 2>/dev/null) || return

    if echo "$status_json" | jq -e '
        .deployments[] |
        select(.booted == true) |
        ((.packages? // []) + (.local_packages? // []) + (."local-packages"? // [])) |
        length > 0
    ' &>/dev/null; then
        HAS_LAYERING=1
    fi
}

# --- Status ---
bootc_status() {
    echo -e "\n--- ${CYAN}System Status${NC} ---\n"

    if [[ "$BACKEND" == "bootc" ]]; then
        sudo bootc status
    elif [[ "$BACKEND" == "rpm-ostree" ]]; then
        sudo rpm-ostree status
    else
        echo -e "${RED}No supported backend found (bootc / rpm-ostree).${NC}"
    fi

    echo
}

# --- Upgrade ---
bootc_upgrade() {
    echo -e "\n--- ${GREEN}System Upgrade${NC} ---\n"

    if [[ "$HAS_LAYERING" -eq 1 ]]; then
        echo -e "${RED}Warning: local package layering detected.${NC}"
        echo -e "${RED}bootc upgrade may fail until these changes are removed.${NC}"
        echo
    fi

    local do_dry_run=0
    if [[ "$PREFER_DRY_RUN" -eq 1 ]]; then
        do_dry_run=1
    fi

    if [[ "$BACKEND" == "bootc" ]]; then
        if [[ "$do_dry_run" -eq 1 ]]; then
            echo -e "${BLUE}Dry-run mode: checking system status...${NC}"
            sudo bootc status
            echo -e "\n${PURPLE}No changes applied (dry-run mode active).${NC}"
        else
            read -p "Do you want to run 'bootc upgrade'? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                if sudo bootc upgrade; then
                    echo -e "\n${GREEN}Upgrade scheduled! Reboot to apply.${NC}"
                else
                    echo -e "\n${RED}Upgrade failed or was cancelled.${NC}"
                fi
            else
                echo -e "\n${PURPLE}Upgrade cancelled by user.${NC}"
            fi
        fi
    elif [[ "$BACKEND" == "rpm-ostree" ]]; then
        echo -e "${BLUE}Bootc not detected. Using rpm-ostree upgrade instead.${NC}"
        if [[ "$do_dry_run" -eq 1 ]]; then
            echo -e "${BLUE}Dry-run mode: checking for available updates...${NC}"
            sudo rpm-ostree upgrade --check
            echo -e "\n${PURPLE}No changes applied (dry-run).${NC}"
        else
            read -p "Do you want to run 'rpm-ostree upgrade'? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                if sudo rpm-ostree upgrade; then
                    echo -e "\n${GREEN}Upgrade scheduled! Reboot to apply.${NC}"
                else
                    echo -e "\n${RED}Upgrade failed or was cancelled.${NC}"
                fi
            else
                echo -e "\n${PURPLE}Upgrade cancelled by user.${NC}"
            fi
        fi
    else
        echo -e "${RED}No supported backend for upgrade.${NC}"
    fi

    echo
    read -p "Press Enter to return..."
}

# --- Rollback ---
bootc_rollback() {
    echo -e "\n--- ${GREEN}System Rollback${NC} ---\n"

    if [[ "$BACKEND" == "bootc" ]]; then
        read -p "Do you want to run 'bootc rollback'? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            if sudo bootc rollback; then
                echo -e "\n${GREEN}Rollback successful! Reboot to use previous deployment.${NC}"
            else
                echo -e "\n${RED}Rollback failed or was cancelled.${NC}"
            fi
        else
            echo -e "\n${PURPLE}Rollback cancelled by user.${NC}"
        fi
    elif [[ "$BACKEND" == "rpm-ostree" ]]; then
        echo -e "${BLUE}Bootc not detected. Using rpm-ostree rollback instead.${NC}"
        read -p "Do you want to run 'rpm-ostree rollback'? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            if sudo rpm-ostree rollback; then
                echo -e "\n${GREEN}Rollback successful! Reboot to use previous deployment.${NC}"
            else
                echo -e "\n${RED}Rollback failed or was cancelled.${NC}"
            fi
        else
            echo -e "\n${PURPLE}Rollback cancelled by user.${NC}"
        fi
    else
        echo -e "${RED}No supported backend for rollback.${NC}"
    fi

    echo
    read -p "Press Enter to return..."
}

# --- Switch image/ref ---
bootc_switch() {
    echo -e "\n--- ${CYAN}Switch Image Reference${NC} ---\n"

    echo -e "Example OCI container image references:"
    echo -e "  quay.io/fedora-ostree-desktops/kinoite"
    echo -e "  quay.io/fedora-ostree-desktops/cosmic-atomic"
    echo -e "  quay.io/fedora-ostree-desktops/silverblue"
    echo

    read -rp "Enter target container image (or press Enter to cancel): " new_ref

    if [[ -z "$new_ref" ]]; then
        echo -e "${PURPLE}Switch cancelled by user.${NC}\n"
        read -p "Press Enter to return..."
        return
    fi

    if [[ "$BACKEND" == "bootc" ]]; then
        read -p "Confirm switch to '$new_ref'? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            if sudo bootc switch "$new_ref"; then
                echo -e "\n${GREEN}Switch scheduled! Reboot to use new image.${NC}"
            else
                echo -e "\n${RED}Switch failed or was cancelled.${NC}"
            fi
        else
            echo -e "\n${PURPLE}Switch cancelled by user.${NC}"
        fi
    else
        echo -e "${RED}Switch is only supported with the bootc backend.${NC}"
    fi

    echo
    read -p "Press Enter to return..."
}

# --- Ajuda ---
show_help() {
    clear
    echo -e "${BLUE}╭──────────────────────────────────────────────────────────╮${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}QUICK DOCUMENTATION & HELP${NC} ${BLUE}│${NC}"
    echo -e "${BLUE}╰──────────────────────────────────────────────────────────╯${NC}\n"

    echo -e "1) Upgrade: Updates the system image using bootc or rpm-ostree."
    echo -e "2) Rollback: Reverts to the previous deployment on next boot."
    echo -e "3) Switch: Changes the OS container image target."
    echo -e "4) Status: Shows detailed technical state of your OS."
    echo -e "\n${BLUE}────────────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}Configuration file:${NC} $CONFIG_FILE"
    echo -e "\n${BOLD}For full guide, visit:${NC}"
    echo -e "https://github.com/diogopessoa/bootc-manager/wiki"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}\n"

    read -p "Press Enter to return to menu..."
}

# --- Menu ---
show_menu() {
    clear

    echo "======================================"
    echo -e " ${BOLD}Bootc Manager${NC}"
    echo " Version $VERSION"
    echo "======================================"
    echo

    if [[ -n "$UPDATE_STATUS" ]]; then
        echo -e "$UPDATE_STATUS\n"
    fi

    if [[ "$BACKEND" == "unknown" ]]; then
        echo -e "${RED}No supported backend detected (bootc / rpm-ostree).${NC}\n"
    else
        echo -e "${GREEN}Backend:${NC} $BACKEND"
    fi

    if [[ "$HAS_LAYERING" -eq 1 ]]; then
        echo -e "${RED}Warning: Local package layering detected.${NC}"
    fi

    echo
    echo "[1] Upgrade system"
    echo "[2] Rollback to previous deployment"
    echo "[3] Switch container image"
    echo "[4] Status"
    echo "[5] Documentation & Help"
    echo "[0] Exit"

    echo
    echo -e "${BLUE}────────────────────────────────────${NC}"
    echo -ne "${GREEN}Option [0-5]:${NC} "
}

# --- Main ---
main() {
    load_config
    detect_backend
    check_local_mutations
    check_update

    while true; do
        show_menu
        read -r opt

        case "$opt" in
            1) bootc_upgrade ;;
            2) bootc_rollback ;;
            3) bootc_switch ;;
            4) clear; bootc_status; read -p "Press Enter to return..." ;;
            5) show_help ;;
            0)
                clear
                echo -e "\nhttps://github.com/diogopessoa/bootc-manager\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

main
