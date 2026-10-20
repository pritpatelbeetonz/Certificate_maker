from PIL import Image

bg = Image.open('assets/Final_Certificates/Achievement/9/bg.png')
print('bg size:', bg.size)
# virtual y: 70 to 105 -> scaled 3x: 210 to 315
# virtual x: 100 to 360 -> scaled 3x: 300 to 1080
crop = bg.crop((300, 210, 1080, 315))
crop.save('scratch/bg_crop_sub.png')
print('Saved bg_crop_sub.png')
