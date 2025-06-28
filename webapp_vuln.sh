#!/usr/bin/env bash
# webapp_vuln.sh
# 4. WebApp Vulnerability Chain
# Runs nikto, nuclei (SQLi templates), and sqlmap for automated scanning.
# Usage: ./webapp_vuln.sh
# Requires: nikto, nuclei, sqlmap

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
  read -rp "Enter target URL (e.g., http://example.com): " TARGET
}

# Dependencies
ensure_tool nikto
ensure_tool nuclei
ensure_tool sqlmap
# Get URL
get_credentials

# Nikto scan
nikto -h "$TARGET" -o nikto_$(basename "$TARGET").txt
# Nuclei SQLi templates
nuclei -u "$TARGET" -t /usr/share/nuclei-templates/sql-injection/ -o nuclei_sqli.txt
# sqlmap scan
sqlmap -u "$TARGET" --batch --level=2 --risk=1 -o sqlmap_output
