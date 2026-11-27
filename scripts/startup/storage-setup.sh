#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/storage-setup.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== Storage setup begins: $(date) ====="

apt-get update
apt-get install -y lvm2

DEVICE="${DISK_DEVICE:-/dev/disk/by-id/google-data-disk}"
VG_NAME="${VG_NAME:-project_vg}"
LV_NAME="${LV_NAME:-project_lv}"
MOUNT_POINT="${MOUNT_POINT:-/data}"
LV_SIZE="${LV_SIZE:-100%FREE}"

# Verify the disk exists
if [ ! -e "$DEVICE" ]; then
    echo "Disk not detected: $DEVICE"
    exit 1
fi

# Create PV only if one does not exist
if ! pvs "$DEVICE" >/dev/null 2>&1; then

    # Do not overwrite an existing filesystem/signature
    if blkid "$DEVICE" >/dev/null 2>&1; then
        echo "ERROR: Disk already contains a filesystem/signature."
        exit 1
    fi

    pvcreate "$DEVICE"
fi

# Create VG if missing
if ! vgs "$VG_NAME" >/dev/null 2>&1; then
    vgcreate "$VG_NAME" "$DEVICE"
fi

# Create LV if missing
if ! lvs "$VG_NAME/$LV_NAME" >/dev/null 2>&1; then
    lvcreate -l "$LV_SIZE" -n "$LV_NAME" "$VG_NAME"
fi

LV_PATH="/dev/$VG_NAME/$LV_NAME"

# Create filesystem only if missing
if ! blkid "$LV_PATH" >/dev/null 2>&1; then
    mkfs.ext4 "$LV_PATH"
fi

mkdir -p "$MOUNT_POINT"

UUID=$(blkid -s UUID -o value "$LV_PATH")

# Add persistent mount configuration
if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
fi

# Mount if not already mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    mount "$MOUNT_POINT"
fi

echo "Storage mounted at $MOUNT_POINT"

echo "===== Storage setup completed: $(date) ====="