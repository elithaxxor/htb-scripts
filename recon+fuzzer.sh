#!/usr/bin/env bash
# Recon + Fuzzing Wrapper (extended): HTTPS detection, virtual host redirection, HTML summary, auto-dependency

set -euo pipefail

# ───────────────────────── Colors ─────────────────────────
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

read -rp $'\n\033[1;36m[*] Target IP or Hostname: \033[0m' TARGET
OUTPUT_DIR="results_$TARGET"
mkdir -p "$OUTPUT_DIR"

# ────────────── Dependency Check & Auto-Install ──────────────
echo -e "${BLUE}[*] Checking required tools...${RESET}"
for bin in ffuf curl nmap jq; do
  if ! command -v $bin &>/dev/null; then
    echo -e "${YELLOW}[!] Missing $bin – attempting install...${RESET}"
    sudo apt-get install -y $bin || { echo -e "${RED}[-] Failed to install $bin${RESET}"; exit 1; }
  fi
done

# ────────────── HTTPS & Redirection Detection ──────────────
echo -e "${BLUE}[*] Detecting protocol...${RESET}"
PROTO="http"
REDIR_HOST=""
for port in 443 8443 80 8080; do
  if timeout 2 bash -c "</dev/tcp/$TARGET/$port" 2>/dev/null; then
    HTTP_PORT=$port
    [[ $port == 443 || $port == 8443 ]] && PROTO="https"
    break
  fi
done

if [[ -z ${HTTP_PORT:-} ]]; then
  echo -e "${RED}[!] No HTTP/HTTPS service available. Exiting.${RESET}"
  exit 1
fi

# Auto-detect Host header via curl redirection
echo -e "${BLUE}[*] Checking for Host header redirection...${RESET}"
REDIR_HOST=$(curl -skIL $PROTO://$TARGET:$HTTP_PORT | grep -i "location: " | grep -oP '(?<=//)[^/]+') || true
if [[ -n "$REDIR_HOST" ]]; then
  echo -e "${CYAN}[+] Detected virtual hostname: $REDIR_HOST${RESET}"
  echo "$TARGET $REDIR_HOST" | sudo tee -a /etc/hosts > /dev/null
else
  REDIR_HOST="$TARGET"
fi

# ────────────── Baseline Response ──────────────
echo -e "${BLUE}[*] Gathering baseline response...${RESET}"
RAND=$(uuidgen | tr 'A-Z' 'a-z')
BASE_LEN=$(curl -sk -o /dev/null -w "%{size_download}" $PROTO://$REDIR_HOST:$HTTP_PORT/$RAND)
BASE_CODE=$(curl -sk -o /dev/null -w "%{http_code}" $PROTO://$REDIR_HOST:$HTTP_PORT/$RAND)

# ────────────── Auto Wordlist ──────────────
WORDLIST="/usr/share/seclists/Discovery/Web-Content/raft-small-words.txt"
[[ $BASE_LEN -gt 5000 ]] && WORDLIST="/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt"

# ────────────── Subdomain Fuzz ──────────────
echo -e "${BLUE}[*] Fuzzing subdomains...${RESET}"
ffuf -u $PROTO://$TARGET -H "Host: FUZZ.$REDIR_HOST" \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
  -fs $BASE_LEN -fc $BASE_CODE -t 50 -o "$OUTPUT_DIR/subs.json" -of json || true

# ────────────── Directory Brute-force ──────────────
echo -e "${BLUE}[*] Fuzzing directories...${RESET}"
ffuf -u $PROTO://$REDIR_HOST:$HTTP_PORT/FUZZ \
  -w $WORDLIST -fs $BASE_LEN -fc $BASE_CODE -t 50 \
  -of json -o "$OUTPUT_DIR/dirs.json"

# ────────────── Extension Fuzzing ──────────────
echo -e "${BLUE}[*] Trying common extensions...${RESET}"
ffuf -u $PROTO://$REDIR_HOST:$HTTP_PORT/FUZZ \
  -w $WORDLIST -e .php,.bak,.html,.txt \
  -fs $BASE_LEN -fc $BASE_CODE -t 50 \
  -of json -o "$OUTPUT_DIR/exts.json"

# ────────────── HTML Report Generation ──────────────
echo -e "${BLUE}[*] Generating summary report...${RESET}"
REPORT="$OUTPUT_DIR/summary.html"
echo "<html><head><title>Recon Report</title></head><body><h2>Recon Summary for $REDIR_HOST</h2><ul>" > $REPORT
for f in subs.json dirs.json exts.json; do
  [[ -f "$OUTPUT_DIR/$f" ]] && echo "<li><b>${f/.json/}</b><ul>$(jq -r '.results[]?.input | "<li>\(.)</li>"' "$OUTPUT_DIR/$f")</ul></li>" >> $REPORT
done
echo "</ul><hr><pre>Protocol: $PROTO\nPort: $HTTP_PORT\nBaseline: $BASE_LEN bytes / $BASE_CODE code</pre></body></html>" >> $REPORT

# ────────────── Summary ──────────────
echo -e "\n${GREEN}====== COMPLETE ======${RESET}"
echo -e "${CYAN}Host:      ${RESET}$REDIR_HOST ($PROTO:$HTTP_PORT)"
echo -e "${CYAN}Wordlist:  ${RESET}$WORDLIST"
echo -e "${CYAN}Output:    ${RESET}$REPORT"
echo -e "${GREEN}======================${RESET}"

exit 0
