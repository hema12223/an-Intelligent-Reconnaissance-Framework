import requests

def get_subdomains(target_domain):
    print(f"[*] Starting Intelligence gathering for: {target_domain}")
    results = set()
    

    print(f"[*] Querying CRT.SH database (this might take time)...")
    try:
        url = f"https://crt.sh/?q=%.{target_domain}&output=json"

        response = requests.get(url, timeout=60) 
        
        if response.status_code == 200:
            data = response.json()
            for entry in data:
                name_value = entry['name_value']
                for sub in name_value.split('\n'):
                    if target_domain in sub and "*" not in sub:
                        results.add(sub)
            print(f"[+] CRT.SH returned {len(results)} subdomains.")
            
    except Exception as e:
        print(f"[-] CRT.SH failed or timed out: {e}")
        print("[*] Switching to Backup Source...")


    if len(results) == 0:
        print(f"[*] Querying HackerTarget API...")
        try:
            url = f"https://api.hackertarget.com/hostsearch/?q={target_domain}"
            response = requests.get(url, timeout=30)
            
            if response.status_code == 200:
                lines = response.text.split('\n')
                for line in lines:
                    if "," in line:
                        sub = line.split(',')[0]
                        if target_domain in sub:
                            results.add(sub)
                print(f"[+] HackerTarget returned {len(results)} subdomains.")
        except Exception as e:
            print(f"[-] HackerTarget failed: {e}")

    return list(results)

