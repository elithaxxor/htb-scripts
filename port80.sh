#!/usr/bin/env bash
# port80_audit.sh — Automated HTTP (port 80) vulnerability reconnaissance
# Enhanced with modular functions, advanced fuzzing, header checks, injection scans,
# screenshotting, TLS-on-80 detection, and OWASP ZAP baseline scan.

set -euo pipefail

#### Configuration & Helpers ####
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTDIR="port80_audit_${TIMESTAMP}"
mkdir -p "${OUTDIR}"

# Prompt for target
read -rp "Enter target IP or hostname: " TARGET
BASEURL="http://${TARGET}"
echo -e "\n[+] Output directory: ./${OUTDIR}/\n"

# Function: Describe each tool's output
function describe_results() {
  echo -e "\n===== Summary of Results ====="
  echo "nmap_banner.txt: Nmap banner/version grab on port 80 (identifies server software)."
  echo "http_checks.txt: HTTP methods allowed and security headers via Nmap http-methods & http-headers scripts."
  echo "whatweb.txt: WhatWeb fingerprinting (CMS, frameworks, languages, libraries)."
  echo "wafw00f.txt: WAF presence detection."
  echo "gobuster.txt: Directory brute-force results (common files/folders)."
  echo "ffuf.json: FFUF fuzzing results (custom wordlists + regex filters)."
  echo "nikto.txt: Nikto baseline HTTP vulnerability scan."
  echo "nuclei.txt: Nuclei CVE/template scans."
  echo "sqlmap/: SQLMap injection scan outputs."
  echo "xsstrike.txt: XSStrike XSS brute-forcer results."
  echo "aquatone/: Screenshots & HTML of site via Aquatone."
  echo "eyewitness/: Visual report from EyeWitness (screenshots of paths)."
  echo "tls_on_80.txt: TLS handshake attempt on port 80 (detect HTTPS-on-80)."
  echo "zap_report.html: OWASP ZAP baseline scan HTML report."
  echo -e "===== End of Summary =====\n"
}

#### Modular Functions ####
run_nmap() {
  echo "[*] Nmap banner & version grab..."
  nmap -p 80 -sV --script http-server-header "${TARGET}" -oN "${OUTDIR}/nmap_banner.txt"
}

run_http_checks() {
  echo "[*] Nmap HTTP methods & header checks..."
  nmap -p80 --script=http-methods,http-headers --script-args http-methods.test-all \
        -oN "${OUTDIR}/http_checks.txt" "${TARGET}"
}

run_whatweb() {
  echo "[*] WhatWeb fingerprinting..."
  whatweb -a 3 "${BASEURL}" > "${OUTDIR}/whatweb.txt" 2>&1
}

run_wafw00f() {
  echo "[*] WAF detection with wafw00f..."
  wafw00f "${BASEURL}" > "${OUTDIR}/wafw00f.txt" 2>&1
}

run_gobuster() {
  echo "[*] Gobuster dir brute-force..."
  gobuster dir -u "${BASEURL}/" \
    -w /usr/share/seclists/Discovery/Web-Content/raft-large-words.txt \
    -t 50 -o "${OUTDIR}/gobuster.txt"
}

run_ffuf() {
  echo "[*] FFUF advanced fuzzing..."
  ffuf -u "${BASEURL}/FUZZ" \
       -w /usr/share/seclists/Discovery/Web-Content/raft-large-words.txt \
       -mc 200,301,302 -fc 404 -ti -o "${OUTDIR}/ffuf.json" -of json
}

run_nikto() {
  echo "[*] Nikto baseline scan..."
  nikto -host "${BASEURL}" -output "${OUTDIR}/nikto.txt"
}

run_nuclei() {
  echo "[*] Nuclei CVE/template scan..."
  nuclei -u "${BASEURL}" -t cves/ -o "${OUTDIR}/nuclei.txt"
}

run_sqlmap() {
  echo "[*] SQLMap injection test..."
  mkdir -p "${OUTDIR}/sqlmap"
  sqlmap -u "${BASEURL}/?id=1" --batch --output-dir="${OUTDIR}/sqlmap"
}

run_xsstrike() {
  echo "[*] XSStrike XSS scan..."
  xsstrike --url "${BASEURL}" --crawl-depth 1 --output "${OUTDIR}/xsstrike.txt"
}

run_screenshots() {
  echo "[*] Aquatone screenshots..."
  echo "${BASEURL}" | aquatone -out "${OUTDIR}/aquatone"

  echo "[*] EyeWitness screenshots..."
  eyewitness --web -f "${OUTDIR}/gobuster.txt" -d "${OUTDIR}/eyewitness"
}

run_tls_detect() {
  echo "[*] TLS on port 80 detection..."
  curl -vk --connect-to "::${TARGET}:80" https://${TARGET}/ 2>&1 | tee "${OUTDIR}/tls_on_80.txt"
}

run_zap() {
  echo "[*] OWASP ZAP baseline scan..."
  zap-baseline.py -t "${BASEURL}" -r "${OUTDIR}/zap_report.html"
}

#### Main Execution ####
run_nmap
run_http_checks
run_whatweb
run_wafw00f
run_gobuster
run_ffuf
run_nikto
run_nuclei
run_sqlmap
run_xsstrike
run_screenshots
run_tls_detect
run_zap

echo -e "\n[✔] port80 audit complete. See results in ./${OUTDIR}/"
describe_results

