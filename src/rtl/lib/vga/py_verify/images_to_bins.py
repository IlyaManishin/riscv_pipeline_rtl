import itertools

from PIL import Image
import os


def convert_color(p: tuple[int, ...]) -> int:
    return ((p[0] >> 5) << 5) | ((p[1] >> 5) << 2) | (p[2] >> 6)


for img_f in os.listdir('./test_patterns'):
    if not img_f.endswith('.png'):
        continue
    img = Image.open(f'./test_patterns/{img_f}')
    res = bytearray()
    print(img.size)
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            res.append(convert_color(img.getpixel((x, y))))
    # hex files for $readmemh
    with open(f'test_patterns/{img_f}.bin', 'w') as f:
        f.write(res.hex(' ') )

    # coe files
    with open(f'test_patterns/{img_f}.coe', 'w') as f:
        s = f'memory_initialization_radix=16;\n'
        s += 'memory_initialization_vector=\n'

        ints = []
        for b in itertools.batched(res, 4):
            i = int.from_bytes(b, byteorder='little', signed=False) # TODO: figure out the correct byteorder
            ints.append(f'{i:4x}')
        s += ', '.join(ints) + ';\n'
        f.write(s)

