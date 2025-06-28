#!/usr/bin/env bash
# iot_enum.sh
# 1. IoT Port & Service Enumerator
# Scans common IoT device ports and grabs banners; tries SNMP public walk.
# Usage: ./iot_enum.sh
# Requires: nmap, snmpwalk

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
    echo "[!] $t not found, installing..."
    if [[ "$(detect_os)" == "darwin" ]]; then
      brew install "$t"
    elif [[ "$(detect_os)" == "linux" ]]; then
      sudo apt-get update && sudo apt-get install -y "$t"
    else
      echo "[-] Unsupported OS for auto-install: $t"; exit 1
    fi
  fi
}

function get_credentials() {
  read -rp "Enter target IP or hostname: " TARGET
  read -rp "Enter domain (if required, else leave blank): " DOMAIN
  read -rp "Enter username (if required, else leave blank): " USER
  read -rsp "Enter password (if required, else leave blank): " PASS
  echo
}

# Ensure dependencies
ensure_tool nmap
ensure_tool snmpwalk
# Prompt for credentials
get_credentials

# Perform IoT enumeration
nmap -p22,80,443,161,554,1883,8883 -sV --script=banner -oN iot_ports_${TARGET}.txt ${TARGET}
snmpwalk -v2c -c public ${TARGET} system || echo "[!] SNMP v2 public failed"
