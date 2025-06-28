#!/usr/bin/env bash
# ap_scan.sh
# 2. Wireless AP Auditor via SNMP, WPS
# Usage: ./ap_scan.sh
# Requires: nmap, snmpwalk, wash, reaver

function detect_os() { case "$(uname -s)" in Linux*) echo "linux";; Darwin*) echo "darwin";; *) echo "unknown";; esac; }
function ensure_tool() { local t=$1; command -v "$t" &>/dev/null || { echo "[!] Please install $t"; exit 1; }; }
function get_credentials() { read -rp "Enter AP IP: " TARGET; }

ensure_tool nmap
ensure_tool snmpwalk
ensure_tool wash
ensure_tool reaver
get_credentials

snmpwalk -v2c -c public "$TARGET" system || echo "SNMP v2c failed"
wash -i wlan0 -o ap_wps.txt
BSSID=$(awk 'NR==2{print $1}' ap_wps.txt)
reaver -i wlan0 -b "$BSSID" -vv
