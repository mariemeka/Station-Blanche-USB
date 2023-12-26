#!/bin/bash

# USB Control Script using USBGuard on Debian

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
    *)
        echo "Invalid action. Usage: $0 <allow/block/list> [device_id]"
        exit 1
        ;;
esac

exit 0
