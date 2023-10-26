import numpy as np
from collections import OrderedDict

# Note the file is an ordered dictionary
eog_peaks_filename = 'eog_peaks_21subs.npy'
arr = np.load(eog_peaks_filename, allow_pickle=True)
arr = arr.flat[0]

# 88 = 4 songs * 2 conditions * 11 trials
# print(len(arr[1]))

# arr subject -> trial -> eogevents & source
# eogevents = time of blinks seconds = val/64
# len(eogevents) = number of blinks



subject1 = arr[1]

# Parsing the data to get the blinks mapped to the keys (see below)
blinks = OrderedDict()

for val in subject1:
    blinks[val] = len(subject1[val]['ica_eog_events'])



np.save("BlinksData.npy", blinks, allow_pickle=True)


# Listening: Song chor-096: Indices:
# [ 0  1  2  3  4  5  6  7  8  9 10]
# Listening: Song chor-038: Indices:
# [11 12 13 14 15 16 17 18 19 20 21]
# Listening: Song chor-101: Indices:
# [22 23 24 25 26 27 28 29 30 31 32]
# Listening: Song chor-019: Indices:
# [33 34 35 36 37 38 39 40 41 42 43]
# Imagery: Song chor-096: Indices:
# [44 45 46 47 48 49 50 51 52 53 54]
# Imagery: Song chor-038: Indices:
# [55 56 57 58 59 60 61 62 63 64 65]
# Imagery: Song chor-101: Indices:
# [66 67 68 69 70 71 72 73 74 75 76]
# Imagery: Song chor-019: Indices:
# [77 78 79 80 81 82 83 84 85 86 87]









# arr = np.load("eog_peaks_21subs.npy", allow_pickle=True)

# print("Dims are:")
# print(arr.ndim)

# print("Size is:")
# print(arr.size)

# print(arr[0])