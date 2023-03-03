################################################
## Environment setup
################################################
from scipy.io import loadmat
import os

# Path to musicImagery dataset
dataDir = r'data/musicImagery'
#dataDir = r'D:\marion_music_imagery\datasetCND_musicImagery\musicImagery'

################################################
## Load stimuli
################################################
stim_mat = loadmat(dataDir+r"/dataCND/dataStim.mat", simplify_cells = True) 
stim = stim_mat['stim']
# print(stim)

stimIdxs = stim['stimIdxs']
print(f'stimIdxs shape (N trials): {stimIdxs.shape}')

condIdxs = stim['condIdxs']
print(f'condIdxs shape (N trials): {condIdxs.shape}')

condNames = stim['condNames']
print(f'condNames shape (P conditions): {condNames.shape}')

events = stim['data']
print(f'events shape (M features, N trials): {events.shape}')

event_labels = stim['names']
print(f'event names shape (M features): {event_labels.shape}')

# fs = stim['fs'] # ignore, use fs from data struct (64 Hz)
# print(f'fs shape: {stimIdxs.shape}')

# Handy mapping of indices to labels
stimId_to_Song_map = {4: 'chor-019', 2: 'chor-038', 1:'chor-096', 3:'chor-101'}
condId_to_State_map = {1: 'Listening', 2: 'Imagery'}

# Collect stim idxs by condition and song
idxs = {} # dict to store idxs for each condition and stim/song idx

for cond in condList: # two conditions
    condName = condNames[cond-1] # MATLAB indexes from 1...
    idxs[condName] = {}
    
    for song in songList:
        
        print(f'{condNames[cond-1]}: Song {song}: Indices:') 
        matched_ndx = np.where(
            (stimIdxs == song) & (condIdxs == cond)
            )[0]
        print(matched_ndx)
        
        idxs[condName][song] = matched_ndx

################################################
## Load EEG data for a subject
################################################
subjectID = 1
sub1_mat = loadmat(dataDir+f"/dataCND/dataSub{subjectID}.mat", simplify_cells = True) 

fs = sub1_mat['eeg']['fs']
print(f'fs: {fs}')

data = sub1_mat['eeg']['data']
print(f'data shape: {data.shape}')

orig_trial_pos = sub1_mat['eeg']['origTrialPosition']
print(f'orig_trial_pos shape: {orig_trial_pos.shape}')

chanLocs = sub1_mat['eeg']['chanlocs']

################################################
## Import data into MNE
################################################

# Clean up channels
old_chs = ['T7 (T3)', 'Iz (inion)', 'Afz', 'T8 (T4)']
edited_chs = ['T7','Iz','AFz','T8']

montage_chs =[]
for k in chanLocs:
    ch_n = k['labels']
    if ch_n not in old_chs:
        montage_chs.append(ch_n)
    else:
        for i in range(len(old_chs)):
            if ch_n == old_chs[i]:
                montage_chs.append(edited_chs[i])

# Select a song and condition to ICA on
cond = 'Listening'
song = 'chor-019'
trialsToEpoch = idxs[cond][song]
print(cond, song, trialsToEpoch)

N_trials = data.shape[0] # get N trials

# Get current subject's song and condition ordering (since its randomized)
thisSubStimOrder = stimIdxs[(orig_trial_pos-1)] # convert to being zero indexed
thisSubCondOrder = condIdxs[(orig_trial_pos-1)]
print(f'Subject{subjectID} stim order: {thisSubStimOrder}')
print(f'Subject{subjectID} cond order: {thisSubCondrder}')

if 0:
	# Don't baseline correct the epochs for ICA
	for n_trial in trialsToEpoch:

		thisTrialData = data[n_trial].T # transpose so its [chan,times] 
		thisTrialCond = thisSubCondOrder[n_trial] # listening or imagining
		thisTrialSong = thisSubStimOrder[n_trial] # which song it was
	    
		thisTrialSongLabel = stimId_to_Song_map[thisTrialSong] # get the string labels for this stim
		thisTrialTaskLabel = condId_to_State_map[thisTrialCond]  # get the string label for this task state (listening, imaging)

		info = mne.create_info(
			ch_names=montage_chs+['stim_014'], 
			sfreq=64.0, 
			ch_types=['eeg']*len(chanLocs)+['stim']
		)
