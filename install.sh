#!/bin/bash
echo "[*] Mise à jour des paquets..."
sudo apt update

echo "[*] Installation des dépendances nécessaires..."
sudo apt install -y aircrack-ng dialog figlet hcxdumptool hcxpcaptool reaver iw

echo "[*] Installation terminée !"
echo "Tu peux maintenant lancer ton script avec : sudo ./wifite3.sh"
