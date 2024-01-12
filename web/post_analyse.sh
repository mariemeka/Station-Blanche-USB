#!/bin/bash

# Emplacement du fichier de statut
status_file="/home/marieme/projet_stationblanche/Station-Blanche-USB/web/scanned_files/scan_results.txt"

#usbguard_rules="/etc/usbguard/rules.conf"
usbguard_rules="/home/marieme/projet_stationblanche/Station-Blanche-USB/station-blanche/rules.conf"


# Lire le statut depuis le fichier
status=$(cat "$status_file")


# Vérifier le statut du scan antivirus et mettre à jour les règles USBGuard
if echo "$status" | grep -q "Infected files: 0"; then
    # Aucun fichier infecté, autoriser la clé USB
    echo 'allow with-interface equals { 08:*:* }' > "$usbguard_rules"
    echo "Clé USB autorisée."
elif echo "$status" | grep -q "Infected files:"; then
    # Des fichiers sont infectés, bloquer la clé USB
    echo 'deny with-interface equals { 08:*:* }' > "$usbguard_rules"
    echo "Clé USB bloquée."
else
    echo "Statut inconnu : $status"
fi

