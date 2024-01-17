## libre à vous de choisir l'emplacement, cependant il faudra mettre à jour le fichier 'server_web.py' ##

#!/bin/bash


python_script_path="/home/marieme/projet_stationblanche/Station-Blanche-USB/w/extraction_hash.py"

# Emplacement du répertoire où la clé USB sera montée
mount_point="/mnt"

# Emplacement du fichier de résultats de la numérisation
result_file="/home/marieme/projet_stationblanche/Station-Blanche-USB/web/scanned_files/scan_results.txt"

# Emplacement du fichier d'informations sur la clé USB
usb_info_file="/home/marieme/projet_stationblanche/Station-Blanche-USB/web/usb_info.txt"

# Emplacement du fichier de logs pour les erreurs
log_file="/home/marieme/projet_stationblanche/Station-Blanche-USB/web/error_logs.log"

# Vérifier si le périphérique USB est connecté
usb_device="/dev/sdd1"

#echo "Début du script"

# Charger les informations de configuration depuis le fichier config.ini
config_file="config.ini"
mysql_config_file="mysql_config.cnf"

if [ -f "$config_file" ]; then
    user=$(grep "user" "$config_file" | cut -d'=' -f2)
    password=$(grep "password" "$config_file" | cut -d'=' -f2)
    database=$(grep "database" "$config_file" | cut -d'=' -f2)
else
    echo "Erreur : le fichier config.ini n'a pas été trouvé."
    exit 1
fi

if mount | grep "$mount_point"; then
    echo "Le périphérique est déjà monté."
else
    mount "$usb_device" "$mount_point"
fi

# Obtenez l'identifiant unique du périphérique USB
usb_id=$(usbguard list-devices | tail -n 1 | awk '{print $4}')

if [ -b "$usb_device" ]; then
    # Calculer le hash global des fichiers sur la clé USB
    full_hash=""
    for file in $(find "$mount_point" -type f); do
        file_hash=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')
        if [ -n "$file_hash" ]; then
            full_hash="${full_hash}${file_hash}"
        fi
    done
    
    
    combined_hash=$(echo -n "$full_hash" | sha256sum | awk '{print $1}')
    # Vérifier si le hash existe déjà dans la base de données
    existing_hash=$(mysql --defaults-extra-file="$mysql_config_file" -e "SELECT hash FROM cles_usb WHERE hash='$combined_hash';" -s)

    if [ "$existing_hash" == "$combined_hash" ]; then
        echo "Le hash existe déjà dans la base de données. Aucune insertion nécessaire."
    else
        # Lancer la numérisation
        echo "Starting ClamAV scan..." 
        clamscan -r "$mount_point" --stdout >> "$result_file"

        # Vérifier le statut de la numérisation
        if [ $? -eq 0 ]; then
            # La numérisation est réussie, effectuer l'insertion


            date_info=$(date +"%Y-%m-%d %H:%M:%S")
            insert_query="INSERT INTO cles_usb (id_cles, hash, statut, date) VALUES ('$usb_id', '$combined_hash', 'pending', '$date_info');"
            mysql -u $user -p"$password" $database -e "$insert_query" 2>> "$log_file"

            formatted_usb_info="$combined_hash, 'pending', '$date_info'"
            #echo "$formatted_usb_info" >> "$usb_info_file"

            # Mettre à jour le statut dans la base de données si la numérisation est réussie
            update_query="UPDATE cles_usb SET statut='OK' WHERE id_cles='$usb_id';"
            mysql -u $user -p"$password" $database -e "$update_query" 2>> "$log_file"
        else
            # Sinon, mettez à jour le statut en NO_OK
            update_query="UPDATE cles_usb SET statut='NO_OK' WHERE id_cles='$usb_id';"
            mysql -u $user -p"$password" $database -e "$update_query" 2>> "$log_file"
            # Bloquer le périphérique USB en utilisant guard.sh
            /home/marieme/projet_stationblanche/Station-Blanche-USB/station-blanche/guard.sh block $usb_id
        fi
    fi

else
    echo "Aucun périphérique USB trouvé à l'emplacement spécifié."
fi

