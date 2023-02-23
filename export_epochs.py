from scipy.io import loadmat
# https://docs.scipy.org/doc/scipy/reference/generated/scipy.io.loadmat.html

import matplotlib.pyplot as plt
import numpy as np
import mne
import os
import pandas as pd
import librosa
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

dataDir = r'D:\marion_music_imagery\datasetCND_musicImagery\musicImagery'
stimId_to_Song_map = {4: 'chor-019', 2: 'chor-038', 1:'chor-096', 3:'chor-101'}
condId_to_State_map = {1: 'Listening', 2: 'Imagery'}

note_id_humanReadable = {'F_4': 66, # replacing the # keys for 'sharp,' because its interfereing w saving
                        'B4': 71,
                        'A4': 69,
                        'G4': 67,
                        'E4': 64,
                        'C_5': 73,
                        'D5': 74,
                        'E5': 76,
                        'F4': 65,
                        'C5': 72,
                        'A_4': 70,
                        'C4': 60,
                        'D4': 62,
                        'C_4': 61,
                        'F5': 77,
                        'D_5': 75,
                        'G_4': 68,
                        'F_5': 78 }

song_events_dict ={}
labels = ['chor-019','chor-038','chor-096','chor-101']
stimId_labels = [4, 2, 1, 3] 
for i in range(len(labels)):
    song_id = labels[i]
    song_events_dict[song_id]={}
    song_events_dict[song_id]['stimIdLabel']=stimId_labels[i]

    song_events_dict[song_id]['note_events_array'] = np.load(os.getcwd()+'\events_array_'+song_id+'.npy')
    for arr_type in ['audio','metronome','time']:
        song_events_dict[song_id][arr_type+'_wav_array'] = np.load(os.getcwd()+'\wavFileExtract_'+song_id+'_'+arr_type+'.npy')

# For each song type we'll want to use the expectation markers as our method of extracting the note identity. We'll have to match the timing of these by getting the timing of the expectation mark and using this as a reference to the note id scheme. 
# this will work as long as the expectation is the same length as the data, and the timing of the note identity aligns with the timing of the expectation mark
def render_event_array(expectations_this_trial, this_song_label, data_this_trial, fs):

    # assuming data has already been transposed as is shape (chan,times)
    assert data_this_trial.shape[1] == expectations_this_trial.shape[0] # expect it to be len 1803

    # get the times of each expectation event
    expectations_this_trial_times = np.asarray(np.round(np.arange(len(expectations_this_trial))/fs, decimals=1)) # in seconds, and rounding up so that it matches the note timing resolution

    # get the expected note values for this song, and their corresponding onset/offset times
    this_song_note_events = song_events_dict[this_song_label]['note_events_array']
    extract_Note_ids =[]
    extract_Note_times_ON = []
    extract_Note_times_OFF = []
    for evs in this_song_note_events:
        extract_Note_ids.append(evs[0]) # grabbing the note ID from the midi files
        extract_Note_times_ON.append(evs[1]/1000) # grab the onsets, in terms of seconds
        extract_Note_times_OFF.append(evs[2]/1000) # grab the offsets, in terms of seconds
    extract_Note_ids = np.asarray(extract_Note_ids)
    extract_Note_times_ON = np.asarray(extract_Note_times_ON)
    extract_Note_times_OFF = np.asarray(extract_Note_times_OFF)

    # get an array of how long each note lasts for this song
    note_durations= extract_Note_times_OFF - extract_Note_times_ON
    # we can epoch according to the shortest note, but its good to know how long they last
    min_note_dur, max_note_dur = np.min(note_durations), np.max(note_durations)

    ev_array = []
    metadata_evs = pd.DataFrame()
    ## LOOP through the samples of the expectations and extract the note identity
    for timepoint in range(data_this_trial.shape[1]):
        # loop through each timepoint, grab out the corresponding expectation value
        expect_this_time = expectations_this_trial[timepoint]

        # if the expecation value is zero, then we don't care about it.
        # but if its anything greater than zero, this indicates it's a note we care about
        if expect_this_time != 0:
            # if there's an expectation at this sample, grab out the equivalent timepoint in the note_id array
            expect_noteTime = expectations_this_trial_times[timepoint]
            note_id_thisTimepoint = extract_Note_ids[extract_Note_times_ON == expect_noteTime]
            
            #print(note_id_thisTimepoint)
            # make sure there's only one note happening at this sample
            assert len(note_id_thisTimepoint) == 1

            # and append it to our events array
            ev_array.append([timepoint, 0, int(note_id_thisTimepoint[0]) ])
            metadata_evs = metadata_evs.append({'song_type':this_song_label, 'midi_note_label':note_id_thisTimepoint[0], 'str_note_label': librosa.midi_to_note(int(note_id_thisTimepoint[0])),
                                                'expectation_value':expect_this_time, 
                                                'note_dur':(extract_Note_times_OFF[np.where(extract_Note_times_ON == expect_noteTime)[0]])-(expect_noteTime)}, ignore_index=True)

    assert len(ev_array) == np.sum(expectations_this_trial != 0)  

    return extract_Note_ids, extract_Note_times_ON, expectations_this_trial_times[expectations_this_trial != 0 ], ev_array, min_note_dur, max_note_dur, metadata_evs

stim_mat = loadmat(dataDir+r"/dataCND/dataStim.mat", simplify_cells = True) 
stim = stim_mat['stim']
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

fs = stim['fs']
print(f'fs shape: {stimIdxs.shape}')

for s in range(1,22):
    subN_mat = loadmat(dataDir+r"/dataCND/dataSub"+str(s)+".mat", simplify_cells = True) 

    dataType = subN_mat['eeg']['dataType']
    print(f'dataType shape: {dataType.shape}')

    fs = subN_mat['eeg']['fs']
    print(f'fs: {fs}')

    data = subN_mat['eeg']['data']
    print(f'data shape: {data.shape}')

    orig_trial_pos = subN_mat['eeg']['origTrialPosition']
    print(f'orig_trial_pos shape: {orig_trial_pos.shape}')

    trial_num = data.shape[0] # get N trials
    thisSubStimOrder = stimIdxs[(orig_trial_pos-1)] # convert to being zero indexed
    thisSubCondOrder = condIdxs[(orig_trial_pos-1)]
    thisSubAcousticEnv = events[0][(orig_trial_pos-1)] # rearrange the arrays so that they're unscrambled, in chronological order
    thisSubExpectations = events[1][(orig_trial_pos-1)]
    chanLocs = subN_mat['eeg']['chanlocs']
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

    taskTypes = ['Listening', 'Imagery']
    wholeExpDict = {x:[] for x in taskTypes} # setting up our dict to be populated later. Each entry in the list will be one trial, given as MNE raw until epoched
    assert len(chanLocs) == 64


    for t in range(trial_num):
        # every trial, we want to add the data the 2D array we'll feed into RawArray (shape n_chan, n_times). We want to epoch the data around the notes, so with every trial
        # we will also add the events matrix as a 'find events' standin.
        # Verify that the biosemi layout is correct
        # and when epoching add the stimulus info as metadata (one row for every epochs obj, since in reality it is one 'trial')

        thisTrialData = data[t].T # transpose so its [chan,times] 
        thisTrialCond = thisSubCondOrder[t] # listening or imagining
        thisTrialSong = thisSubStimOrder[t] # which song it was
        thisTrialAcousticEnv = thisSubAcousticEnv[t]
        thisTrialExpectations = thisSubExpectations[t] # the expectations for this trial
        thisTrialSongLabel = stimId_to_Song_map[thisTrialSong] # get the string labels for this stim
        thisTrialTaskLabel = condId_to_State_map[thisTrialCond]  # get the string label for this task state (listening, imaging)

        note_ids_from_midi, note_onsets_from_midi, _,  ev_array, min_note_dur, max_note_dur,metadata_envs = render_event_array(expectations_this_trial= thisTrialExpectations, this_song_label= thisTrialSongLabel, data_this_trial=thisTrialData, fs=fs)

        event_dict_thisTrial={}
        for key in note_id_humanReadable.keys(): # loop through all over strings of keys
            thisMidiID = note_id_humanReadable[key] 

            for note in ev_array: # loop through the midi notes for this trial
                if note[2] == thisMidiID and (key not in event_dict_thisTrial): 
                    event_dict_thisTrial[key]=thisMidiID

        info = mne.create_info(ch_names=montage_chs+['stim_014'], sfreq=64.0, ch_types=['eeg']*len(chanLocs)+['stim'])

        data_plus_stim = np.zeros((thisTrialData.shape[0]+1, thisTrialData.shape[1])) # 65, n_times
        data_plus_stim[:thisTrialData.shape[0], :]=thisTrialData/10000000
        rawArr = mne.io.RawArray( data = data_plus_stim,
                                info = info,
                                first_samp = 0 # have to check in on this parameter-- not sure what it is
        )
        rawArr.add_events(events=ev_array, stim_channel='stim_014')
        eps = mne.Epochs(raw=rawArr, event_id=event_dict_thisTrial, events=ev_array, tmin=-0.5, tmax=2.0, baseline=(None,0), metadata=metadata_envs)
        eps.set_montage('biosemi64')

        wholeExpDict[thisTrialTaskLabel].append(eps)

    # save the data
    for task in taskTypes:

        comb_eps = mne.concatenate_epochs(wholeExpDict[task])
        comb_eps.save(fname=os.getcwd()+r'\epoched_data'+'\concatEps_sub'+str(s)+'_'+task+'-epo.fif')

        
