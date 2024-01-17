#!/bin/bash

# USB device ID variable
usb_device_id=$(usbguard list-devices | tail -n 1 | awk '{print $4}')

# Function to allow a specific USB device
allow_usb() {
    local device_id=$1
    usbguard allow-device "$device_id"
}

# Function to query a remote MySQL database
query_remote_database() {
    # Read SQL parameters from the configuration file
    source db_config.txt

    # SQL query to get the status of the key based on $usb_device_id
    sql_query="SELECT statut FROM cles_usb WHERE id_cles = '$usb_device_id' ORDER BY date DESC LIMIT 1;"
    #sql_query="SELECT statut FROM cles_usb WHERE id_cles = '$usb_device_id';"
    # Run the remote MySQL query and store the result
    query_result=$(mysql -h "$db_host" -P "$db_port" -u "$db_username" -p"$db_password" -D "$db_database" -e "$sql_query" 2>/dev/null | grep -E -o '\bOK\b')
    echo $query_result
    if [ "$query_result" == "OK" ]; then
        echo "Access is allowed. The status is OK. Allowing USB device..."
        allow_usb "$usb_device_id"
    else
        echo "Access denied. The status is not OK."
    fi
}

# Main script
query_remote_database

exit 0
