#!/bin/bash

# Ensure the USB directory is mounted
USB_DIRECTORY="/mnt"
if [ ! -d "$USB_DIRECTORY" ]; then
    echo "USB directory not found."
    exit 1
fi

# Log file for scan results
LOG_FILE="/scanned_files/scan_results.txt"

# Perform ClamAV scan
echo "Starting ClamAV scan..."
clamscan -r "$USB_DIRECTORY" --log="$LOG_FILE"

# Check the scan results
if [ $? -eq 0 ]; then
    echo "USB keys are clean. Scan results stored in $LOG_FILE."
else
    echo "USB keys may be infected. Scan results stored in $LOG_FILE."
fi

# fast method (we scan only files)
sudo find $USB_DIRECTORY -type f -exec sha256sum {} + | sha256sum | tr -d '-' >> $LOG_FILE

# slow method (scans all the device)
#sudo dd if=$USB_DIRECTORY bs=4M status=progress | sha256sum | tr -d '-' >> $LOG_FILE
