from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
import requests
import socket
import urllib3
import time
from io import BytesIO
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from engine import get_subdomains

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

app = Flask(__name__)
CORS(app)

@app.route('/scan', methods=['GET'])
def scan():
    domain = request.args.get('domain')
    if not domain:
        return jsonify({"error": "No domain provided"}), 400
    results = get_subdomains(domain)
    return jsonify(results)

@app.route('/scan_ports', methods=['GET'])
def scan_ports():
    target = request.args.get('domain')
    if not target:
        return jsonify({"error": "No domain provided"}), 400

    common_ports = [
        {'port': 80, 'service': 'HTTP', 'priority': 100},
        {'port': 443, 'service': 'HTTPS', 'priority': 100},
        {'port': 21, 'service': 'FTP', 'priority': 60},
        {'port': 22, 'service': 'SSH', 'priority': 90},
        {'port': 23, 'service': 'Telnet', 'priority': 50},
        {'port': 25, 'service': 'SMTP', 'priority': 70},
        {'port': 53, 'service': 'DNS', 'priority': 80},
        {'port': 3306, 'service': 'MySQL', 'priority': 75},
        {'port': 3389, 'service': 'RDP', 'priority': 70},
        {'port': 8080, 'service': 'HTTP-Proxy', 'priority': 80},
        {'port': 445, 'service': 'SMB', 'priority': 85}
    ]

    priority_queue = sorted(common_ports, key=lambda x: x['priority'], reverse=True)
    results = []
    
    for item in priority_queue:
        port = item['port']
        service = item['service']
        priority = item['priority']
        status = "Closed"
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(0.5)
            result = sock.connect_ex((target, port))
            if result == 0:
                status = "Open"
            sock.close()
        except:
            pass

        results.append({
            "port": port,
            "service": service,
            "status": status,
            "priority": priority
        })

    return jsonify({"target": target, "scan_results": results})

@app.route('/detect_tech', methods=['GET'])
def detect_tech():
    target = request.args.get('domain')
    if not target:
        return jsonify({"error": "No domain provided"}), 400

    if not target.startswith('http'):
        target = 'http://' + target

    detected_tech = []
    try:
        response = requests.get(target, timeout=5, verify=False)
        headers = response.headers
        content = response.text.lower()
        cookies = str(response.cookies.get_dict())

        rules = [
            {'name': 'WordPress', 'check': lambda: 'wp-content' in content},
            {'name': 'Laravel', 'check': lambda: 'laravel' in cookies},
            {'name': 'Django', 'check': lambda: 'csrftoken' in cookies},
            {'name': 'React', 'check': lambda: 'react' in content},
            {'name': 'Nginx', 'check': lambda: 'nginx' in headers.get('Server', '').lower()},
            {'name': 'Apache', 'check': lambda: 'apache' in headers.get('Server', '').lower()},
            {'name': 'Cloudflare', 'check': lambda: 'cloudflare' in headers.get('Server', '').lower()},
            {'name': 'PHP', 'check': lambda: 'php' in headers.get('X-Powered-By', '').lower()}
        ]

        for rule in rules:
            if rule['check']():
                detected_tech.append(rule['name'])

        if not detected_tech:
            detected_tech.append("Unknown Stack")

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    return jsonify({"target": target, "technologies": detected_tech})

@app.route('/assess_risk', methods=['GET'])
def assess_risk():
    target = request.args.get('domain')
    if not target:
        return jsonify({"error": "No domain provided"}), 400

    if not target.startswith('http'):
        target_url = 'http://' + target
        target_host = target
    else:
        target_url = target
        target_host = target.split('//')[1].split('/')[0]

    risk_score = 0
    issues = []

    try:
        response = requests.get(target_url, timeout=5, verify=False)
        headers = response.headers

        security_headers = ['X-Frame-Options', 'X-XSS-Protection', 'Strict-Transport-Security']
        for h in security_headers:
            if h not in headers:
                issues.append(f"Missing Security Header: {h}")
                risk_score += 15

        critical_ports = [21, 22, 3389]
        for port in critical_ports:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(0.5)
            if sock.connect_ex((target_host, port)) == 0:
                risk_score += 20
                issues.append(f"Critical Port Open: {port}")
            sock.close()

        risk_score = min(risk_score, 100)
        risk_level = "Low"
        if risk_score > 75: risk_level = "CRITICAL"
        elif risk_score > 40: risk_level = "High"
        elif risk_score > 20: risk_level = "Medium"

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    return jsonify({
        "target": target,
        "risk_score": risk_score,
        "risk_level": risk_level,
        "issues": issues
    })

@app.route('/generate_report', methods=['GET'])
def generate_report():
    target = request.args.get('domain')
    if not target:
        return "Target domain is required", 400
    
    subdomains_list = []
    open_ports_list = []
    detected_tech = []
    issues = []
    risk_score = 0
    
    try:
        if not target.startswith('http'): 
            url = 'http://' + target
            hostname = target
        else: 
            url = target
            hostname = target.split('//')[1].split('/')[0]
        
        try:
            resp = requests.get(url, timeout=5, verify=False)
            server = resp.headers.get('Server', 'Unknown')
            powered = resp.headers.get('X-Powered-By', 'Unknown')
            detected_tech.append(f"Server: {server}")
            detected_tech.append(f"Backend: {powered}")
            
            if 'X-Frame-Options' not in resp.headers:
                issues.append("Missing Clickjacking Protection (X-Frame-Options)")
                risk_score += 20
            if 'Strict-Transport-Security' not in resp.headers:
                issues.append("Missing HSTS (SSL Stripping Risk)")
                risk_score += 20
        except:
            detected_tech.append("Target Unreachable")

        try:
            graph_data = get_subdomains(hostname) 
            if 'nodes' in graph_data:
                for node in graph_data['nodes'][:12]: 
                    subdomains_list.append(node['label'])
        except Exception as e:
            pass

        critical_ports = [21, 22, 80, 443, 3306, 3389, 8080]
        for port in critical_ports:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(0.3)
                result = sock.connect_ex((hostname, port))
                if result == 0:
                    open_ports_list.append(str(port))
                    risk_score += 10
                    issues.append(f"Open Port Detected: {port}")
                sock.close()
            except:
                pass

    except Exception as e:
        pass

    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4

    c.setFillColor(colors.black)
    c.rect(0, height - 80, width, 80, fill=True, stroke=False)
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 22)
    c.drawString(30, height - 50, "NEXUS INTELLIGENCE REPORT")
    c.setFont("Helvetica", 10)
    c.drawString(width - 150, height - 50, "CONFIDENTIAL")

    current_y = height - 120

    c.setFillColor(colors.black)
    c.setFont("Helvetica-Bold", 14)
    c.drawString(30, current_y, f"Target: {hostname}")
    c.setFont("Helvetica", 10)
    c.drawString(30, current_y - 15, f"Scan Date: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    score_color = colors.green
    if risk_score > 40: score_color = colors.orange
    if risk_score > 70: score_color = colors.red
    
    c.setFillColor(score_color)
    c.circle(width - 80, current_y - 10, 30, fill=True, stroke=False)
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 16)
    c.drawCentredString(width - 80, current_y - 15, f"{risk_score}")
    c.setFont("Helvetica", 8)
    c.drawCentredString(width - 80, current_y - 35, "RISK SCORE")

    current_y -= 60
    c.setStrokeColor(colors.grey)
    c.line(30, current_y, width - 30, current_y)
    current_y -= 30

    c.setFillColor(colors.darkblue)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(30, current_y, "1. TECHNOLOGY STACK")
    current_y -= 20
    c.setFillColor(colors.black)
    c.setFont("Courier", 10)
    for tech in detected_tech:
        c.drawString(50, current_y, f"• {tech}")
        current_y -= 15
    current_y -= 10

    c.setFillColor(colors.darkblue)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(30, current_y, "2. OPEN PORTS & SERVICES")
    current_y -= 20
    c.setFillColor(colors.black)
    c.setFont("Courier", 10)
    if open_ports_list:
        c.drawString(50, current_y, f"Detected Open Ports: {', '.join(open_ports_list)}")
    else:
        c.drawString(50, current_y, "No critical open ports found (Quick Scan).")
    current_y -= 30

    c.setFillColor(colors.darkblue)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(30, current_y, "3. DISCOVERED SUBDOMAINS")
    current_y -= 20
    c.setFillColor(colors.black)
    c.setFont("Courier", 10)
    
    if subdomains_list:
        for sub in subdomains_list:
            c.drawString(50, current_y, f"• {sub}")
            current_y -= 15
            if current_y < 150:
                c.drawString(50, current_y, "... (Truncated for PDF)")
                break
    else:
         c.drawString(50, current_y, "No subdomains found or scan timed out.")

    current_y -= 20

    c.setFillColor(colors.red)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(30, current_y, "4. SECURITY ISSUES IDENTIFIED")
    current_y -= 20
    c.setFillColor(colors.black)
    c.setFont("Courier", 10)
    for issue in issues:
        c.drawString(50, current_y, f"[-] {issue}")
        current_y -= 15

    c.setFont("Helvetica-Oblique", 8)
    c.setFillColor(colors.grey)
    c.drawCentredString(width / 2, 30, "Generated by Nexus Engine. © Nexus Systems.")

    c.save()
    buffer.seek(0)
    
    return send_file(buffer, as_attachment=True, download_name=f'vortex_report_{hostname}.pdf', mimetype='application/pdf')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
