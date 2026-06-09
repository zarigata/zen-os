#!/bin/bash
set -e

ZENOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK_DIR="${ZENOS_DIR}/disks"
QEMU_NAME="${ZENOS_NAME:-zenos-test}"
DISK_PATH="${DISK_DIR}/${QEMU_NAME}.qcow2"

usage() {
    cat << EOF
ZEN-OS VM Snapshot Manager

USAGE: $(basename "$0") [ACTION] [NAME]

ACTIONS:
    create NAME     Create a new snapshot
    list            List all snapshots
    load NAME       Restore to snapshot
    delete NAME     Delete a snapshot
    info            Show disk info

EXAMPLES:
    $(basename "$0") create fresh-install
    $(basename "$0") list
    $(basename "$0") load fresh-install
    $(basename "$0") delete old-snapshot
EOF
}

if [ ! -f "$DISK_PATH" ]; then
    echo "ERROR: Disk not found: ${DISK_PATH}"
    echo "Create first: ./create-disk.sh"
    exit 1
fi

ACTION="${1:-list}"
NAME="${2:-}"

case "$ACTION" in
    create)
        if [ -z "$NAME" ]; then
            echo "ERROR: Snapshot name required"
            usage
            exit 1
        fi
        qemu-img snapshot -c "$NAME" "$DISK_PATH"
        echo "Snapshot '${NAME}' created."
        ;;
    list)
        echo "Snapshots for ${QEMU_NAME}:"
        qemu-img snapshot -l "$DISK_PATH"
        ;;
    load|restore)
        if [ -z "$NAME" ]; then
            echo "ERROR: Snapshot name required"
            usage
            exit 1
        fi
        # Must stop VM before restoring
        systemctl --user stop "$QEMU_NAME" 2>/dev/null || true
        pkill -f "qemu-system.*${QEMU_NAME}" 2>/dev/null || true
        sleep 2
        qemu-img snapshot -a "$NAME" "$DISK_PATH"
        echo "Restored snapshot '${NAME}'. Start VM to use it."
        ;;
    delete|remove)
        if [ -z "$NAME" ]; then
            echo "ERROR: Snapshot name required"
            usage
            exit 1
        fi
        qemu-img snapshot -d "$NAME" "$DISK_PATH"
        echo "Deleted snapshot '${NAME}'."
        ;;
    info)
        qemu-img info "$DISK_PATH"
        ;;
    *)
        echo "Unknown action: $ACTION"
        usage
        exit 1
        ;;
esac
