from PIL import Image, ImageDraw, ImageFont


# vlines
img = Image.new('RGB', (640, 480))
d = ImageDraw.Draw(img)
for i in range(640):
    d.line((i, 0, i, 480-1), 'blue' if i%2 == 0 else 'red', width=1)
img.save('test_patterns/v_lines.png')

# checkerboard
img = Image.new('RGB', (640, 480))
d = ImageDraw.Draw(img)
for y in range(480):
    for x in range(640):
        colors = ['white', 'black']
        if x == 0 or y == 0 or x == 640-1 or y == 480 - 1:
            colors = ['green', 'red']
        color = colors[x&1 ^ y&1]
        d.point((x, y), color)
d.point((0, 0), 'blue')
img.save('test_patterns/checkerboard.png')

# checkerboard 320x240
img = Image.new('RGB', (320, 240))
d = ImageDraw.Draw(img)
for y in range(240):
    for x in range(320):
        colors = ['white', 'black']
        if x == 0 or y == 0 or x == 320-1 or y == 240 - 1:
            colors = ['green', 'red']
        color = colors[x&1 ^ y&1]
        d.point((x, y), color)
d.point((0, 0), 'blue')
img.save('test_patterns/checkerboard_320x240.png')

# box
img = Image.new('RGBA', (640, 480))
d = ImageDraw.Draw(img)
d.rectangle((0, 0, 639, 479), 'white', 'green', 5)
d.line((0, 0, 639, 479), 'yellow', 5)
d.line((0, 479, 639, 0), 'magenta', 5)
rv_logo = Image.open('test_patterns/RISC-V-logo-square.svg.png.src')
rv_logo.thumbnail((150, 150))
img.paste(rv_logo, (640//4 - rv_logo.size[0]//2, 480//2 - rv_logo.size[1]//2), rv_logo)
img.paste(rv_logo, (640//4*3 - rv_logo.size[0]//2, 480//2 - rv_logo.size[1]//2), rv_logo)
img.paste(rv_logo, (640//2 - rv_logo.size[0]//2, 480//4 - rv_logo.size[1]//2), rv_logo)
img.paste(rv_logo, (640//2 - rv_logo.size[0]//2, 480//4*3 - rv_logo.size[1]//2), rv_logo)
img.save('test_patterns/box.png')

# box 320x240
img = Image.new('RGBA', (320, 240))
d = ImageDraw.Draw(img)
d.rectangle((0, 0, 320-1, 240-1), 'white', 'green', 5)
d.line((0, 0, 320-1, 240-1), 'yellow', 5)
d.line((0, 240-1, 320-1, 0), 'magenta', 5)
rv_logo = Image.open('test_patterns/RISC-V-logo-square.svg.png.src')
rv_logo.thumbnail((150//2, 150//2))
img.paste(rv_logo, (640//8 - rv_logo.size[0]//2, 480//4 - rv_logo.size[1]//2), rv_logo)
img.paste(rv_logo, (640//8*3 - rv_logo.size[0]//2, 480//4 - rv_logo.size[1]//2), rv_logo)
img.paste(rv_logo, (640//4 - rv_logo.size[0]//2, 480//8 - rv_logo.size[1]//2), rv_logo)
img.paste(rv_logo, (640//4 - rv_logo.size[0]//2, 480//8*3 - rv_logo.size[1]//2), rv_logo)
d.text((10, 10), '320x240 (QVGA)', fill='red')
img.save('test_patterns/box_320x240.png')

open('test_patterns/ladder.bin', 'w').write(bytearray([i for i in range(256)]*1200).hex(' '))