#!/usr/bin/env bash
# iot_firmware.sh
# 6. IoT Firmware Downloader & Emulator
# Downloads firmware, extracts with binwalk, and boots in QEMU.
# Usage: ./iot_firmware.sh
# Requires: wget, binwalk, qemu-system-arm

function detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux" ;;
    Darwin*) echo "darwin" ;;
    *) echo "unknown" ;;
  esac
}

function ensure_tool() {
  local t=$1
  if ! command -v "$t" &>/dev/null; then
    echo "[!] Installing $t..."
    if [[ "$(detect_os)" == "darwin" ]]; then brew install "$t"; else sudo apt-get update && sudo apt-get install -y "$t"; fi
  fi
}

function get_credentials() {
  read -rp "Enter firmware URL: " FW_URL
}

ensure_tool wget
ensure_tool binwalk
ensure_tool qemu-system-arm
get_credentials

wget -O firmware.bin "$FW_URL"
binwalk -e firmware.bin
IMG=$(find _firmware.bin.extracted -type f -name '*.elf' | head -n1)
qemu-system-arm -M versatilepb -kernel "$IMG" -nographic
