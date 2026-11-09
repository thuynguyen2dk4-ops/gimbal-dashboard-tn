import sys
sys.stdout.reconfigure(encoding='utf-8')

p = r'C:\Users\thuyn\.copilot\repos\gimbal-dashboard-tn\public\web\index.html'
with open(p, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, l in enumerate(lines):
    if 'function renderNavUserSection' in l:
        print(''.join(lines[i:i+55]))
        break
