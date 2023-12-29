#!/bin/bash


python_script_path="/home/marieme/Station-Blanche-USB/w/extraction_hash.py"

# Emplacement du répertoire où la clé USB sera montée
mount_point="/mnt"

# Emplacement du fichier de résultats de la numérisation
result_file="/home/marieme/Station-Blanche-USB/web/scanned_files/scan_results.txt"

# Emplacement du fichier d'informations sur la clé USB
usb_info_file="/home/marieme/Station-Blanche-USB/web/usb_info.txt"

# Emplacement du fichier de logs pour les erreurs
log_file="/home/marieme/Station-Blanche-USB/web/error_logs.log"

# Vérifier si le périphérique USB est connecté
usb_device="/dev/sdc"

#echo "Début du script"
if mount | grep "$mount_point"; then
    echo "Le périphérique est déjà monté."
else
    mount "$usb_device" "$mount_point"
fi

# Obtenez l'identifiant unique du périphérique USB
usb_id=$(udevadm info -q property -n "$usb_device" | grep ID_SERIAL_SHORT | cut -d "=" -f 2)

if [ -b "$usb_device" ]; then
    # Calculer le hash global des fichiers sur la clé USB
    full_hash=""
    for file in $(find "$mount_point" -type f); do
        file_hash=$(sha256sum "$file" | awk '{print $1}')
        full_hash="${full_hash}${file_hash}"
    done

    
    combined_hash=$(echo -n "$full_hash" | sha256sum | awk '{print $1}')
    mysql_user="root"
    mysql_pass="root"
    mysql_db="stationblanche"
    
    # Vérifier si le hash existe déjà dans la base de données
    existing_hash=$(mysql -u$mysql_user -p$mysql_pass $mysql_db -se "SELECT hash FROM cles_usb WHERE hash='$combined_hash';")
    if [ "$existing_hash" == "$combined_hash" ]; then
        echo "Le hash existe déjà dans la base de données. Aucune insertion nécessaire."
    else
        # Lancer la numérisation
        echo "Starting ClamAV scan..."
        clamscan -r "$mount_point" --stdout

        # Vérifier le statut de la numérisation
        if [ $? -eq 0 ]; then
            # La numérisation est réussie, effectuer l'insertion


            date_info=$(date +"%Y-%m-%d %H:%M:%S")
            insert_query="INSERT INTO cles_usb (id_cles, hash, statut, date) VALUES ('$usb_id', '$combined_hash', 'pending', '$date_info');"
            mysql -u$mysql_user -p$mysql_pass $mysql_db -e "$insert_query" 2>> "$log_file"

            formatted_usb_info="$combined_hash, 'pending', '$date_info'"
            #echo "$formatted_usb_info" >> "$usb_info_file"

            # Mettre à jour le statut dans la base de données si la numérisation est réussie
            update_query="UPDATE cles_usb SET statut='OK' WHERE id_cles='$usb_id';"
            mysql -u$mysql_user -p$mysql_pass $mysql_db -e "$update_query" 2>> "$log_file"
        else
            # Sinon, mettez à jour le statut en NO_OK
            update_query="UPDATE cles_usb SET statut='NO_OK' WHERE id_cles='$usb_id';"
            mysql -u$mysql_user -p$mysql_pass $mysql_db -e "$update_query" 2>> "$log_file"
        fi
    fi

else
    echo "Aucun périphérique USB trouvé à l'emplacement spécifié."
fi

