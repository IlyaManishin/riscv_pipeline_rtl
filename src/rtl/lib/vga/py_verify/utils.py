import numpy as np

# returns indices of measurements AFTER the edge
def posedges(data):
    return np.flatnonzero((data[:-1] == 0) & (data[1:] != 0)) + 1

def negedges(data):
    return np.flatnonzero((data[:-1] != 0) & (data[1:] == 0)) + 1


def print_stats(data: np.array):
    print(f'min: {np.min(data)}, max: {np.max(data)}, avg: {np.average(data)}, shape: {data.shape}')