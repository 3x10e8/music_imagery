%% Add eeglab to path
cd /Users/3x10e8/Documents/GitHub/music_imagery.nosync
addpath ../eeglab
addpath ../eeglab/plugins/Blinker1.2.0/utilities/+pr/private/
% eyecatch mat files were missing, had to be downloaded from 
% https://github.com/bigdelys/eye-catch/tree/master/private

% But these are included in blinker as of 6months ago:
% https://github.com/VisLab/EEG-Blinks/tree/master/blinker/utilities/%2Bpr/private

% Launch eeglab
% eeglab

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
for subject = 2 %:21
    % subject = 1; % works well

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
    
    EEG_EPS = pop_importdata('setname', 'musicImagery' ...
            , 'data', data ...
            , 'subject', subject ...
            , 'condition', 'all' ...
            , 'session', 1 ...
            , 'nbchan', 64 ...
            , 'chanlocs', eeg.chanlocs ...
            , 'srate', eeg.fs ...
            );
            %, 'ref', '', );
    
    % EEG_TRIALS.epoch = 1:88;
    EEG_EPS.epoch = trialsval'; % append trial descriptors (is EEG.trialsval not supported?)
    EEG_EPS.epochdescription = {'condName'; 'stimName'}; % EEG.epoch column descriptors
    EEG_EPS.filename = ['dataSub', num2str(subject), '.mat']; 
    EEG_EPS, changes = eeg_checkset(EEG_EPS); % check for errors?
    % 
    % % Save set?
    % %save('sub1', eeg.data, )

    %% Run ICA
    EEG_EPS = pop_runica(EEG_EPS, 'icatype', 'runica')
    %OUTEEG = ALLEEG;
    % pop_eegplot(ALLEEG, 0)

    %% Now relaunch GUI to run ICLabel
    %eeglab redraw
    EEG_EPS = pop_iclabel(EEG_EPS, 'default'); % fails for epoched ICs?
    [pClass, eyeICidxs] = sortrows(...
        EEG_EPS.etc.ic_classification.ICLabel.classifications,...
        3, 'descend');
    topEyeICidxs = eyeICidxs(1:3); %(pClass(:, 3)>0.9) % >90% eye class
    pop_prop(EEG_EPS, 0, topEyeICidxs(1))

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
            ALLEEG = EEG_TRIAL;
        else % append the new trial's data
            ALLEEG = pop_mergeset(ALLEEG, EEG_TRIAL); % looses condition info
        end
    
    end
    
    %% Run ICA
    ALLEEG = pop_runica(ALLEEG, 'icatype', 'runica')
    %OUTEEG = ALLEEG;
    % pop_eegplot(ALLEEG, 0)

    %% Now relaunch GUI to run ICLabel
    %eeglab redraw
    ALLEEG = pop_iclabel(ALLEEG, 'default');
    [pClass, eyeICidxs] = sortrows(...
        ALLEEG.etc.ic_classification.ICLabel.classifications,...
        3, 'descend');
    topEyeICidxs = eyeICidxs(pClass(:, 3)>0.9) % >90% eye class

    %% Swap in ICA components for regular EEG channels
    icdata = eeg_getdatact(ALLEEG, 'component', [1:size(ALLEEG.icaweights,1)]);
    eyeICdata = icdata(topEyeICidxs, :);
    EEG_EYE_ICs = pop_importdata('setname', 'musicImagery' ...
            , 'data', eyeICdata ...
            , 'subject', subject ...
            , 'condition', condition ...
            , 'session', 1 ...
            , 'nbchan', length(topEyeICidxs) ...
            , 'chanlocs', [] ...
            , 'srate', eeg.fs ...
            );
    
    %% Run blinker (doesn't take epoched data, expects continuous input)
    params = checkBlinkerDefaults(struct(), getBlinkerDefaults(EEG_EYE_ICs));
    
    params.subjectID = num2str(subject);
    params.uniqueName = 'allTrials';
    params.experiment = 'musicImagery';
    params.task = 'allConditions';
    %params.startDate
    %params.startTime
    
    params.signalTypeIndicator = 'UseNumbers';
    params.signalNumbers = 1:length(topEyeICidxs);
    %params.signalTypeIndicator = 'UseICs';
    %params.signalNumbers = [3, 8];
    
    %params.signalLabels = {''};
    %params.excludeLabels = {''};
    
    params.dumpBlinkerStructures = true;
    params.showMaxDistribution = true;
    params.dumpBlinkImages = false;
    params.verbose = true;
    params.dumpBlinkPositions = true;
    
    params.fileName = ['dataSub', num2str(subject), '.mat']; 
    params.blinkerSaveFile = ['dataSub', num2str(subject), '_BlinkSummary.mat'];
    params.blinkerDumpDir = ['/Users/3x10e8/Documents/GitHub/music_imagery.nosync', ...
        '/blinkDump/']; %, 'Sub', num2str(subject)];
    params.keepSignals = false;
    
    [OUTEEG, com, blinks, blinkFits, blinkProperties, ...
                         blinkStatistics, params] = pop_blinker(...
                         EEG_EYE_ICs ...
                         , params);
    
    %% Print some stats
    blinks
    blinkStatistics
    
    %%
%     figure()
%     blinkSignal = blinks.signalData.signal;
%     plot(blinkSignal); hold on
%     
%     blinkPositions1 = blinks.signalData.blinkPositions(1, :);
%     blinkPositions2 = blinks.signalData.blinkPositions(2, :);
%     
%     plot(blinkPositions1, blinkSignal(blinkPositions1), 'rx')
%     plot(blinkPositions2, blinkSignal(blinkPositions2), 'gx')
end
