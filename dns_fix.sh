#!/usr/bin/env bash
# fix_htb_dns.sh ─ Update /etc/hosts so <DOMAIN> always points at the
#                  current Hack-The-Box machine IP.
#
# Usage:   sudo ./fix_htb_dns.sh
#          (you’ll be prompted for the new IP)
#
# Notes:
#   • The script backs up /etc/hosts first.
#   • If an entry already exists it’s replaced; otherwise it’s appended.
#   • Works on any Linux/macOS box that has GNU sed (Parrot OS, Kali, Ubuntu…).

set -euo pipefail

DOMAIN="artificial.htb"   # Change this if the box you’re working on uses a
                          # different vHost name (e.g. precious.htb, bucket.htb)

HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.bak.$(date +%Y%m%d_%H%M%S)"

echo "[*] Updating local DNS for $DOMAIN"
read -rp "    → Enter the NEW IP address: " NEWIP

# Basic sanity check (IPv4 dotted-decimal)
if ! [[ $NEWIP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "[!] '$NEWIP' doesn't look like a valid IPv4 address. Aborting." >&2
  exit 1
fi

echo "[*] Backing up $HOSTS_FILE to $BACKUP_FILE"
sudo cp "$HOSTS_FILE" "$BACKUP_FILE"

if grep -qE "[[:space:]]$DOMAIN\$" "$HOSTS_FILE"; then
  echo "[*] Existing entry found – replacing it."
  sudo sed -i "s/^[0-9.\\t ]\\+[[:space:]]\\+$DOMAIN\$/$NEWIP  $DOMAIN/" "$HOSTS_FILE"
else
  echo "[*] No entry found – adding a new one."
  echo "$NEWIP  $DOMAIN" | sudo tee -a "$HOSTS_FILE" >/dev/null
fi

echo "[+] Done. $DOMAIN → $NEWIP"
echo "    (Original hosts file saved as $BACKUP_FILE)"
