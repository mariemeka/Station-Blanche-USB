#!/bin/bash

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"
MOUNT_POINT="/mnt/usb"
CHECK_MOUNT_POINT=$(mount | grep "${DEVICE}" | awk '{ print $3 }')
DATE=$(date +"[%Y-%m-%d %H:%M:%S]")

# MOUNT KEY
mount_key() {
    # Check if already mounted
    if [[ -n "${CHECK_MOUNT_POINT}" ]]; then
        exit 1
    fi

    # Get info: id_fs_label, id_fs_uuid, and id_fs_type
    eval "$(blkid -o udev "${DEVICE}")"
    LABEL="${ID_FS_LABEL}"

    if [[ -z "${LABEL}" ]]; then
        LABEL="${DEVBASE}"
    elif grep -q "${MOUNT_POINT}" /etc/mtab; then
        LABEL+="-${DEVBASE}"
    fi

    # GLOBAL
    OPTS="rw,relatime"
    TYPE="vfat"

    # MOUNT
    mount -t "${TYPE}" -o "${OPTS}" "${DEVICE}" "${MOUNT_POINT}"

    # LOG ACTION
    echo "$DATE [USB][Mount] USB key mounted in '/mnt/usb'" >> /home/user/logs/usb.log
}

# UNMOUNT KEY
unmount_key() {
    if [[ -n "${CHECK_MOUNT_POINT}" ]]; then
        # UNMOUNT
        umount -l "${MOUNT_POINT}"

        # LOG ACTION
        echo "$DATE [USB][Unmount] USB key unmounted from '/mnt/usb'" >> /home/user/logs/usb.log
    fi
}

# MAIN
echo "$DATE [USB][Detect] USB key detected" >> /home/user/logs/usb.log

case "${ACTION}" in
    add)
        mount_key
        ;;
    remove)
        unmount_key
        ;;
esac
