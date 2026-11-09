import os, sys
sys.stdout.reconfigure(encoding='utf-8')

repo = r'C:\Users\thuyn\.copilot\repos\gimbal-dashboard-tn'
scratch = r'C:\Users\thuyn\.gemini\antigravity\scratch\smart_gimbal_ui'

for d in [repo, scratch]:
    for root, dirs, files in os.walk(d):
        for f in files:
            if f.endswith('.html') or f.endswith('.js') or f.endswith('.py'):
                fp = os.path.join(root, f)
                try:
                    with open(fp, 'r', encoding='utf-8', errors='ignore') as s:
                        content = s.read()
                        if 'google_auth.html' in content:
                            print(f'Found in {os.path.relpath(fp, d)}')
                except:
                    pass
