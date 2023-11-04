# %% Import libraries
import pandas as pd
import numpy as np

# %% Read the datafram from CSV
df_all = pd.read_csv('StatBlinks_df_all.csv')

#%% Make an unordered dict by subjectID / condition / song / [list of blink counts over trials]
blink_trials = {}
for subjectID in df_all['subjectID'].unique():
    blink_trials[subjectID] = {}

    for condition in df_all['condition'].unique():
        blink_trials[subjectID][condition] = {}

        for chorale in df_all['chorale'].unique():
            blinks = df_all[
                (df_all['subjectID'] == subjectID) &
                (df_all['condition'] == condition) &
                (df_all['chorale'] == chorale)
            ]['blinks']

            blinks = np.array(blinks)
            blink_trials[subjectID][condition][chorale] = blinks            
  
print(blink_trials)
# %%
