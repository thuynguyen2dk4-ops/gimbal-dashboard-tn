import sys
sys.stdout.reconfigure(encoding='utf-8')

p = r'C:\Users\thuyn\.copilot\repos\gimbal-dashboard-tn\public\web\user_dashboard.html'
with open(p, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, l in enumerate(lines):
    if 'google_auth.html' in l or 'loginWithGoogle' in l or 'OAuth' in l:
        print(f'Line {i+1}: {l.strip()[:100]}')
        print(''.join(lines[max(0, i-5):min(len(lines), i+25)]))
        print('---')
