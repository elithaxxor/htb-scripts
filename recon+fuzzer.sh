#!/usr/bin/env bash
# Recon + Fuzzing Auto-Wrapper
# Auto-selects optimal wordlist and filters false positives based on server behavior

set -euo pipefail

# ───────────────────────────── Colors ─────────────────────────────
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

read -rp $'\n\033[1;36m[*] Target IP or Hostname: \033[0m' TARGET
OUTPUT_DIR="results_$TARGET"
mkdir -p "$OUTPUT_DIR"

# ───────────────────── Detect HTTP Service ─────────────────────
echo -e "${BLUE}[*] Scanning for HTTP service...${RESET}"
HTTP_PORT=$(nmap -p- --open --min-rate=1000 -T4 $TARGET | grep -E '/tcp.*http' | cut -d "/" -f1 | head -n1 || true)

if [[ -z "$HTTP_PORT" ]]; then
  echo -e "${RED}[!] No HTTP service detected. Exiting.${RESET}"
  exit 1
fi

echo -e "${GREEN}[+] Found HTTP on port $HTTP_PORT${RESET}"

# ───────────────────── Baseline Response Fingerprint ─────────────────────
echo -e "${BLUE}[*] Establishing baseline page signature...${RESET}"
RAND_PATH=$(uuidgen | tr 'A-Z' 'a-z')
BASELINE_LENGTH=$(curl -s -o /dev/null -w "%{size_download}" http://$TARGET:$HTTP_PORT/$RAND_PATH)
BASELINE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$TARGET:$HTTP_PORT/$RAND_PATH)

echo -e "${CYAN}[i] Baseline length: $BASELINE_LENGTH, code: $BASELINE_CODE${RESET}"

# ───────────────────── Auto Wordlist Selection ─────────────────────
echo -e "${BLUE}[*] Selecting optimal wordlist...${RESET}"
WORDLIST=""
case $BASELINE_LENGTH in
  ''|0)   WORDLIST="/usr/share/wordlists/dirb/common.txt" ;;
  [0-9]|[1-2][0-9][0-9]) WORDLIST="/usr/share/seclists/Discovery/Web-Content/raft-small-words.txt" ;;
  *)      WORDLIST="/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt" ;;
esac

if [[ ! -f "$WORDLIST" ]]; then
  echo -e "${RED}[!] Wordlist not found: $WORDLIST${RESET}"
  exit 1
fi

# ───────────────────── Run FFUF with Filtering ─────────────────────
echo -e "${BLUE}[*] Starting ffuf scan with live filtering...${RESET}"
ffuf -u http://$TARGET:$HTTP_PORT/FUZZ \
     -w $WORDLIST \
     -fs $BASELINE_LENGTH \
     -fc $BASELINE_CODE \
     -t 50 \
     -of html -o "$OUTPUT_DIR/ffuf_filtered.html"

# ───────────────────── Optional Extension Fuzz ─────────────────────
echo -e "\n${BLUE}[*] Extension-based scan (.php, .bak)...${RESET}"
ffuf -u http://$TARGET:$HTTP_PORT/FUZZ \
     -w $WORDLIST \
     -e .php,.bak,.html,.txt \
     -fs $BASELINE_LENGTH \
     -fc $BASELINE_CODE \
     -t 50 \
     -of html -o "$OUTPUT_DIR/ffuf_extensions.html"

# ───────────────────── Summary ─────────────────────
echo -e "\n${GREEN}====== WRAP-UP ======${RESET}"
echo -e "${CYAN}Host:        ${RESET}$TARGET"
echo -e "${CYAN}HTTP Port:   ${RESET}$HTTP_PORT"
echo -e "${CYAN}Wordlist:    ${RESET}$WORDLIST"
echo -e "${CYAN}Baseline Len:${RESET} $BASELINE_LENGTH | ${CYAN}Code:${RESET} $BASELINE_CODE"
echo -e "${CYAN}Output:      ${RESET}$OUTPUT_DIR/ffuf_filtered.html"
echo -e "${CYAN}Extensions:  ${RESET}$OUTPUT_DIR/ffuf_extensions.html"
echo -e "${GREEN}======================${RESET}"

exit 0
