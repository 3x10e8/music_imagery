%% Add eeglab to path
addpath ../eeglab

% Lauch eeglab
eeglab

%% Load Stim mat file from dataset
stim_path = './data/musicImagery/dataCND/dataStim.mat';
load(stim_path)

% stimIdx to name mapping was missing in the stim struct
% Identified stimIdx names from matching sheet music to provided events
% 2: 'chor-038', 
% 1: 'chor-096', 
% 3: 'chor-101',
% 4: 'chor-019', 

stimNames = {};
stimNames{1} = 'chor-096';
stimNames{2} = 'chor-038';
stimNames{3} = 'chor-101';
stimNames{4} = 'chor-019';

%% Load One Subject's Data
% subject = 1; % works well
subject = 2; % blinker status shows bad

data_path = ['./data/musicImagery/dataCND/dataSub', num2str(subject), '.mat'];
data_path = join(data_path);
load(data_path)

%% Merge all trials into one 3D matrix

data = []; % nbchan x points x trials, from https://sccn.ucsd.edu/~arno/eeglab/auto/eeglab.html
trialsval = {}; % trial labels, trial and epoch appears to be used interchangeably in EEGLAB

trialIdx = 1;
for origTrialIdx = eeg.origTrialPosition
    
    % eeg.data{trial_idx} is 1803x64 (time x chans)
    % transpose to get chans x time 
    data(:, :, trialIdx) = eeg.data{origTrialIdx}';

    % Identify the corresponding stimulus and condition 
    stimIdx = stim.stimIdxs(origTrialIdx);
    stimName = stimNames{stimIdx};
    condIdx = stim.condIdxs(origTrialIdx);
    condName = stim.condNames{condIdx};
    condition = [condName, '_', stimName];

    trialsval{trialIdx, 1} = condName;
    trialsval{trialIdx, 2} = stimName;

    trialIdx = trialIdx + 1;

end

%% Import the data into EEGLAB as an epoched set
% 
% EEG = pop_importdata('setname', 'musicImagery' ...
%         , 'data', data ...
%         , 'subject', subject ...
%         , 'condition', 'all' ...
%         , 'session', 1 ...
%         , 'nbchan', 64 ...
%         , 'chanlocs', eeg.chanlocs ...
%         , 'srate', eeg.fs ...
%         );
%         %, 'ref', '', );
% 
% % EEG_TRIALS.epoch = 1:88;
% EEG.epoch = trialsval'; % append trial descriptors (is EEG.trialsval not supported?)
% EEG.epochdescription = {'condName'; 'stimName'}; % EEG.epoch column descriptors
% EEG.filename = ['dataSub', num2str(subject), '.mat']; 
% EEG, changes = eeg_checkset(EEG); % check for errors?
% 
% % Save set?
% %save('sub1', eeg.data, )

%% Merge all trials into one dataset
for origTrialIdx = eeg.origTrialPosition
    
    % eeg.data{trial_idx} is 1803x64 (time x chans)
    % transpose to get chans x time (for EEGLAB import below)
    data = eeg.data{origTrialIdx}';

    % Identify the corresponding stimulus and condition 
    stimIdx = stim.stimIdxs(origTrialIdx);
    stimName = stimNames{stimIdx};
    condIdx = stim.condIdxs(origTrialIdx);
    condName = stim.condNames{condIdx};
    condition = [condName, '_', stimName];

    EEG_TRIAL = pop_importdata('setname', 'musicImagery' ...
        , 'data', data ...
        , 'subject', subject ...
        , 'condition', condition ...
        , 'session', 1 ...
        , 'nbchan', 64 ...
        , 'chanlocs', eeg.chanlocs ...
        , 'srate', eeg.fs ...
        );
        %, 'ref', '', );

    if origTrialIdx == eeg.origTrialPosition(1)
        EEG = EEG_TRIAL;
    else % append the new trial's data
        EEG = pop_mergeset(EEG, EEG_TRIAL); % looses condition info
    end

end

%% Run blinker (doesn't take epoched data, expects continuous input)

params = checkBlinkerDefaults(struct(), getBlinkerDefaults(EEG));
params.subjectID = num2str(subject);
params.experiment = 'musicImagery';
params.uniqueName = 'allTrials';
params.task = 'allConditions';
params.fileName = ['dataSub', num2str(subject), '.mat']; 
params.blinkerSaveFile = ['dataSub', num2str(subject), '_BlinkSummary.mat'];
params.dumpBlinkerStructures = true;
params.dumpBlinkImages = false; %true;
params.dumpBlinkPositions = true;
params.keepSignals = false;
params.showMaxDistribution = true;
params.verbose = true;
params.excludeLabels = {''};

[OUTEEG, com, blinks, blinkFits, blinkProperties, ...
                     blinkStatistics, params] = pop_blinker(EEG, params);

%% Print some stats
blinks
blinkStatistics