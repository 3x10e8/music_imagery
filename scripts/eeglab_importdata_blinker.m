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
for subject = 3 %1:21
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
            , 'condition', 'merged' ...
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
    
    %% Save the set file before running AMICA
    if true % prevent accidental overwrites
        pop_saveset(...
            ALLEEG...
            , 'filename', ['sub', num2str(subject), '_merged_preica'] ...
            , 'filepath', './data/eog_peaks/merged_raws/blinker/' ...
            , 'check', 'on')
        %OUTEEG = ALLEEG;
        % pop_eegplot(ALLEEG, 0)
    end

    %% Load this set again to run AMICA
    ALLEEG = pop_loadset(['sub', num2str(subject), '_merged_preica.set'] ...
        , './data/eog_peaks/merged_raws/blinker/');

    %% Run ICA
    %ALLEEG = pop_runica(ALLEEG, 'icatype', 'runica');
    ALLEEG = pop_runamica(ALLEEG);

    %% Save the set file with ICA decomposition included
    if true % prevent accidental overwrites
        pop_saveset(...
            ALLEEG...
            , 'filename', ['sub', num2str(subject), '_merged_amica'] ...
            , 'filepath', './data/eog_peaks/merged_raws/blinker/' ...
            , 'check', 'on')
        %OUTEEG = ALLEEG;
        % pop_eegplot(ALLEEG, 0)
    end
end

%% Readback saved SET files
for subject = 3 %:21
    ALLEEG = pop_loadset(['sub', num2str(subject), '_merged_amica.set'] ...
        , './data/eog_peaks/merged_raws/blinker/')
    
    %% Now relaunch GUI to run ICLabel
    % updating makes it now ask for >100Hz sampling rate
    %eeglab redraw
    ALLEEG = pop_iclabel(ALLEEG, 'default');
    [pClass, eyeICidxs] = sortrows(...
        ALLEEG.etc.ic_classification.ICLabel.classifications,...
        3, 'descend');
    topEyeICidxs = eyeICidxs(1:3); %pClass(:, 3)>0.9) % >90% eye class
    pClass(1:3, 3);
    
    %%
    pIdx = 1
    for icIdx = topEyeICidxs'
        fh = pop_prop_extended(ALLEEG ...
            , 0 ...
            , icIdx ...
            , NaN ...
            , {} ...
            , {});
        saveas(fh ...
            , ['./data/eog_peaks/merged_raws/blinker/' ...
            , 'sub', num2str(subject)...
            , '_ic', num2str(icIdx)...
            , '_pEye', num2str(round(100*pClass(pIdx, 3)))] ...
            , 'png')
        pIdx = pIdx + 1;
    end
end

%% Manually identify blink ICs from the top 3 ICLabel Eye ICs
manualTopBlinkIC = zeros(1, 21);
%manualTopBlinkIC(1) = 1; % blinks with amica
manualTopBlinkIC(1) = 2; % blinks
manualTopBlinkIC(2) = 7; % maybe subject doesn't blink much
manualTopBlinkIC(3) = 1; % blinks + saccades?
manualTopBlinkIC(4) = 1; % good
manualTopBlinkIC(5) = 2; % good
manualTopBlinkIC(6) = -1; % good
manualTopBlinkIC(7) = 2; % good, blinks a lot
manualTopBlinkIC(8) = 2; % longer blinks
manualTopBlinkIC(9) = -1; 
manualTopBlinkIC(10) = 2;
manualTopBlinkIC(11) = -1; 
manualTopBlinkIC(12) = -1; % saccades?
manualTopBlinkIC(13) = 1;
manualTopBlinkIC(14) = 2;
manualTopBlinkIC(15) = 2;
manualTopBlinkIC(16) = -2;
manualTopBlinkIC(17) = 1; % blinks a lot
manualTopBlinkIC(18) = 2;
manualTopBlinkIC(19) = 3; % saccades?
manualTopBlinkIC(20) = 1;
manualTopBlinkIC(21) = 1;

%% Now run blinker on manually selected IC only
for subject = 1 %:21 
    ALLEEG = pop_loadset(['sub', num2str(subject), '_merged_ica.set'] ...
        , './data/eog_peaks/merged_raws/blinker/ica_sets/');

    %% Swap in ICA components for regular EEG channels
    icdata = eeg_getdatact(ALLEEG, 'component', [1:size(ALLEEG.icaweights,1)]);
    topEyeICidxs = manualTopBlinkIC(subject);
    if topEyeICidxs > 0
        eyeICdata = icdata(topEyeICidxs, :);
    else % flip the sign
        eyeICdata = -icdata(topEyeICidxs, :);
    end

    % Now import this IC as a regular channel
    EEG_EYE_ICs = pop_importdata('setname', 'musicImagery' ...
            , 'data', eyeICdata ...
            , 'subject', subject ...
            , 'condition', 'merged' ...
            , 'session', 1 ...
            , 'nbchan', length(topEyeICidxs) ...
            , 'chanlocs', [] ...
            , 'srate', eeg.fs ...
            );

    %% Run blinker (doesn't take epoched data, expects continuous input)
    params = checkBlinkerDefaults(struct(), getBlinkerDefaults(EEG_EYE_ICs));
    params.lowCutoffHz = 1; % increased from default 1Hz, improved blink detection in 10 subjects
    params.highCutoffHz = 20;
    params.blinkAmpRange = [3, 50]; %[3, 50];
    params.stdThreshold = 0.2;
    params.pAVRThreshold = 3; %3; 
    params.correlationThresholdTop = 0.98; % "best" blinks
    params.correlationThresholdMiddle = 0.95;
    params.correlationThresholdMiddle = 0.9; % still "good"

    if any(subject == [2, 7])
        EEG_EYE_ICs = ALLEEG; % blink finding seems to fail, but IC does show blinks.
        % revert to blink finding with scalp channels
        %params.goodRatioThreshold = 0.1;
        %params.minGoodBlinks = 1;
        %params.stdThreshold = 1;
        %params.lowCutoffHz = 4;
    else % limit signalNumbers to the one manually labelled blink IC
        params.signalNumbers = 1;
    end
    
    params.subjectID = num2str(subject);
    params.uniqueName = 'allTrials';
    params.experiment = 'musicImagery';
    params.task = 'allConditions';
    %params.startDate
    %params.startTime
    
    params.signalTypeIndicator = 'UseNumbers';
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
    
    try
        [OUTEEG, com, blinks, blinkFits, blinkProperties, ...
                             blinkStatistics, params] = pop_blinker(...
                             EEG_EYE_ICs ...
                             , params);
    end 


    %% Print some stats
    blinks;
    blinkStatistics;
    
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
