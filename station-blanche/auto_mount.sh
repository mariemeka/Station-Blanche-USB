#!/bin/bash

# Wait for the device to settle
sleep 2

# Get the device path
DEVICE_PATH="/dev/$1"

# Mount the USB device
MOUNT_POINT="/scanned_files/$(basename $DEVICE_PATH)"
mkdir -p "$MOUNT_POINT"
mount "$DEVICE_PATH" "$MOUNT_POINT"
