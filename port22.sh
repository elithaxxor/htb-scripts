#!/usr/bin/env bash
# port22_audit.sh — Automated SSH (port 22) vulnerability audit & enumeration

set -euo pipefail

#### Setup ####
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTDIR="port22_audit_${TIMESTAMP}"
mkdir -p "${OUTDIR}"

read -rp "Enter target IP or hostname: " TARGET
echo -e "\n[+] Output directory: ./${OUTDIR}/\n"

#### Describe results ####
function describe_results() {
  echo -e "\n===== SSH Audit Summary ====="
  echo "nmap_banner.txt: Basic banner and version detection (SSH server details)."
  echo "nmap_scripts.txt: SSH scripts output (host-key, algorithms, auth methods)."
  echo "ssh_keyscan.txt: Raw keyscan output for known_hosts fingerprinting."
  echo "ssh_audit.txt: Detailed algorithm & security config audit via ssh-audit."
  echo "hydra.txt: (Optional) brute-force login attempts via Hydra against common user/pass."
  echo -e "===== End of Summary =====\n"
}

#### Functions ####
run_nmap_banner() {
  echo "[*] Nmap basic SSH banner & version..."
  nmap -p 22 -sV "${TARGET}" -oN "${OUTDIR}/nmap_banner.txt"
}

run_nmap_scripts() {
  echo "[*] Nmap SSH NSE scripts (hostkey, algos, auth-methods)..."
  nmap -p 22 \
        --script ssh-hostkey,ssh2-enum-algos,ssh-auth-methods,sshv1 \
        "${TARGET}" -oN "${OUTDIR}/nmap_scripts.txt"
}

run_ssh_keyscan() {
  echo "[*] SSH keyscan for known_hosts..."
  ssh-keyscan -p 22 "${TARGET}" > "${OUTDIR}/ssh_keyscan.txt" 2>&1
}

run_ssh_audit() {
  if ! command -v ssh-audit &>/dev/null; then
    echo "[!] ssh-audit not found, installing..."
    pip3 install --user ssh-audit
  fi
  echo "[*] Running ssh-audit..."
  ssh-audit "${TARGET}" > "${OUTDIR}/ssh_audit.txt" 2>&1
}

run_hydra() {
  echo "[*] Hydra brute-force (common users & rockyou)..."
  USERLIST="/usr/share/seclists/Usernames/top-usernames-shortlist.txt"
  PASSLIST="/usr/share/wordlists/rockyou.txt"
  hydra -L "${USERLIST}" -P "${PASSLIST}" ssh://"${TARGET}" \
        -t 4 -o "${OUTDIR}/hydra.txt"
}

#### Main Execution ####
run_nmap_banner
run_nmap_scripts
run_ssh_keyscan
run_ssh_audit
run_hydra

echo -e "\n[✔] port22 audit complete. Results in ./${OUTDIR}/"
describe_results
