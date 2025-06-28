#!/usr/bin/env bash
# ftp_smb_enum.sh
# 3. FTP & SMB Rapid Auditor
# Checks anonymous FTP and enumerates SMB shares.
# Usage: ./ftp_smb_enum.sh
# Requires: nmap, smbclient

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
    echo "[!] $t missing, installing..."
    if [[ "$(detect_os)" == "darwin" ]]; then
      brew install "$t"
    else
      sudo apt-get update && sudo apt-get install -y "$t"
    fi
  fi
}

function get_credentials() {
  read -rp "Enter target IP or hostname: " TARGET
  read -rp "Enter domain (if any): " DOMAIN
  read -rp "Enter username (if any): " USER
  read -rsp "Enter password (if any): " PASS
  echo
}

# Dependencies
ensure_tool nmap
ensure_tool smbclient
# Credentials
get_credentials

# FTP anonymous check
nmap -p21 --script ftp-anon -oN ftp_anon_${TARGET}.txt ${TARGET}

echo "[*] SMB share list:"
smbclient -L \\$TARGET -N | tee smb_shares_${TARGET}.txt
