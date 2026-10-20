import json

data = json.load(open('assets/Final_Certificates/Achievement/9/Scarlet_Ribbon.json', encoding='utf-8'))
for l in data['scene']['layers']:
    b = l.get('bounds', {})
    print(f"{l['id']}: z={l.get('zIndex')}, y={b.get('y')}, h={b.get('height')}, x={b.get('x')}, w={b.get('width')}")
