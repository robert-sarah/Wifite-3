#!/bin/bash
# ===========================================
#      WIFITE 3 - Version PRO
#      Auteur : Levi
#      Date : 2025
# ===========================================

set -euo pipefail

# === Variables globales ===
VERSION="3.0"
TMPDIR=$(mktemp -d)
LOGDIR="./wifite3_logs"
mkdir -p "$LOGDIR"
HANDSHAKE_DIR="$LOGDIR/handshakes"
PMKID_DIR="$LOGDIR/pmkid"
LOGFILE="$LOGDIR/session_$(date +%F_%H-%M-%S).log"
LANGUAGE="FR"
INTERFACE=""
MONITOR_INTERFACE=""
TIMEOUT_SCAN=30
TIMEOUT_HANDSHAKE=120

# === Couleurs ===
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# === Trap interruptions ===
cleanup() {
    dialog --infobox "Nettoyage en cours..." 5 40
    pkill -f "airodump-ng" || true
    pkill -f "aireplay-ng" || true
    pkill -f "hcxdumptool" || true
    pkill -f "reaver" || true
    if [[ -n "${MONITOR_INTERFACE:-}" ]]; then
        airmon-ng stop "$MONITOR_INTERFACE" &>/dev/null || true
    fi
    restore_network
    rm -rf "$TMPDIR"
    chmod 600 "$LOGDIR"/*
}
trap cleanup EXIT INT TERM

# === Bannière ===
banner() {
    clear
    echo -e "\n${CYAN}"
    figlet -f slant "WIFITE 3"
    echo -e "${RESET}"
    echo "Version $VERSION | By Levi"
    echo "----------------------------------"
}

# === Détection outils ===
check_tools() {
    REQUIRED=("airmon-ng" "airodump-ng" "aireplay-ng" "dialog")
    for tool in "${REQUIRED[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo "${RED}[!] $tool manquant.${RESET}"
            echo "Installe avec : sudo apt install aircrack-ng dialog"
            exit 1
        fi
    done
}

# === Restaure réseau ===
restore_network() {
    if systemctl list-unit-files | grep -q NetworkManager; then
        systemctl start NetworkManager || true
    elif systemctl list-unit-files | grep -q wpa_supplicant; then
        systemctl start wpa_supplicant || true
    fi
}

# === Menu langue ===
choose_lang() {
    choice=$(dialog --stdout --title "Language" --menu "Choose language" 10 50 2 \
        1 "Français" \
        2 "English")
    [[ $choice == 2 ]] && LANGUAGE="EN"
}

# === Choix interface ===
choose_interface() {
    interfaces=($(iw dev | grep Interface | awk '{print $2}'))
    options=()
    for i in "${interfaces[@]}"; do
        options+=("$i" "Interface Wi-Fi")
    done
    INTERFACE=$(dialog --stdout --title "Interface" --menu "Sélectionne l'interface" 20 60 10 "${options[@]}")
    [[ -z "$INTERFACE" ]] && exit 0
    enable_monitor "$INTERFACE"
}

# === Activer mode monitor ===
enable_monitor() {
    iface="$1"
    airmon-ng check kill
    airmon-ng start "$iface" >/dev/null
    MONITOR_INTERFACE="${iface}mon"
}

# === Scan + affichage logs ===
scan_networks() {
    dialog --infobox "Scan en cours ($TIMEOUT_SCAN sec)..." 5 50
    airodump-ng --write "$TMPDIR/scan" --output-format csv "$MONITOR_INTERFACE" >/dev/null &
    PID=$!
    for i in $(seq 0 $TIMEOUT_SCAN); do
        sleep 1
        echo $((i * 100 / TIMEOUT_SCAN)) | dialog --gauge "Scanning networks..." 10 70
    done
    kill $PID
}

# === Lister réseaux ===
list_networks() {
    awk -F',' '/WPA|WEP|OPN/ {print NR,$1,$4,$6,$9,$14}' "$TMPDIR/scan-01.csv" | sed 's/ //g'
}

# === Mode auto complet ===
auto_mode() {
    scan_networks
    best=$(awk -F',' '/WPA/ {print $6,$8}' "$TMPDIR/scan-01.csv" | sort -k2 -nr | head -1 | awk '{print $1}')
    dialog --msgbox "Meilleur réseau détecté : $best\nAttaque handshake..." 8 50
    capture_handshake "$best"
}

# === Capture Handshake ===
capture_handshake() {
    mkdir -p "$HANDSHAKE_DIR"
    dialog --tailbox "$LOGFILE" 20 80 &
    airodump-ng --bssid "$1" -c "$2" -w "$HANDSHAKE_DIR/handshake" "$MONITOR_INTERFACE" >>"$LOGFILE" 2>&1
}

# === Multi-thread : Scan + attaque en même temps ===
multi_thread() {
    scan_networks &
    capture_handshake "$1" &
    wait
}

# === Menu principal ===
main_menu() {
    choice=$(dialog --stdout --title "WIFITE 3" --menu "Choisis une action" 20 60 10 \
        1 "Mode automatique" \
        2 "Scan et sélection manuelle" \
        3 "Attaques avancées (WPS, PMKID, WEP)" \
        4 "Voir logs" \
        5 "Quitter")
    case $choice in
    1) auto_mode ;;
    2) scan_networks ;;
    3) dialog --msgbox "Attaques avancées à implémenter" 8 50 ;;
    4) dialog --tailbox "$LOGFILE" 20 80 ;;
    5) exit 0 ;;
    esac
}

# === MAIN ===
banner
check_tools
choose_lang
choose_interface
main_menu
