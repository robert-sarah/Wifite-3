WIFITE 3 - Levi Edition
Auteur : Levi
Version : 3.0
Date : 2025

Description
WIFITE 3 Levi Edition est un outil avancé de pentesting Wi-Fi écrit en Bash.
Il permet de scanner les réseaux Wi-Fi, de capturer des handshakes WPA/WPA2, et de lancer diverses attaques (Deauth, PMKID, WPS) avec une interface utilisateur interactive basée sur dialog.

Fonctionnalités
Détection automatique de l’interface Wi-Fi compatible et activation du mode monitor

Scan interactif des réseaux Wi-Fi avec affichage de la puissance, sécurité, canal, SSID

Mode automatique complet : scan, sélection de la meilleure cible, attaque Deauth, capture handshake

Attaques avancées : PMKID (via hcxdumptool), WPS (via reaver)

Multi-threading simple (scan et attaque simultanée)

Interface utilisateur conviviale avec menus, barres de progression, affichage des logs en temps réel

Nettoyage et restauration réseau propres en cas d’interruption

Support multilingue (français/anglais)

Logs et sauvegardes dans un dossier dédié

Prérequis
Système Linux (Kali, Ubuntu, Parrot, Debian)

Droits root (sudo) pour exécuter les commandes Wi-Fi

Les outils suivants doivent être installés :

aircrack-ng (airmon-ng, airodump-ng, aireplay-ng)

dialog

figlet

hcxdumptool

hcxpcaptool

reaver

iw

Installation
Cloner ou télécharger le projet.

Rendre le script d’installation exécutable et lancer :

bash
Copier
Modifier
chmod +x install.sh
./install.sh
Cela installera toutes les dépendances nécessaires.

Utilisation
Lance le script en root :

bash
Copier
Modifier
sudo ./wifite3_levi.sh
Options disponibles :

Choisir la langue (français ou anglais)

Sélectionner l’interface Wi-Fi (en mode monitor)

Scanner les réseaux avec interface graphique dialog

Mode automatique : lance attaque Deauth + capture handshake + attaques avancées

Menu pour attaques manuelles (PMKID, WPS)

Affichage des logs en temps réel

Nettoyage propre et restauration du réseau à la sortie

Aide
Pour afficher l’aide intégrée :

bash
Copier
Modifier
sudo ./wifite3_levi.sh --help
Sécurité & Limitations
Utiliser uniquement sur des réseaux dont vous avez l’autorisation de tester la sécurité.

Nécessite un adaptateur Wi-Fi compatible mode monitor.

Certaines attaques nécessitent des outils spécifiques (hcxdumptool, reaver).

Contributions
Ce projet est en développement, contributions bienvenues !
Contact : Levi

Licence
À usage personnel et éducatif uniquement.