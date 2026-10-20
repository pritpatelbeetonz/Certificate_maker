from PIL import Image

thumb = Image.open('assets/Final_Certificates/Achievement/9/thumbnail.png')
# virtual size is 463 x 333 -> thumbnail is 1389 x 999 (scale 3.0)
# 'CERTIFICATE' is y: 51 -> scaled: 153
# 'OF ACHIEVEMENT' is y: 84 -> scaled: 252
# Let's crop around 'OF ACHIEVEMENT' (x: 550 to 850, y: 240 to 280)
crop = thumb.crop((550, 240, 850, 280))
crop.save('scratch/thumb_sub_detail.png')
print('Saved thumb_sub_detail.png')
