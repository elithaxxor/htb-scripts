#!/usr/bin/env bash
# headset_ble_scan.sh
# Adapted with remote-vs-local execution: remote scan vs on-device via SSH
# Usage: ./ headset_ble_scan.sh
# Requires appropriate tools depending on mode

function detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux";;
    Darwin*) echo "darwin";;
    *) echo "unknown";;
  esac
}

function ensure_tool() {
  local t=$1
  if ! command -v "$t" &>/dev/null; then
    echo "[!] $t not found, attempting install"
    if [[ "$(detect_os)" == "darwin" ]]; then
      brew install "$t"
    elif [[ "$(detect_os)" == "linux" ]]; then
      sudo apt-get update && sudo apt-get install -y "$t"
    else
      echo "Unsupported OS for install: $t"; exit 1
    fi
  fi
}

function remote_scan() {
  echo "Scanning BLE..."
hcitool lescan --duplicates & sleep 10; kill $!
DEV=$(hcitool lescan | head -n1 | awk '{print $1}')
echo "Device: $DEV"
gatttool -b "$DEV" --char-read --uuid=0x2a19

}

function remote_ssh_execute() {
  local host="$SSH_HOST"
  local user="$SSH_USER"
  local pass="$SSH_PASS"
  echo "[*] Copying script and executing on-device via SSH"
  scp "$0" "$user@$host:/tmp/headset_ble_scan.sh"
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$host" "bash /tmp/headset_ble_scan.sh on-device"
}

# Main
echo "Select mode:"
echo "1) Remote scan from attacker machine"
echo "2) Run on-device via SSH"
read -rp "Choice [1/2]: " MODE

if [[ "$MODE" == "2" ]]; then
  read -rp "SSH host: " SSH_HOST
  read -rp "SSH user: " SSH_USER
  read -rsp "SSH password: " SSH_PASS
  echo
  ensure_tool sshpass
  remote_ssh_execute
  exit 0
else
  # perform remote scan
  ensure_tool hcitool
ensure_tool gatttool
  remote_scan
  exit 0
fi
