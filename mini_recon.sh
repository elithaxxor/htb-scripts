#!/usr/bin/env bash

IP="$1"
DOMAIN="artificial.htb"

if [ -z "$IP" ]; then
  echo "Usage: $0 <target_ip>"
  exit 1
fi

echo "[*] Setting up /etc/hosts..."
grep -q "$DOMAIN" /etc/hosts || echo "$IP $DOMAIN" | sudo tee -a /etc/hosts

echo "[*] Starting Nmap scans..."
mkdir -p recon_$DOMAIN
nmap -sC -sV -A -oN recon_$DOMAIN/nmap_full.txt $IP

echo "[*] Running WhatWeb..."
whatweb http://$DOMAIN > recon_$DOMAIN/whatweb.txt

echo "[*] Running ffuf for directories..."
ffuf -u http://$DOMAIN/FUZZ \
     -w /usr/share/seclists/Discovery/Web-Content/common.txt \
     -fs 154 -o recon_$DOMAIN/ffuf.txt

echo "[*] Checking HTTP headers..."
curl -I http://$DOMAIN > recon_$DOMAIN/headers.txt

echo "[*] Running Nmap HTTP NSE scripts..."
nmap -p80 --script http-enum,http-git,http-robots.txt -oN recon_$DOMAIN/http_scripts.txt $IP

echo "[+] Done. Check recon_$DOMAIN/ for output."
