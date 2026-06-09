#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZENOS_DIR="${SCRIPT_DIR}/.."
ISO_PATH="${ZENOS_DIR}/live-image-amd64.hybrid.iso"
WEB_PORT="${ZENOS_WEB_PORT:-8006}"
VNC_PORT="${ZENOS_VNC_PORT:-5900}"
VNC_DISPLAY="${ZENOS_VNC_DISPLAY:-0}"
RAM_MB="${ZENOS_RAM:-4096}"
CPUS="${ZENOS_CPUS:-4}"
QEMU_NAME="${ZENOS_NAME:-zenos-test}"
OVMF_CODE="/usr/share/edk2/ovmf/OVMF_CODE.fd"
OVMF_VARS="/tmp/${QEMU_NAME}-ovmf-vars.fd"
SERIAL_LOG="/tmp/${QEMU_NAME}-serial.log"
QMP_SOCK="/tmp/${QEMU_NAME}-qmp.sock"
SERIAL_SOCK="/tmp/${QEMU_NAME}-serial.sock"

show_help() {
    cat << EOF
ZEN-OS VM Test Launcher

USAGE: $(basename "$0") [MODE] [OPTIONS]

MODES:
    --web           Browser-based VNC via noVNC (default)
    --vnc           Native VNC client only
    --mcp           MCP control + web VNC
    --docker        Use qemux/qemu Docker (easiest, built-in noVNC)
    --stop          Stop running VM
    --status        Show VM status

OPTIONS:
    --iso PATH      Custom ISO path
    --ram MB        RAM in MB (default: ${RAM_MB})
    --cpus N        CPU cores (default: ${CPUS})
    --name NAME     VM name (default: ${QEMU_NAME})

EXAMPLES:
    $(basename "$0") --docker          # Easiest: full web UI
    $(basename "$0") --web             # Native QEMU + noVNC
    $(basename "$0") --mcp             # AI-controlled testing
    $(basename "$0") --stop
EOF
}

MODE="web"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --web|--novnc) MODE="web"; shift ;;
        --vnc) MODE="vnc"; shift ;;
        --mcp) MODE="mcp"; shift ;;
        --docker) MODE="docker"; shift ;;
        --stop) MODE="stop"; shift ;;
        --status) MODE="status"; shift ;;
        --iso) ISO_PATH="$2"; shift 2 ;;
        --ram) RAM_MB="$2"; shift 2 ;;
        --cpus) CPUS="$2"; shift 2 ;;
        --name) QEMU_NAME="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown: $1"; show_help; exit 1 ;;
    esac
done

if [ ! -f "$ISO_PATH" ]; then
    echo "ERROR: ISO not found: ${ISO_PATH}"
    exit 1
fi

if [ "$MODE" = "stop" ]; then
    systemctl --user stop "${QEMU_NAME}" 2>/dev/null || true
    pkill -f "qemu-system.*${QEMU_NAME}" 2>/dev/null || true
    docker rm -f "${QEMU_NAME}" 2>/dev/null || true
    echo "Stopped ${QEMU_NAME}."
    exit 0
fi

if [ "$MODE" = "status" ]; then
    echo "=== ${QEMU_NAME} Status ==="
    pgrep -a "qemu-system" 2>/dev/null | grep "${QEMU_NAME}" && echo "QEMU: Running" || echo "QEMU: Not running"
    nc -z localhost "$VNC_PORT" 2>/dev/null && echo "VNC: localhost:${VNC_PORT}" || echo "VNC: Not listening"
    docker ps --filter "name=${QEMU_NAME}" --format "Docker: {{.Status}}" 2>/dev/null || true
    [ -f "$SERIAL_LOG" ] && echo "Serial: ${SERIAL_LOG} ($(wc -c < "$SERIAL_LOG" | numfmt --to=iec)B)"
    exit 0
fi

if [ "$MODE" = "docker" ]; then
    docker run -d --name "${QEMU_NAME}" --rm \
        --device /dev/kvm --device /dev/net/tun \
        --cap-add NET_ADMIN \
        -p ${WEB_PORT}:8006 -p ${VNC_PORT}:5900 \
        -v "${ISO_PATH}:/boot.iso" \
        -v "${ZENOS_DIR}/qemu-storage:/storage" \
        -e CPU_CORES="${CPUS}" -e RAM_SIZE="${RAM_MB}M" \
        -e DISK_SIZE="32G" -e VGA="virtio" \
        -e BOOT="alpine" -e DISPLAY="web" -e UEFI="Y" \
        qemux/qemu
    echo ""
    echo "Docker VM started."
    echo "Web VNC: http://localhost:${WEB_PORT}"
    echo "Stop:    ./test-vm.sh --stop"
    exit 0
fi

QEMU_ARGS=(
    -enable-kvm -smp "${CPUS}" -m "${RAM_MB}"
    -drive "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}"
    -drive "if=pflash,format=raw,file=${OVMF_VARS}"
    -drive "file=${ISO_PATH},media=cdrom,readonly=on"
    -boot d
    -netdev "user,id=net0,hostfwd=tcp::2222-:22"
    -device "virtio-net-pci,netdev=net0"
    -serial "file:${SERIAL_LOG}"
    -chardev "socket,path=${QMP_SOCK},server=on,wait=off,id=qmp0"
    -mon "chardev=qmp0,mode=control"
    -serial "unix:${SERIAL_SOCK},server,nowait"
    -device "virtio-balloon"
    -name "${QEMU_NAME}"
)

case "$MODE" in
    web)
        QEMU_ARGS+=(-vnc ":${VNC_DISPLAY}" -vga std)
        echo "VNC: localhost:${VNC_PORT} (display :${VNC_DISPLAY})"
        echo ""
        echo "For browser VNC, run in another terminal:"
        echo "  websockify --web /usr/share/novnc ${WEB_PORT} localhost:${VNC_PORT}"
        echo "Then open: http://localhost:${WEB_PORT}/vnc.html?host=localhost&port=${WEB_PORT}&encrypt=false"
        ;;
    vnc)
        QEMU_ARGS+=(-vnc ":${VNC_DISPLAY}" -vga std)
        echo "VNC: localhost:${VNC_PORT} (display :${VNC_DISPLAY})"
        echo "Use any VNC client (vncviewer, Remmina, etc.)"
        ;;
    mcp)
        QEMU_ARGS+=(-vnc ":${VNC_DISPLAY}" -vga std)
        echo "MCP: VNC+QMP+serial"
        echo "VNC: localhost:${VNC_PORT} (display :${VNC_DISPLAY})"
        echo "QMP: ${QMP_SOCK}"
        echo "Serial: ${SERIAL_SOCK}"
        echo ""
        echo "Start MCP: mcp-qemu-vnc --stdio"
        echo "Connect: vm_connect(qmp_socket=\"${QMP_SOCK}\", vnc_host=\"localhost\", vnc_port=${VNC_PORT}, serial_socket=\"${SERIAL_SOCK}\")"
        ;;
esac

systemctl --user stop "${QEMU_NAME}" 2>/dev/null || true
pkill -f "qemu-system.*${QEMU_NAME}" 2>/dev/null || true

cp "/usr/share/edk2/ovmf/OVMF_VARS.fd" "$OVMF_VARS" 2>/dev/null || true
rm -f "$SERIAL_LOG"

systemd-run --user --unit="${QEMU_NAME}" \
    /usr/bin/qemu-system-x86_64 "${QEMU_ARGS[@]}"

echo ""
echo "VM: ${QEMU_NAME}"
echo "Stop:    ./test-vm.sh --stop"
echo "Status:  ./test-vm.sh --status"
echo "Serial:  tail -f ${SERIAL_LOG}"
echo ""
echo "If you see an error, run: ./flag-error.sh \"what you see\""
