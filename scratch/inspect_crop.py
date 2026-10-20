from PIL import Image

img = Image.open('C:/Users/pc/.gemini/antigravity-ide/brain/cf0ee85e-efcf-4ef2-bb95-c7c879188f42/.user_uploaded/media_1792406324913.png')
print('Size:', img.size)
for y in range(img.size[1]):
    line = []
    for x in range(img.size[0]):
        r, g, b, a = img.getpixel((x, y))
        if r > 150 and g < 70 and b < 70:
            line.append('R')
        elif r < 50 and g < 50 and b < 50:
            line.append('B')
        elif r > 240 and g > 240 and b > 240:
            line.append('.')
        else:
            line.append('?')
    print(f'{y:2d}: ' + ''.join(line[50:130]))
