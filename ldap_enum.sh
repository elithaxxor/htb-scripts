#!/usr/bin/env bash
# ldap_enum.sh
# 8. Active Directory LDAP Misconfig Checker
# Queries LDAP for users and group policies to find misconfigurations.
# Usage: ./ldap_enum.sh
# Requires: ldapsearch

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
  read -rp "Enter Domain Controller IP: " DC
  read -rp "Enter LDAP bind DN (user): " USER
  read -rsp "Enter LDAP password: " PASS; echo
}

ensure_tool ldapsearch
get_credentials

# Enumerate domain users
ldapsearch -x -H ldap://${DC} -D "${USER}" -w "${PASS}"   -b "dc=example,dc=com" "(objectClass=user)" sAMAccountName | tee ldap_users.txt

# Check Group Policy ACLs
ldapsearch -x -H ldap://${DC} -D "${USER}" -w "${PASS}"   -b "dc=example,dc=com" "(&(objectClass=groupPolicyContainer)(gPCFileSysPath=*))" gPLink | tee ldap_acls.txt
