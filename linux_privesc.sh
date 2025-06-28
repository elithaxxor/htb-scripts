#!/usr/bin/env bash
# linux_privesc.sh
# 7. Linux PrivEsc Auditor
# Copies and runs LinPEAS & LinEnum on a remote Linux host via SSH, checks for SUID.
# Usage: ./linux_privesc.sh
# Requires: ssh, wget

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
    echo "[!] Installing $t..."
    if [[ "$(detect_os)" == "darwin" ]]; then brew install "$t"; else sudo apt-get update && sudo apt-get install -y "$t"; fi
  fi
}

function get_credentials() {
  read -rp "Enter target (user@host): " TGT
}

ensure_tool ssh
ensure_tool wget
get_credentials

ssh ${TGT} "wget -q https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh && chmod +x linpeas.sh && ./linpeas.sh | tee linpeas.txt"
ssh ${TGT} "wget -q https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh && chmod +x LinEnum.sh && ./LinEnum.sh -t | tee linenum.txt"
ssh ${TGT} "find / -perm -4000 -type f 2>/dev/null | tee suid_files.txt"
