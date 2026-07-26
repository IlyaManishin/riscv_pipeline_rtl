import sys

import pandas as pd
import numpy as np

from config import *
from utils import *


if len(sys.argv) != 2:
    print(f'Usage: {sys.argv[0]} path_to_trace.csv')
    exit(1)

df = pd.read_csv(sys.argv[1])

vsync = df['vsync'].to_numpy()
hsync = df['hsync'].to_numpy()
r = df['r'].to_numpy()
g = df['g'].to_numpy()
b = df['b'].to_numpy()

color_sum = r+g+b

hsync_starts = negedges(hsync)
hsync_ends = posedges(hsync)

vsync_starts = negedges(vsync)
vsync_ends = posedges(vsync)

print('Test pattern should NOT contain black pixels!')

line_start_by_color = posedges(color_sum)
line_starts_by_hsync = hsync_ends + H_BP
if np.setdiff1d(line_start_by_color, line_starts_by_hsync).shape[0] != 0:
    print('Color start at incorrect time!')
else:
    print('Line color starts ok')


print('\nLine duration data:')
print_stats(hsync_starts[1:] - hsync_starts[:-1])
print('HSync pulse data:')
print_stats(hsync_ends - hsync_starts)

print('\nFrame duration data (in lines):')
print_stats((vsync_starts[1:] - vsync_starts[:-1]) / PIXELS_IN_LINE)
print('VSync duration data:')
print_stats((vsync_ends - vsync_starts))

frame_starts = vsync_ends + V_BP
if np.setdiff1d(frame_starts, line_start_by_color).shape[0] == 0:
    print('Frame starts OK')
else:
    print('Frames start at wrong timing\n')


frame_durations_in_lines_by_color = []
i_start = 0
i_prev = 0
for i in line_start_by_color:
    if i - i_prev <= PIXELS_IN_LINE:
        i_prev = i
    else:
        frame_durations_in_lines_by_color.append(i_prev - i_start + PIXELS_IN_LINE)
        i_start = i
        i_prev = i
frame_durations_in_lines_by_color = np.array(frame_durations_in_lines_by_color)
print('Frame durations by color in lines:', frame_durations_in_lines_by_color / PIXELS_IN_LINE)
print('Line durations by color:')
print_stats(negedges(color_sum)[1:] - posedges(color_sum)) 
