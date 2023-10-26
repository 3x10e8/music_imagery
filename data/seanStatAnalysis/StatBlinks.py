import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from scipy.stats import ttest_ind

# Taking in the subject data, each condition (see map) is the key for a
# blink value that is the number of blinks in the duration of the trial
arr = np.load('Subject1BlinksData.npy', allow_pickle=True)
arr = arr.flat[0]

# Numerical map for each of the song and listening or imagining conditions
Listeningchor96_Indexes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
Imaginingchor96_Indexes = [44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54]

Listeningchor38_Indexes = [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]
Imaginingchor38_Indexes = [55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65]

Listeningchor101_Indexes = [22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]
Imaginingchor101_Indexes = [66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76]

Listeningchor19_Indexes = [33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43]
Imaginingchor19_Indexes = [77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87]


chors = [Listeningchor19_Indexes,Listeningchor38_Indexes,Listeningchor96_Indexes,Listeningchor101_Indexes,
         Imaginingchor19_Indexes,Imaginingchor38_Indexes,Imaginingchor96_Indexes,Imaginingchor101_Indexes]


# Creating 2D array with rows equal to the number of chors and conditions and cols equal to test number
ConditionArray = np.empty([len(chors),len(chors[1])], dtype=int)

# Filling 2D ndarray with blink info row corresponds to L/I + chor##
# and col is the number of blinks in one of the 11 trials
rowi = 0
for chorindexes in chors:

    coli = 0
    for key in chorindexes:
        ConditionArray[rowi, coli] = arr[key]
        coli += 1

    rowi += 1


# Running statistical analysis with student's t. Comparing each condition to all others
# Array for storing the tstatistic and pval results as a list with [tstat, pval]
StatArray = np.empty([8,8], dtype = list)


# Conducting two-tailed t test as the null hypothesis is that there is difference between the distributions
# Each distribution will be compared against all other distributions, including itself
rowi = 0
for Row in ConditionArray:
    # print(Row)
    coli = 0
    for Col in ConditionArray:

        t_statistic, p_value = ttest_ind(Row, Col)
        
        StatArray[rowi, coli] = [t_statistic, p_value]
        coli += 1

    rowi += 1


# print(StatArray)


# Converting StatArray to a dataframe for easy analysis

df = pd.DataFrame(StatArray)

chors = [Listeningchor19_Indexes,Listeningchor38_Indexes,Listeningchor96_Indexes,Listeningchor101_Indexes,
         Imaginingchor19_Indexes,Imaginingchor38_Indexes,Imaginingchor96_Indexes,Imaginingchor101_Indexes]


# Rename columns and rows for easy analysis
df.rename(columns={0: 'Listeningchor19', 1: 'Listeningchor38', 2: 'Listeningchor96', 3: 'Listeningchor101',
                 4: 'Imaginingchor19', 5: 'Imaginingchor38', 6: 'Imaginingchor96', 7: 'Imaginingchor101'}, inplace=True)

df.rename(index={0: 'Listeningchor19', 1: 'Listeningchor38', 2: 'Listeningchor96', 3: 'Listeningchor101',
                 4: 'Imaginingchor19', 5: 'Imaginingchor38', 6: 'Imaginingchor96', 7: 'Imaginingchor101'}, inplace=True)


print(df)

# Save to Excel
df.to_excel('StatBlinks.xlsx', index=False)


# Plotting ---- in progress ----
# categories = ["t1", "t2"]
# test = [1,2]
# plt.bar(categories, test)

# plt.show()



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