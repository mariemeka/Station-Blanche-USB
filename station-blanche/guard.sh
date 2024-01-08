#!/bin/bash

# USB Control Script using USBGuard on Debian

# usb device ID variable
usb_device_id=$(usbguard list-devices | tail -n 1 | awk '{print $4}')

# Function to allow a specific USB device
allow_usb() {
    device_id=$1
    usbguard allow-device $device_id
}

# Function to block a specific USB device
block_usb() {
    device_id=$1
    usbguard block-device $device_id
}

# Function to list connected USB devices
list_usb_devices() {
    usbguard list-devices
}

# Function to query a remote MySQL database
query_remote_database() {
    read -p "Enter MySQL host: " host
    read -p "Enter MySQL port: " port
    read -p "Enter MySQL username: " username
    read -s -p "Enter MySQL password: " password
    echo # Move to a new line after password input
    read -p "Enter database name: " database
    # Requête SQL pour obtenir le statut de la clé basée sur $usb_device_id
    sql_query="SELECT statut FROM cles_usb WHERE id_cles = '$usb_device_id';"

    # Run the remote MySQL query
    mysql -h "$host" -P "$port" -u "$username" -p"$password" -D "$database" -e "$sql_query"
}

# Main script
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <allow/block/list> [device_id]"
    exit 1
fi

action=$1
device_id=$2

case $action in
    "allow")
        allow_usb $device_id
        ;;
    "block")
        block_usb $device_id
        ;;
    "list")
        list_usb_devices
        ;;
"query")  # Ajout de l'option pour la requête MySQL
        query_remote_database
        ;;
    *)
        echo "Invalid action. Usage: $0 <allow/block/list/query> [device_id]"
        exit 1
        ;;
esac

exit 0
