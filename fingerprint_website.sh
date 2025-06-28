#!/usr/bin/env bash

# Colors for formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# Prompt for input
read -rp "Enter the target IP or domain (e.g., 10.10.10.10 or example.com): " TARGET

echo -e "\n${CYAN}Starting fingerprinting for: $TARGET${NC}\n"

# Function to run a tool and print header and output
run_tool() {
    TOOL_NAME="$1"
    DESCRIPTION="$2"
    COMMAND="$3"

    echo -e "${YELLOW}[+] Running $TOOL_NAME${NC}"
    echo -e "${GREEN}▶ $DESCRIPTION${NC}"
    echo -e "${CYAN}---------------------------------------------${NC}"
    eval "$COMMAND"
    echo -e "${CYAN}---------------------------------------------\n${NC}"
}

# Tool 1: Nmap service and version detection
run_tool "Nmap -sV" \
  "Scans open ports and tries to detect running service versions." \
  "nmap -sV -Pn -T4 -p- --min-rate=500 $TARGET | tee nmap_output.txt"

# Tool 2: WhatWeb
run_tool "WhatWeb" \
  "Identifies website technologies (CMS, frameworks, etc.)." \
  "whatweb http://$TARGET"

# Tool 3: curl -I
run_tool "Curl Headers" \
  "Fetches HTTP response headers to reveal server type and config." \
  "curl -I http://$TARGET"

# Tool 4: wafw00f
run_tool "WAFW00F" \
  "Detects if the website is protected by a Web Application Firewall." \
  "wafw00f http://$TARGET"

# Tool 5: sslscan
run_tool "SSLScan" \
  "Scans SSL/TLS configurations and supported cipher suites." \
  "sslscan $TARGET"

# Tool 6: httpx (if installed)
if command -v httpx &> /dev/null; then
  run_tool "Httpx" \
    "Performs basic web fingerprinting with status code, title, tech stack." \
    "echo $TARGET | httpx -status-code -title -tech-detect"
fi

# Tool 7: Gobuster (optional)
if command -v gobuster &> /dev/null; then
  read -rp "Run directory brute-force with Gobuster? (y/n): " G
  if [[ "$G" == "y" || "$G" == "Y" ]]; then
    read -rp "Enter path to wordlist (e.g., /usr/share/wordlists/dirb/common.txt): " WORDLIST
    run_tool "Gobuster" \
      "Brute-forces directories and files using a wordlist." \
      "gobuster dir -u http://$TARGET -w $WORDLIST -t 40"
  fi
fi

echo -e "${GREEN}Fingerprinting complete.${NC}"
