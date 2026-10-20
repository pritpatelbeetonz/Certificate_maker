from PIL import Image

crop = Image.open('scratch/thumb_sub_detail.png').convert('RGB')
red_ys = []
for y in range(crop.size[1]):
    for x in range(crop.size[0]):
        r, g, b = crop.getpixel((x, y))
        if r > 160 and g < 60 and b < 60:
            red_ys.append(y)

print('Min Y in crop:', min(red_ys), 'Max Y in crop:', max(red_ys))
print('Capital height in thumbnail (px):', max(red_ys) - min(red_ys) + 1)
print('Virtual capital height:', (max(red_ys) - min(red_ys) + 1) / 3.0)
