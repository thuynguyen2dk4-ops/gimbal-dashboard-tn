import sys
sys.stdout.reconfigure(encoding='utf-8')

p = r'C:\Users\thuyn\.copilot\repos\gimbal-dashboard-tn\public\web\google_auth.html'
with open(p, 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.find('<script>')
print(text[idx:])
