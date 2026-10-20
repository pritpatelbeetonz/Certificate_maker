from PIL import ImageFont

for fs in [7.5, 8.0, 8.5, 9.0, 9.5, 10.0]:
    font = ImageFont.truetype('assets/Final_Certificates/Fonts/LibreBaskerville-VariableFont_wght.ttf', int(fs * 3))
    bbox = font.getbbox('OF ACHIEVEMENT')
    print(f'fontSize {fs}: bbox={bbox}, w={bbox[2]-bbox[0]} (v={(bbox[2]-bbox[0])/3:.1f}), h={bbox[3]-bbox[1]} (v={(bbox[3]-bbox[1])/3:.1f})')
