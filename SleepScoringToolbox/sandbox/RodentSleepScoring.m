function [ScoreIndex,CompareStruct] = RodentSleepScoring(EEG,EMG)
% RodentSleepScoring is the sleep scoring framework to load data, artifact 
% detect and score eeg states.
% Without arguments, associated functions can import Neuroexplorer Files
% and .Dat Files (UW Psych EEG recording format) 
%
% Usage:
%  >> ScoreVec = RodentSleepScoring(EEG,EMG)
%
% Inputs:
%   EEG        - vector of analog values (optional);
%   EMG        - vector of analog values (optional);
%
% Outputs:
%   ScoreVec   - vector of identified states.
%
% See also: 
%   ParameterFile for framework settings.
%
% Copyright (C) 2010 by David Devilbiss <ddevilbiss@wisc.edu>
%
% ToDo: Finish putting in nLeng Fail
%

LogFileName = ['RodentSleepScoring' datestr(now(), 'yyyymmddHHMMSS') '.log'];
ScoreIndex = [];
StimulusStruct = [];
CompareStruct = [];
SelectChan = false;

%load Sleep Scoring parameters
params = ParameterFile();

%% No Inputs (Open Dialog and import data):
if nargin < 1
    [FileName,PathName,FilterIndex] = uigetfile({'*.nex','Neuroexploder File (*.nex)';'*.dat','Rat Physio File (*.dat)'},'Select Neuroexplorer File To Be Scored');
    if FilterIndex == 1;
        NexStruct = fullreadNexFile(fullfile(PathName,FileName));
    elseif FilterIndex == 2;
        [EEGData,PHYSIO_HEADER] = ReadBerridgeDATFile(fullfile(PathName,FileName));
        FileName = [FileName,'.nex'];
        PHYSIO_HEADER.filename = fullfile(PathName,FileName);
        NexStruct = Dat2Nex(PHYSIO_HEADER,EEGData);
        clear EEGData PHYSIO_HEADER;
    else
        return;
    end
    appendLogMessage(LogFileName,['SleepScoring: ',fullfile(PathName, FileName)]);
    SelectChan = true;
elseif nargin == 1
    if ischar(EEG)
        NexStruct = fullreadNexFile(fullfile(EEG));
        appendLogMessage(LogFileName,['SleepScoring: ',EEG]);
        SelectChan = true;
    end
end

%select Channels if requested
if SelectChan
    %select Channel to EEG score
    contVarStruct = [NexStruct.contvars{:}];
    ADnames = {contVarStruct.name};
    [EEGchan,OK] = listdlg('PromptString','Choose EEG Channel to Analyze','SelectionMode','Single','ListString',ADnames);
    if ~OK
        disp('No EEG channel selected: Terminating Function');
        appendLogMessage(LogFileName,'No EEG channel selected: Terminating Function');
        return;
    else
        %extract EEG/EMG data into common var's (EEG,EMG)
        chanNum = find(strcmp({contVarStruct.name},ADnames{EEGchan}));
        EEG = SSM_assembleRawSignal(contVarStruct(chanNum));
        SampleHz = contVarStruct(chanNum).ADFrequency;
        StartOffset = contVarStruct(chanNum).timestamps(1);
    end
    
    [EMGchan,OK] = listdlg('PromptString','Choose EMG Channel','SelectionMode','Single','ListString',ADnames);
    if ~OK
        disp('No EMG channel selected: Running Scoring Without EMG');
        appendLogMessage(LogFileName,'No EMG channel selected: Running Scoring Without EMG');
        EMG = [];
    else
        chanNum = find(strcmp({contVarStruct.name},ADnames{EMGchan}));
        EMG = SSM_assembleRawSignal(contVarStruct(chanNum));
    end
    
    if isfield(NexStruct,'events')
    eventVarStruct = [NexStruct.events{:}];
    Eventnames = {eventVarStruct.name};
    [EVENTchan,OK] = listdlg('PromptString','Choose Stimulus Event Channel','SelectionMode','Single','ListString',Eventnames);
    if ~OK
        disp('No Event channel selected: Running Scoring Without Event Blanking');
        appendLogMessage(LogFileName,'No Event channel selected: Running Scoring Without Event Blanking');
        STIMULUS = [];
        StimulusStruct = [];
    else
        chanNum = find(strcmp({eventVarStruct.name},Eventnames{EVENTchan}));
        STIMULUS = eventVarStruct(chanNum).timestamps;
        
        disp('generating stimulus windows... ');
        appendLogMessage(LogFileName,['SleepScoring: generating stimulus windows... ']);
        StimulusStruct.intStarts = STIMULUS -params.StimWindow.Xmin;
        StimulusStruct.intEnds = STIMULUS +params.StimWindow.Xmax;
        %pad Struct for NexFile
        StimulusStruct = addAncInfo(StimulusStruct,1,length(StimulusStruct.intStarts),2);
        StimulusStruct.name = 'StimulusWindow';
    end
    end
end

%now we have a vector for EEG and (possibly EMG Data) so cleanup workspace
disp('cleaning workspace... ');
clear contVarStruct eventVarStruct;
pause(0.01);drawnow();

%Update params Struct with File Specific data
params.LogFileName = LogFileName;


%% Downsample if necessary
if SampleHz > params.File.SampleHz
    disp(['Downsampling to ',num2str(params.File.SampleHz),' Hz']);
    appendLogMessage(LogFileName,['SleepScoring: Downsampling to ',num2str(params.File.SampleHz),' Hz']); 
    EEG = resample(EEG,params.File.SampleHz,SampleHz);
else
    params.File.SampleHz = SampleHz; %<< NOTE Untested with DAT data
end

%% Detect Artifact for file segment using EEG
%This will return a struct of intervals relating to artifacts and remove
%artifact from EEG
disp('detecting Artifacts... ');
appendLogMessage(LogFileName,'SleepScoring: Detecting Artifacts... '); 
    
if ~isempty(StimulusStruct)
    ArtifactStruct = ArtifactDetection(params,EEG,StimulusStruct);
    [EEG, ArtifactStruct] = RemoveArtifact(params,EEG,ArtifactStruct,StimulusStruct);
else
    ArtifactStruct = ArtifactDetection(params,EEG);
    [EEG, ArtifactStruct] = RemoveArtifact(params,EEG,ArtifactStruct);
end
ArtifactStruct.name = 'Artifacts';

%% Run Sleep Scoring
disp('Generating Sleep Scoring...');
appendLogMessage(LogFileName,'SleepScoring: Generating Sleep Scoring... '); 
[ScoreIndex, ValidScoreIndex] = SleepScoreModule(EEG,EMG,params);

% %Archtecture Rules
if params.rules.ApplyArchitectureRules
disp('Applying Architecture Rules...');
appendLogMessage(LogFileName,'SleepScoring: Applying Architecture Rules... '); 
%ScoreIndex = ArchitectureRules(ScoreIndex, params);
[ScoreIndex2, medScoreIndex] = StateTransitionRules(ScoreIndex, ValidScoreIndex, params);
figure;plot(ScoreIndex,'r');hold on;plot(ScoreIndex2,'g');plot(medScoreIndex,'m');
legend('Original','Applied Rules','Median Filter');
title('Hypnogram');
ScoreIndex = ScoreIndex2;
end

if params.File.CompareScorings
    if ~all(ScoreIndex == 0)
        %is it is not one state
    appendLogMessage(LogFileName,'SleepScoring: Comparing Scoring... '); 
    CompareStruct = CompareScoring(ScoreIndex, NexStruct, params);
    save(['ConfusionMatrix_',FileName,'.mat'], '-struct', 'CompareStruct');
    else
        disp('SleepScoring: Singular state - no comparison made.');
        appendLogMessage(LogFileName,'SleepScoring: Singular state - no comparison made.'); 
    end
end

% Generate Sleep Score struct
ScoreStruct = GenerateSleepScoreStruct(ScoreIndex,params,StartOffset);

%% Write Updated Neuroexplorer File
if nargin < 1
    disp('Writing Nex File... ');
    if isfield(NexStruct,'intervals')
        numNEXInts = length(NexStruct.intervals);
    else
        numNEXInts = 0;
    end
    numScoreInts = length(ScoreStruct);
    numArtifactInt = 0;
    
    if ~isempty(ArtifactStruct.intStarts)
        NexStruct.intervals{numNEXInts+1,1} = ArtifactStruct;
        numArtifactInt = 1;
        
    end
    
    if ~isempty(StimulusStruct)
        if ~isempty(StimulusStruct.intStarts)
            NexStruct.intervals{numNEXInts+ numArtifactInt+ 1,1} = StimulusStruct;
            numArtifactInt = numArtifactInt +1;
        end
    end
    
    for curInt = 1:numScoreInts
        NexStruct.intervals{numNEXInts+ numArtifactInt+ curInt,1} = ScoreStruct(curInt);
    end
    
    %update nVar in NexStruct
    NexStruct.nvar = NexStruct.nvar+ numArtifactInt + numScoreInts;
    [nexStruct] = write2NexFile(NexStruct, fullfile(PathName,['SCORED_',FileName]));
    
    %% Write data to EDF <<<Broken
%     % build header
%     HDR.FileName = fullfile(PathName,[FileName(1:end-4),datestr(now,'HHMMSS'),'.edf']);
%     HDR.SampleRate = contVarStruct(chanNum).ADFrequency;
%     gdftyp = 16;
%     HDR.TYPE = 'EDF';
%     [HDR.SPR, HDR.NS] = size(DATA);
%     HDR.NRec = 1;
%     HDR.PhysMax = max(DATA,[],1);
%     HDR.PhysMin = min(DATA,[],1);
%     ix = find(HDR.PhysMax == HDR.PhysMin);
%     HDR.PhysMin(ix) = HDR.PhysMin(ix) - 1;
%     HDR.DigMin = double(int16(HDR.PhysMin / contVarStruct(chanNum).ADtoMV + contVarStruct(chanNum).MVOfffset));
%     HDR.DigMax = double(int16(HDR.PhysMax / contVarStruct(chanNum).ADtoMV + contVarStruct(chanNum).MVOfffset));
%     HDR.T0 = datevec(now);
%     HDR.PhysDimCode = 4256; %mV
%     
%     %convert to int16
% %DATA = DATA / contVarStruct(chanNum).ADtoMV + contVarStruct(chanNum).MVOfffset;
%     
%     edfHDR = sopen(HDR,'w');
%         %edfHDR.FLAG.UCAL = true;
%         %edfHDR.RID = ['Startdate ',datestr(edfHDR.T0,'dd-mmm-yyyy')];
%         warning off;
%     edfHDR = swrite(edfHDR,DATA);
%         warning on;
%     edfHDR = sclose(edfHDR);
%     
    
    
end