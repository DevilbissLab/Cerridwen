function [status, msg] = NSB_Workflow_LIMS(handles)
%[status, msg] = NSB_Workflow_LIMS(handles)
%
% Inputs:
%   handles              - (struct) from PreclinicalEEGFramework
%
% Outputs:
%   status               - (logical) return value
%   msg                  - (string) status message if error
%
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0
% March 10 2013, Version 2.0
% April 16 2025, Version 3.0

%Also see MATLAB Memory Shielding
%StudyDesign{1,1}.path sometime is cell when loading DSI DATA from Dir.

%% Notes
% From main GUI there is passed 
%   handles.parameters - DataSpider and PreClinicalFramework
%   handles.licensing
%   handles.StudyDesign - what files to run - metadata on output files
%   handles.AnalysisStruct - What analysis components to run
%
%   inputParms - Local struct to be passed to functions
%
% Not sure why we need the options struct - seems redundant
% options is a sloppy holdover and can be updated sometime

status = false;
msg = '';
AbortFileLoad = false;
NSBlog(handles.parameters.PreClinicalFramework.LogFile,'NSB_Workflow_LIMS: Begin');

% Create Local LIMS Struct
% For better code clarity and unified structure to pass to functions
LIMS.logfile = handles.parameters.PreClinicalFramework.LogFile;
LIMS.progress = handles.parameters.PreClinicalFramework.useWaitBar;
LIMS.Licensing = handles.licensing;
LIMS.StudyDesign = handles.StudyDesign; %This is a duplicate because we never want it changed except by this fcn
LIMS.PreClinicalFramework = handles.parameters.PreClinicalFramework;
LIMS.usingUniqueParmsFiles = false;
LIMS.showHeadPlot = handles.parameters.PreClinicalFramework.File.FIF.showHeadPlot;
LIMS.assumeTemplateChOrderCorrect = handles.parameters.PreClinicalFramework.File.FIF.assumeTemplateChOrderCorrect;
LIMS.ChanLocFiles_Dir = handles.parameters.PreClinicalFramework.File.FIF.ChanLocFiles_Dir;
LIMS.DSIoffset = handles.parameters.PreClinicalFramework.File.DSIoffset;
LIMS.AbortProcessing = false;
LIMS.chans = [];
LIMS.ValidDataChans = [];
LIMS.DoseChan = [];
LIMS.EMGChan = [];
LIMS.RefChan = [];
LIMS.PositionTemplate = '';
LIMS.subjectID = '';
LIMS.RecordingDate = [];
LIMS.HypnogramChannel = [];

%Create a logfile path copy for past compatability
handles.parameters.PreClinicalFramework.SpectralAnalysis.logfile = LIMS.logfile;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% This is the START of the main section for processing each Data FILE of StudyDesign       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(LIMS.StudyDesign)

    %Create a cancelable wait bar
    if LIMS.progress
        LIMS.hWaitbar = waitbar(0,'Processing File List ...','Name','Processing Files...',...
            'CreateCancelBtn',@NSB_ProgressCloseReq);
        setappdata(LIMS.hWaitbar,'Canceling',0);
        if handles.parameters.PreClinicalFramework.MatlabPost2014
            LIMS.hWaitbar.Children(2).Title.Interpreter = 'none';
        else
            hWaitBarChild = get(LIMS.hWaitbar,'Children');
            hWaitBarTitle = get(hWaitBarChild(1),'Title');
            set(hWaitBarTitle,'Interpreter','none')
        end
    end
    
    %% Iterate through each file/row if the Study design
    % Parse file specific data from each row
    % parallize here -> undocumented -> feature('numcores')
    for curFile = 1:size(LIMS.StudyDesign,1)
    % Clear all file specific data
    LIMS.chans = [];
    LIMS.ValidDataChans = [];
    LIMS.DoseChan = [];
    LIMS.EMGChan = [];
    LIMS.RefChan = [];
    LIMS.PositionTemplate = '';
    LIMS.subjectID = '';
    LIMS.RecordingDate = [];
    LIMS.HypnogramChannel = [];

        % determine whether there is a Per File - Parameter File
        % This is currently dirty.
        % The excell could have no entries, just the channel or both
        % if just channel:  handles.StudyDesign{1, 1}.AnalysisChan = struct =  {'EEG1-01-00',NaN;NaN,[]}
        % if channel + Parameter file:  handles.StudyDesign{1, 1}.AnalysisChan = struct =  {'EEG1-01-00','A:/none/no.txt';NaN,[]}
        % if no data: handles.StudyDesign{1, 1}.AnalysisChan = false
        
        if islogical(LIMS.StudyDesign{curFile,1}.AnalysisChan)
            % No analysis channel/parameters data
            
            % If a unique param file was loaded and there is not one now... load the default
            if LIMS.usingUniqueParmsFiles
                NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Parameter .xml not specified (using initial parameters from GUI): ',LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile]);
                LIMS.PreClinicalFramework = handles.parameters.PreClinicalFramework;
                LIMS.usingUniqueParmsFiles = false;
            end
            if strcmpi(LIMS.StudyDesign{curFile,1}.type, '.fif')
                LIMS.chans = LIMS.PreClinicalFramework.File.FIFtype;
            else
                LIMS.chans = [];
            end

        elseif isstruct(LIMS.StudyDesign{curFile,1}.AnalysisChan)
            %analysis channel/parameters data is in spreadsheet
            %this is a struct let it be because we will process each channel seperately later
            %contains .Name and .ParamsFile
            %
            % First process channel names
            try
                LIMS.chans = LIMS.StudyDesign{curFile, 1}.AnalysisChan;
            catch
                LIMS.chans = LIMS.StudyDesign{1, 1}.AnalysisChan;
                msg = ['Warning: NSB_Workflow_LIMS >> Channels not specified in row ',num2str(curFile +1),'. Using channels from first row.'];
                NSBlog(LIMS.logfile,msg);
            end

            % Second process parameter filenames
            if ~isempty(LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile)
                LIMS.usingUniqueParmsFiles = false;
                
                if ischar(LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile)
                    %this is a NaN or String (if contains data)
                    if exist(LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile,'file') == 2
                        DynParamGUIStruct = [];
                        if handles.parameters.PreClinicalFramework.MatlabPost2014
                            DynParamGUIStruct = tinyxml2_wrap('load', LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile);
                        else
                            DynParamGUIStruct = xml_load(LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile);
                        end

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Update ONLY the artifact detection.
                        [status, LIMS.PreClinicalFramework.ArtifactDetection, msg] = NSB_ParameterHandler('mergeExtAnalysisParms', LIMS.PreClinicalFramework.ArtifactDetection, DynParamGUIStruct.ArtifactDetection);

                        NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Updating/using artifact detection parameters from: ', LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile]);
                        NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Reference Channel will be taken from Study Design if it exists']);

                        LIMS.PreClinicalFramework.ArtifactDetection.full.DCcalculation = 'DC';
                        NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ..."FULL / FULL-EMG" Artifact detection using User set DC value']);

                        NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...All remaining parameters will not be altered']);
                        LIMS.usingUniqueParmsFiles = true;
                    else
                        NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Parameter .xml not found (using initial parameters from GUI): ',LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile]);
                        %If a unique param file was loaded and there is not one... load the default
                        LIMS.PreClinicalFramework = handles.parameters.PreClinicalFramework;
                        LIMS.usingUniqueParmsFiles = false;
                    end
                else
                    NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Parameter File value not a char array (using initial parameters from GUI): ',LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile]);
                    %If a unique param file was loaded and there is not one... load the default
                    LIMS.PreClinicalFramework = handles.parameters.PreClinicalFramework;
                    LIMS.usingUniqueParmsFiles = false;
                end
            else
                if LIMS.usingUniqueParmsFiles
                    NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Parameter .xml not specified (using initial parameters from GUI): ',LIMS.StudyDesign{curFile}.AnalysisChan(1).ParamsFile]);
                    %If a unique param file was loaded and there is not one now... load the default
                    LIMS.PreClinicalFramework = handles.parameters.PreClinicalFramework;
                end
                LIMS.usingUniqueParmsFiles = false;
            end
        else
            msg = ['Warning: NSB_Workflow_LIMS >> StudyDesign is neither a logical or struct. Skipping analysis row'];
            NSBlog(LIMS.logfile,msg);
            continue;
        end
        
        % determine whether there is a dose channel (not sure how to processes yet) <<optional???
        if isfield(LIMS.StudyDesign{curFile,1},'DoseChan')
            if all(isnan(LIMS.StudyDesign{curFile,1}.DoseChan)) || isempty(LIMS.StudyDesign{curFile,1}.DoseChan) %all() because this could also be a string
                LIMS.DoseChan = '';
            else
                LIMS.DoseChan = LIMS.StudyDesign{curFile,1}.DoseChan;
            end
        else
            LIMS.DoseChan = '';
        end
        % EMG Channel
        if ~isempty(LIMS.StudyDesign{curFile,1}.EMGchan)
            LIMS.EMGChan = LIMS.StudyDesign{curFile,1}.EMGchan;
        else
            LIMS.EMGChan = '';
        end
        % Reference Chan
        if ~isempty(LIMS.StudyDesign{curFile,1}.RefChannel)
            LIMS.RefChan = LIMS.StudyDesign{curFile,1}.RefChannel;
            LIMS.PreClinicalFramework.Reference.doReRef = true;
        else
            LIMS.RefChan = '';
            LIMS.PreClinicalFramework.Reference.doReRef = false;
        end
        %Position Template
        if ~isempty(LIMS.StudyDesign{curFile,1}.PositionTemplate)
            LIMS.PositionTemplate = LIMS.StudyDesign{curFile,1}.PositionTemplate;
        else
            LIMS.PositionTemplate = '';
        end
        %Subject ID to analyze <<make sure it is a str
        % This can also be a str ('File')
        if isfield(LIMS.StudyDesign{curFile,2},'animalID')
            if ~isempty(LIMS.StudyDesign{curFile,2}.animalID)
                if isnumeric(LIMS.StudyDesign{curFile,2}.animalID)
                    LIMS.StudyDesign{curFile,2}.animalID = num2str(LIMS.StudyDesign{curFile,2}.animalID);
                end
                LIMS.subjectID = LIMS.StudyDesign{curFile,2}.animalID;
            else
                LIMS.subjectID = '';
            end
        else
            LIMS.subjectID = '';
        end
        %Store date to compare with file stored date.
        if isfield(LIMS.StudyDesign{curFile,2},'date')
            if ~isempty(LIMS.StudyDesign{curFile,2}.date)
                LIMS.RecordingDate = datenum(LIMS.StudyDesign{curFile,2}.date);
            else
                LIMS.RecordingDate = [];
            end
        else
            LIMS.RecordingDate = [];
        end      
        
%% Load in file(s) for StudyDesign row

% Clear the Status panel
set(handles.status_stxt,'String', cell(0)); %create cell array
status = updatePreClinicalFrameworkStatus(handles, LIMS, LIMS.StudyDesign{curFile,1}.name);

[status, LIMS.AbortProcessing] = updateProgress(LIMS,curFile/size(LIMS.StudyDesign,1),['Subject: ',LIMS.StudyDesign{curFile,1}.name]);
if LIMS.AbortProcessing
    status = updatePreClinicalFrameworkStatus(handles, LIMS, 'File Import Aborted.', 'NSB_Workflow_LIMS');
    break; 
else       
        try
            if ischar(LIMS.StudyDesign{curFile,1}.path)
                logstr = ['NSB_Workflow_LIMS: Opening - ',LIMS.StudyDesign{curFile,1}.path,' : '];
            else
                logstr = ['NSB_Workflow_LIMS: Opening - ',LIMS.StudyDesign{curFile,1}.path{1},' : '];
            end
            if ischar(LIMS.StudyDesign{curFile,1}.name)
                 logstr = [logstr,LIMS.StudyDesign{curFile,1}.name];
            else
                logstr = [logstr,LIMS.StudyDesign{curFile,1}.name{1}];
            end   
            disp(logstr);
            NSBlog(LIMS.logfile,logstr);
            ReadTic = tic;

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load Files (Import)
            [readstatus, DataStruct] = NSB_DataImportModule(LIMS.StudyDesign{curFile,1}, LIMS);

            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Read Time = ',num2str(toc(ReadTic)), ' (sec)']);
            try
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: File Start Time = ',datestr(DataStruct.StartDate)]);
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: File End Time = ',datestr(DataStruct.Channel(1).ts(end))]);
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Timestamp Offset (To Be Applied) = ',...
                num2str(LIMS.PreClinicalFramework.File.DSIoffset),' hours']);
            catch
                 NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: No Timestamp/DSI Offset found in file']);
            end
       
            if readstatus
                status = updatePreClinicalFrameworkStatus(handles, LIMS, 'Loaded File...');
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Read OK - ',[LIMS.StudyDesign{curFile,1}.path, ' : ', LIMS.StudyDesign{curFile,1}.name]]);
            else
                status = updatePreClinicalFrameworkStatus(handles, LIMS, 'Read Failed...');
                 msg = ['NSB_Workflow_LIMS: Read FAILED - ',[LIMS.StudyDesign{curFile,1}.path, ' : ', LIMS.StudyDesign{curFile,1}.name]];
                 NSBlog(LIMS.logfile,msg);
                 disp(msg);
                continue;
            end
        catch ME
            msg = ME.message;
            return;
        end
end

%% Identify Channel Types in File
ChannelNames = {DataStruct.Channel(:).Name};
ChannelNumbers = [DataStruct.Channel(:).ChNumber];

% Identify EMG channels
keepEMGChannels = [];
if ~isempty(LIMS.EMGChan) % explicitly stated in Study Design
    if isnumeric(LIMS.EMGChan) && all(~isnan(LIMS.StudyDesign{curFile}.EMGchan))
        keepEMGChannels = LIMS.EMGChan;     %Numeric Ch Num
    elseif ischar(LIMS.EMGChan)
        selectedChan = find(strcmpi(ChannelNames, LIMS.EMGChan));
        if ~isempty(selectedChan)
            if length(selectedChan) > 1
                NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Found Multiple Matching EMG Channels #',num2str(EMGchannel),': ',datestr(now)]);
                NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Ignoring EMG chanels.']);
                LIMS.EMGChan = [];
            else
                keepEMGChannels = selectedChan; %Numeric Ch Num
            end
        else
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Selecting Channels >> Chan. not found: ',LIMS.StudyDesign{curFile}.EMGchan ]);
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Huristically trying to find EMG channel.']);
            % huristically try to find EMG channel
            selectedChan = find(~cellfun(@isempty,strfind(ChannelNames,'EMG')));
            if length(selectedChan) > 1
                NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Found Multiple Matching EMG Channels #',num2str(EMGchannel),': ',datestr(now)]);
                NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Ignoring EMG chanels.']);
                LIMS.EMGChan = [];
            else
                LIMS.EMGChan = selectedChan; %update options struct
                keepEMGChannels = selectedChan; %Numeric Ch Num
            end
        end
    end
else %is empty
    NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Huristically trying to find EMG channel.']);
    % huristically try to find EMG channel
    selectedChan = find(~cellfun(@isempty,strfind(ChannelNames,'EMG')));
    if length(selectedChan) > 1
        NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Found Multiple Matching EMG Channels #',num2str(selectedChan),': ',datestr(now)]);
        NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Ignoring EMG chanels.']);
        LIMS.EMGChan = [];
    else
        NSBlog(LIMS.logfile,['NSB_Workflow_LIMS >> Found EMG Channel #',num2str(selectedChan),' ',DataStruct.Channel(selectedChan).Name,': ',datestr(now)]);
        LIMS.EMGChan = selectedChan; %update options struct
        keepEMGChannels = selectedChan; %Numeric Ch Num
    end
end

% Identify DOSE channels
keepDoseChannels = [];
if ~isempty(LIMS.DoseChan)
        %explicitly save DoseChan
        if isnumeric(LIMS.DoseChan) && all(~isnan(LIMS.StudyDesign{curFile}.DoseChan))
            keepDoseChannels = LIMS.DoseChan;
            %keepChannels = [keepChannels, LIMS.StudyDesign{curFile}.DoseChan];
        elseif ischar(LIMS.DoseChan)
            selectedChan = find(strcmpi(ChannelNames, LIMS.DoseChan));
            if ~isempty(selectedChan)
                keepDoseChannels = selectedChan;
                %keepChannels = [keepChannels, selectedChan];
            else
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Selecting Channels >> Chan. not found: ',LIMS.StudyDesign{curFile}.DoseChan ]);
            end
        end
end

% Identify Data channels
keepChannels = [];
if isstruct(LIMS.StudyDesign{curFile}.AnalysisChan)
    for curChannel = 1:length(LIMS.StudyDesign{curFile}.AnalysisChan)
        if isnumeric(LIMS.StudyDesign{curFile}.AnalysisChan(curChannel).Name) && ~isnan(LIMS.StudyDesign{curFile}.AnalysisChan(curChannel).Name)
            %channel numbers may be different so check like names
            selectedChan = find(LIMS.StudyDesign{curFile}.AnalysisChan(curChannel).Name == ChannelNumbers);
            if ~isempty(selectedChan)
                keepChannels = [keepChannels, selectedChan];
                %test for Hz
            else
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Selecting Channels >> Chan. not found: ',LIMS.StudyDesign{curFile}.AnalysisChan(curChannel).Name ]);
            end
        elseif ischar(LIMS.StudyDesign{curFile}.AnalysisChan(curChannel).Name)
            selectedChan = find(strcmpi(ChannelNames, LIMS.StudyDesign{curFile}.AnalysisChan(curChannel).Name));
            if ~isempty(selectedChan)
                keepChannels = [keepChannels, selectedChan];
                %test for Hz
            else
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Selecting Channels >> Chan. not found: ',LIMS.StudyDesign{curFile}.AnalysisChan(curChannel).Name ]);
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: Selecting Channels >> Avail. Channels: ',ChannelNames{:} ]);
            end
        end
    end
elseif islogical(handles.StudyDesign{curFile}.AnalysisChan)
    keepChannels = 1:DataStruct.nChannels;
    LIMS.ValidDataChans = find([DataStruct.Channel(:).Hz] > 60);
end

%% Remove unwanted Channels
% this is to limit the amout of memory needed.
if isstruct(LIMS.StudyDesign{curFile}.AnalysisChan)
    % remove unused data Channels
    keepChannels = sort([keepChannels, keepEMGChannels, keepDoseChannels]);
    removeChannels = setdiff(1:length(DataStruct.Channel), keepChannels);   
    DataStruct.Channel(removeChannels) = [];
    DataStruct.nChannels = length(keepChannels);
    
    % now that you have deleted data channels, update EMG channel and Dose Channel IDX
    if ~isempty(keepEMGChannels) && isnumeric(LIMS.EMGChan)
        %recalculate EMD Chan IDX since it moved
        EMGchanOffset = sum(removeChannels < keepEMGChannels);
        LIMS.EMGChan = LIMS.EMGChan - EMGchanOffset;
    end
    if ~isempty(keepDoseChannels)  && isnumeric(LIMS.DoseChan)
        DoseChanOffset = sum(removeChannels < keepDoseChannels);
        LIMS.DoseChan = LIMS.DoseChan - DoseChanOffset;
    end   
end

%% Detrend if requested (not an option - by default)
status = updateProgress(LIMS);

if LIMS.PreClinicalFramework.Resample.Detrend
    status = NSB_UpdateStatusWindow(handles, '...Detrending Channels', 'NSB_Workflow_LIMS:');

    [DataStruct, status] = LIMS_DetrendData(handles, DataStruct);

    if status
        status = NSB_UpdateStatusWindow(handles, '...Detrending Channels Sucessful.', 'NSB_Workflow_LIMS:');
    else
        status = NSB_UpdateStatusWindow(handles, '...Detrending Channels Failed.', 'NSB_Workflow_LIMS:');
    end
end

%% Re-Reference if Requested
status = updateProgress(LIMS);

if LIMS.PreClinicalFramework.Reference.doReRef
    status = NSB_UpdateStatusWindow(handles, '...Re-Referencing Channels', 'NSB_Workflow_LIMS:');

    [DataStruct, status] = NSB_reReference(DataStruct,LIMS.RefChan, LIMS);

    if status
        status = NSB_UpdateStatusWindow(handles, '...Re-Referencing Channels Sucessful:', 'NSB_Workflow_LIMS:');
    else
        status = NSB_UpdateStatusWindow(handles, '...Re-Referencing Channels Failed:', 'NSB_Workflow_LIMS:');
    end
end

%% Resample if requested
status = updateProgress(LIMS);

if LIMS.PreClinicalFramework.Resample.doResample
    status = updatePreClinicalFrameworkStatus(handles, LIMS, ...
        ['...Resampling data to ',num2str(LIMS.PreClinicalFramework.Resample.newSampleRate),' Hz' ]);
    NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: resampling data to ',num2str(LIMS.PreClinicalFramework.Resample.newSampleRate),' Hz' ]);

    [DataStruct,status, msg] = NSB_Resample(DataStruct, LIMS.PreClinicalFramework.Resample);
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% This is the START of the main section for processing each Channel of DataStruct       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for curChannel = 1:length(DataStruct.Channel)
    status = updateProgress(LIMS);

    try
        % check/ignore channel 1st for Sample rate less than 60Hz = nyquist 30Hz
        if DataStruct.Channel(curChannel).Hz > 60
            status = updatePreClinicalFrameworkStatus(handles, LIMS, ['...Analyzing Ch#',num2str(curChannel),' ',DataStruct.Channel(curChannel).Name]);
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Analyzing Ch#',num2str(curChannel),' ',DataStruct.Channel(curChannel).Name,': ',datestr(now)]);
        else
            status = updatePreClinicalFrameworkStatus(handles, LIMS, ['...Analyzing Ch#',num2str(curChannel),' ',DataStruct.Channel(curChannel).Name]);
            status = updatePreClinicalFrameworkStatus(handles, LIMS, ['...Sample Rate < 60Hz. Skipping Channel.']);
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Analyzing Ch#',num2str(curChannel),' ',DataStruct.Channel(curChannel).Name,': ',datestr(now)]);
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Sample Rate < 60Hz. Skipping invalid data.']);
            continue;
        end

        %detect whether current channel is EMG channel
        isNotEMGChannel = true;
        if curChannel == LIMS.EMGChan %you need this in two steps because EMGchannel may be empty and as such returns empty not false
            isNotEMGChannel = false;
        end

        % %%%%%%%%%%%%%%%%%%%   Run User Spectral Setting GUI
        % Ignore EMG channels
        if handles.AnalysisStruct.useNewAnalysisParameters
            if isNotEMGChannel %Don't Process EMG Channel

                status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Generating User Spectral Settings');
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Generating User Spectral Settings: ',datestr(now)]);
                drawnow();

                %open DynamicParameterGUI for each Channel !!!!
                clear inputParms;
                inputParms.PreClinicalFramework = LIMS.PreClinicalFramework;
                inputParms.Filename = DataStruct.Filename;

                [LIMS.PreClinicalFramework.ArtifactDetection, LIMS.PreClinicalFramework.SpectralAnalysis] = ...
                    DynamicParameterGUI(DataStruct.Channel(curChannel),inputParms);
            end
        end

        % %%%%%%%%%%%%%%%%%%%   Run artifact detection
        %assign options
        %channel sample rate; generate artifact plot
        %Do not do this for EMG
        status = updateProgress(LIMS);

        if isNotEMGChannel %Don't Process EMG Channel
            if handles.AnalysisStruct.doSpectralAnalysis || ...
                    handles.AnalysisStruct.doSomnogram || ...
                    handles.AnalysisStruct.doTransferEntropy || ...
                    handles.AnalysisStruct.doActiveInfoStorage

                status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Detecting Artifacts');
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Detecting Artifacts: ',datestr(now)]);
                drawnow();

                %This is now updated to match the options struct and handle per file parmaters file.
                LIMS.PreClinicalFramework.ArtifactDetection.SampleRate = DataStruct.Channel(curChannel).Hz;
                LIMS.PreClinicalFramework.ArtifactDetection.logfile = LIMS.logfile;
                LIMS.PreClinicalFramework.ArtifactDetection.plotTitle = {DataStruct.Filename,[DataStruct.SubjectID, ' ',DataStruct.Channel(curChannel).Name]};

                [DataStruct.Channel(curChannel).Artifacts, AnalysisStatus] = NSB_ArtifactDetection(DataStruct.Channel(curChannel).Data,...
                    LIMS.PreClinicalFramework.ArtifactDetection);
            end
        else
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Not Detecting Artifacts on EMG Channel: ',datestr(now)]);
        end

        % %%%%%%%%%%%%%%%%%%%   Run Seizure Detection
        status = updateProgress(LIMS);

        if handles.AnalysisStruct.doSeizureAnalysis
            if isNotEMGChannel %Don't Process EMG Channel

                status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Running Seizure Analysis');
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Running Seizure Analysis: ',datestr(now)]);
                drawnow();

                clear inputParms;
                inputParms = LIMS.PreClinicalFramework.SeizureAnalysis;
                inputParms.SampleRate = DataStruct.Channel(curChannel).Hz;
                inputParms.logfile = LIMS.logfile;
                inputParms.Artifacts =LIMS.PreClinicalFramework.ArtifactDetection;
                inputParms.plotTitle = {DataStruct.Filename,[DataStruct.SubjectID, ' ',DataStruct.Channel(curChannel).Name]};

                %Currently This handles a single channel at a time _> returns additional struct within a channel
                %ToDo better error and reporting
                [DataStruct.Channel(curChannel).SeizureStruct, status] = NSB_SeizureDetection(DataStruct.Channel(curChannel).Data, inputParms);

                %CSV/Xls output here
                status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Saving Seizure Analysis');
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Saving Seizure Analysis: ',datestr(now)]);
                drawnow();
                %ToDo better error and reporting
                [AnalysisStatus, MetaData] = NSB_SaveSeizureData(DataStruct, handles, curFile, curChannel, DataStruct.Channel(curChannel).ChNumber);

                % % % % % %    Temp hack << AnalysisParameterEditor is not handling this correctly !!              %
                LIMS.PreClinicalFramework.SeizureAnalysis.doSeizureReport = false;
                % % % % % %
                if LIMS.PreClinicalFramework.SeizureAnalysis.doSeizureReport
                    clear inputParms;
                    inputParms.handles = handles;
                    inputParms.EEGChannel = curChannel;
                    inputParms.ActivityChannel = [];
                    %options.SeizureChannel = SeizureChannel;
                    inputParms.curFile = curFile;
                    inputParms.logfile = LIMS.logfile;
                    inputParms.TemplateFile = LIMS.PreClinicalFramework.SeizureAnalysis.SeizureReport_Template;
                    try
                        [status, filenames] = NSB_SaveSeizureReport(DataStruct, inputParms);
                    catch ME2
                        errorstr = ['ERROR: NSB_Workflow_LIMS >> Failed to save seizure report for Channel #',num2str(curChannel),' file: ',[LIMS.StudyDesign{curFile,1}.path, LIMS.StudyDesign{curFile,1}.name],' ',ME2.message];
                        NSBlog(LIMS.logfile,errorstr);
                        disp(errorstr);
                    end
                end
            end
        end


        % %%%%%%%%%%%%%%%%%%%   Run Spectral Analysis
        status = updateProgress(LIMS);

        if handles.AnalysisStruct.doSpectralAnalysis
            if isNotEMGChannel %Don't Process EMG Channel

                status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Running Spectral Analysis');
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Running Spectral Analysis: ',datestr(now)]);
                drawnow();

                clear inputParms;
                inputParms = LIMS.PreClinicalFramework.SpectralAnalysis;
                if strcmpi(LIMS.PreClinicalFramework.SpectralAnalysis.FFTWindowSizeMethod,'Auto')
                    inputParms.FFTWindowSize = [];
                else
                    inputParms.FFTWindowSize = LIMS.PreClinicalFramework.SpectralAnalysis.FFTWindowSize;
                end
                inputParms.nanMean = LIMS.PreClinicalFramework.SpectralAnalysis.nanMean;
                %these were the defaults prior to Version 1.27 (in the new wersion it is unclear how this will perform).
                %inputParms.FFTWindowSize = 10; %10 Seconds << 10x sample rate will always greate 0.1Hz div of Spectrum!
                %inputParms.FFTWindowSize = handles.parameters.PreClinicalFramework.ArtifactDetection.SampleRate * 10;%10 Seconds
                inputParms.Artifacts = DataStruct.Channel(curChannel).Artifacts;
                [DataStruct.Channel(curChannel).Spectrum,...
                    DataStruct.Channel(curChannel).SpectrumCI,...
                    DataStruct.Channel(curChannel).Spectrum_ts,...
                    DataStruct.Channel(curChannel).Spectrum_freqs,...
                    DataStruct.Channel(curChannel).Spectrum_validBins,...
                    AnalysisStatus] = NSB_SpectralAnalysis(DataStruct.Channel(curChannel).Data,...
                    LIMS.PreClinicalFramework.SpectralAnalysis.FinalTimeResolution,...
                    LIMS.PreClinicalFramework.SpectralAnalysis.FinalFreqResolution,...
                    LIMS.PreClinicalFramework.ArtifactDetection.SampleRate, inputParms);

                % CSV/Xls output here
                status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Saving Spectral Analysis');
                NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Saving Spectral Analysis: ',datestr(now)]);
                drawnow();

                [AnalysisStatus, MetaData] = NSB_SaveSpectralData(DataStruct, handles, curFile, curChannel, DataStruct.Channel(curChannel).ChNumber);
                % Add file location meta data to Study Design for analysis later
                MetaData.channel = curChannel;
                if ~isfield(MetaData,'type'),MetaData.type='';end
                if ~isfield(MetaData,'metadata'),MetaData.metadata='';end
                if ~isfield(MetaData,'filename'),MetaData.filename='';end

                if size(LIMS.StudyDesign,2) < 3
                    %first entry
                    LIMS.StudyDesign{curFile,3} = MetaData;
                elseif isempty(LIMS.StudyDesign{curFile,3})
                    %first entry for file
                    LIMS.StudyDesign{curFile,3} = MetaData;
                else
                    FileInfo = LIMS.StudyDesign{curFile,3};%get structure
                    if length(FileInfo)+1 == curChannel
                        FileInfo = [FileInfo, MetaData];
                    else
                        curFieldnames = fieldnames(MetaData);
                        for curField = 1:length(curFieldnames)
                            FileInfo(curChannel).(curFieldnames{curField}) = MetaData.(curFieldnames{curField});
                        end
                    end
                    LIMS.StudyDesign{curFile,3} = FileInfo;%return it
                end
            end
        end

        % %%%%%%%%%%%%%%%%%%%   Run Sleep scoring
        status = updateProgress(LIMS);

        if handles.AnalysisStruct.doSomnogram
            status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Running Sleep Scoring');
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Running Sleep Scoring: ',datestr(now)]);
            drawnow();

            % Need to ID EEG and EMG Channel
            %inputParms = handles.parameters.PreClinicalFramework; %used in line 852;
            doSleepScoring = true;
            if curChannel == LIMS.EMGChan %you need this in two steps because EMGchannel may be empty and as such returns empty not false
                doSleepScoring = false;
                status = false;
            end
            if doSleepScoring %Don't Score EMG Channel
                %will need to figure out how to deal with the rest
                %of the channels then... Maybe leverage file type
                %but for now do all channels

                %SleepScoring now returns a new channel
                LIMS.HypnogramChannel = length(DataStruct.Channel) +1;

                [SleepScore, status] = NSB_SleepScoring(DataStruct.Channel(curChannel), DataStruct.Channel(LIMS.EMGChan), [], LIMS.PreClinicalFramework);
                %Because these may have different structures, manually populate new struct.
                if status
                    SleepScoreFieldnames = fieldnames(SleepScore);
                    for curField = 1:length(SleepScoreFieldnames)
                        DataStruct.Channel(LIMS.HypnogramChannel).(SleepScoreFieldnames{curField}) = SleepScore.(SleepScoreFieldnames{curField});
                    end
                    clear SleepScore SleepScoreFieldnames curField;
                    DataStruct.nChannels = DataStruct.nChannels +1;
                end
            end
            %CSV/Xls output here
            status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Saving Sleep Scoring');
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Saving Somnogram Data: ',datestr(now)]);
            drawnow();

            MetaData = [];
            if status && doSleepScoring

                [AnalysisStatus, MetaData] = NSB_SaveSomnogramData(DataStruct, handles, curFile, LIMS.HypnogramChannel, DataStruct.Channel(curChannel).ChNumber);
            else
                %report error
                status = updatePreClinicalFrameworkStatus(handles, LIMS,'Warning: Could not generate hypnogram channel. Will not save Sleep Scoring');
                NSBlog(LIMS.logfile,['Warning: NSB_Workflow_LIMS >> Could not generate hypnogram channel. Will not save Sleep Scoring: ',datestr(now)]);
            end
            %Add file location meta data to Study Desighn for
            %analysis later
            MetaData.channel = curChannel;
            if ~isfield(MetaData,'type'),MetaData.type='';end
            if ~isfield(MetaData,'metadata'),MetaData.metadata='';end
            if ~isfield(MetaData,'filename'),MetaData.filename='';end

            if size(LIMS.StudyDesign,2) < 3 + handles.AnalysisStruct.doSpectralAnalysis
                %first entry
                LIMS.StudyDesign{curFile,end+1} = MetaData;
            elseif isempty(LIMS.StudyDesign{curFile,3+handles.AnalysisStruct.doSpectralAnalysis})
                %first entry for file
                LIMS.StudyDesign{curFile,3} = MetaData;
            else
                FileInfo = LIMS.StudyDesign{curFile,3};%get structure
                if length(FileInfo)+1 == curChannel
                    FileInfo = [FileInfo, MetaData];
                else
                    curFieldnames = fieldnames(MetaData);
                    for curField = 1:length(curFieldnames)
                        FileInfo(curChannel).(curFieldnames{curField}) = MetaData.(curFieldnames{curField});
                    end
                end
                LIMS.StudyDesign{curFile,3} = FileInfo;%return it
            end
            %Generate Sleep Report
            if LIMS.PreClinicalFramework.Scoring.doSomnogramReport && doSleepScoring
                % THese options calls are ugly and need a cleanup!
                %inputParms
                clear inputParms;
                inputParms.handles = handles;
                inputParms.EEGChannel = curChannel;
                inputParms.EMGChannel = LIMS.EMGChan;
                inputParms.ActivityChannel = [];
                inputParms.HypnogramChannel = LIMS.HypnogramChannel;
                inputParms.curFile = curFile;
                %LIMS.logfile = handles.parameters.PreClinicalFramework.LogFile;
                inputParms.TemplateFile = LIMS.PreClinicalFramework.Scoring.SomnogramReport_Template;
                try
                    [status, filenames] = NSB_SaveHypnogramReport(DataStruct, inputParms);
                catch ME2
                    errorstr = ['ERROR: NSB_Workflow_LIMS >> Failed to save sleep report for Channel #',num2str(curChannel),' file: ',[LIMS.StudyDesign{curFile,1}.path, LIMS.StudyDesign{curFile,1}.name],' ',ME2.message];
                    NSBlog(LIMS.logfile,errorstr);
                end
            end
        end
        %Channel error catch
    catch ME
        errorstr = ['ERROR: NSB_Workflow_LIMS >> Failed Processing Channel #',num2str(curChannel),' file: ',[LIMS.StudyDesign{curFile,1}.path, ' ',LIMS.StudyDesign{curFile,1}.name]];
        NSBlog(LIMS.logfile,errorstr);
        errorstr = ['ERROR: NSB_Workflow_LIMS >> ',ME.message];
        if ~isempty(ME.stack)
            errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
            NSBlog(LIMS.logfile,errorstr);
        end
        errordlg({['Failed Processing Channel #',num2str(curChannel),' file: ',[LIMS.StudyDesign{curFile,1}.path, ' ', LIMS.StudyDesign{curFile,1}.name]],...
            errorstr},'NSB_SpectralAnalysis');
    end

    % %%%%%%%%%%%%%%%%%%%   Run single channel AIC
    status = updateProgress(LIMS);

    if handles.AnalysisStruct.doActiveInfoStorage
        if isNotEMGChannel %Don't Process EMG Channel

            status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Running ActiveInfoStorage');
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Running Univariate ActiveInfoStorage Analysis: ',datestr(now)]);
            drawnow();

            clear inputParms;
            inputParms = LIMS.PreClinicalFramework.Connectivity;
            inputParms.logfile = LIMS.logfile;
            inputParms.FinalTimeBinSize = LIMS.PreClinicalFramework.SpectralAnalysis.FinalTimeResolution;
            inputParms.FinalFreqRes = LIMS.PreClinicalFramework.SpectralAnalysis.FinalFreqResolution;
            inputParms.fs = LIMS.PreClinicalFramework.ArtifactDetection.SampleRate;
            %Set Analysis for Univariate ActiveInformationCalculator
            inputParms.JIDT.UnivariateAnalysis = true;
            inputParms.JIDT.AnalysisChannels = curChannel;
            inputParms.JIDT.calculator = 'ActiveInformationCalculator';
            inputParms.JIDT.calcType = 'ksg';
            inputParms.JIDT.k_history = 'auto';
            inputParms.JIDT.numSurrogates = 100; %100 is the minimum

            [status, DataStruct] = NSB_ConnectivityAnalysis(DataStruct, inputParms); %%bins = Bins (8574), AIS (8567); diff = 7.
            %CSV/Xls output here
            status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Saving ActiveInfoStorage Analysis');
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Saving ActiveInformation Analysis: ',datestr(now)]);
            drawnow();

            [AnalysisStatus, MetaData] = NSB_SaveActiveInformationData(DataStruct, handles, curFile, curChannel, DataStruct.Channel(curChannel).ChNumber);
            %Add file location meta data to Study Design for
            %analysis later
            MetaData.channel = curChannel;
            if ~isfield(MetaData,'type'),MetaData.type='';end
            if ~isfield(MetaData,'metadata'),MetaData.metadata='';end
            if ~isfield(MetaData,'filename'),MetaData.filename='';end

            if size(LIMS.StudyDesign,2) < 3
                %first entry
                LIMS.StudyDesign{curFile,3} = MetaData;
            elseif isempty(LIMS.StudyDesign{curFile,3})
                %first entry for file
                LIMS.StudyDesign{curFile,3} = MetaData;
            else
                FileInfo = LIMS.StudyDesign{curFile,3};%get structure
                if length(FileInfo)+1 == curChannel
                    FileInfo = [FileInfo, MetaData];
                else
                    curFieldnames = fieldnames(MetaData);
                    for curField = 1:length(curFieldnames)
                        FileInfo(curChannel).(curFieldnames{curField}) = MetaData.(curFieldnames{curField});
                    end
                end
                LIMS.StudyDesign{curFile,3} = FileInfo;%return it
            end
        end
    end

end %for curChannel loop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the END of the main section for processing each Channel of DataStruct       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Quantify multichannel connectivity measures
% JIDT Transfer Entropy
if handles.AnalysisStruct.doTransferEntropy
    status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Running TransferEntropy');
    NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Running TransferEntropy Analysis: ',datestr(now)]);
    drawnow();

    clear inputParms;
    inputParms = LIMS.PreClinicalFramework.Connectivity;
    inputParms.logfile = LIMS.logfile;
    inputParms.FinalTimeBinSize = LIMS.PreClinicalFramework.SpectralAnalysis.FinalTimeResolution;
    inputParms.FinalFreqRes = LIMS.PreClinicalFramework.SpectralAnalysis.FinalFreqResolution;
    inputParms.fs = LIMS.PreClinicalFramework.ArtifactDetection.SampleRate;
    %Set Analysis for Univariate ActiveInformationCalculator
    inputParms.JIDT.UnivariateAnalysis = false;
    inputParms.JIDT.AnalysisChannels = LIMS.ValidDataChans;
    inputParms.JIDT.calculator = 'TransferEntropyCalculator';
    %inputParms.JIDT.calculator = 'TransferEntropyCalculatorMultiVariateKraskov';
    inputParms.JIDT.calcType = 'ksg';
    inputParms.JIDT.k_history = 'auto';
    inputParms.JIDT.numSurrogates = 100;

    [status, DataStruct] = NSB_ConnectivityAnalysis(DataStruct, inputParms);
    %CSV/Xls output here
    status = updatePreClinicalFrameworkStatus(handles, LIMS,'...Saving TransferEntropy Analysis');
    NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Saving TransferEntropy Analysis: ',datestr(now)]);
    drawnow();

    [AnalysisStatus, MetaData] = NSB_SaveTransferEntropyData(DataStruct, handles, curFile, LIMS.ValidDataChans);
    %Add file location meta data to Study Design for
    %analysis later
    MetaData.channel = curChannel;
    if ~isfield(MetaData,'type'),MetaData.type='';end
    if ~isfield(MetaData,'metadata'),MetaData.metadata='';end
    if ~isfield(MetaData,'filename'),MetaData.filename='';end

    if size(LIMS.StudyDesign,2) < 3
        %first entry
        LIMS.StudyDesign{curFile,3} = MetaData;
    elseif isempty(LIMS.StudyDesign{curFile,3})
        %first entry for file
        LIMS.StudyDesign{curFile,3} = MetaData;
    else
        FileInfo = LIMS.StudyDesign{curFile,3};%get structure
        if length(FileInfo)+1 == curChannel
            FileInfo = [FileInfo, MetaData];
        else
            curFieldnames = fieldnames(MetaData);
            for curField = 1:length(curFieldnames)
                FileInfo(curChannel).(curFieldnames{curField}) = MetaData.(curFieldnames{curField});
            end
        end
        LIMS.StudyDesign{curFile,3} = FileInfo;%return it
    end
end



        %% Save as EDF if Requested (this will be moved after sleep scoring so that sleep stages can be saved to EDF)
        if handles.AnalysisStruct.doWriteEDF
            try
            txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = LIMS.PreClinicalFramework.StatusLines -3;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    
                    %if ~strcmpi(LIMS.StudyDesign{curFile}.type,'.edf') %<< you
                    %will want to write sleep scoring.
                    rows = rows+1;
                    txt{rows,1} = '...Writing EDF';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Writing EDF: ',datestr(now)]);
                    drawnow();
                    %\/\/ LIMS.StudyDesign{curFile}.path{1} shuuld be a string <may be diff if dir load \/\/\/
                    status = NSB_EDFplusWriter(DataStruct, fullfile(char(LIMS.StudyDesign{curFile}.path), 'NSB_Output', [LIMS.StudyDesign{curFile}.name,'.edf']),options);
                    if status
                        rows = rows+1;
                        txt{rows,1} = '...Write Sucessful';
                        set(handles.status_stxt,'String',txt);
                        NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Write EDF Sucessful: ',datestr(now)]);
                        drawnow();
                    else
                        rows = rows+1;
                        txt{rows,1} = '...Write Failed';
                        set(handles.status_stxt,'String',txt);
                        NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Write EDF Failed: ',datestr(now)]);
                        drawnow();
                    end
%                     else
%                     rows = rows+1;
%                     txt{rows,1} = '...Skipping EDF->EDF';
%                     set(handles.status_stxt,'String',txt);
%                     NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Skipping EDF->EDF: ',datestr(now)]);
%                     drawnow();
%                     end
        %EDF error catch
            catch ME
                errorstr = ['ERROR: NSB_Workflow_LIMS >> Failed Writing: ',fullfile(char(LIMS.StudyDesign{curFile}.path), 'NSB_Output', [LIMS.StudyDesign{curFile}.name,'.edf']),' ',ME.message];
                NSBlog(LIMS.logfile,errorstr);
                errordlg(errorstr,'EDF+ Writer');
                if ~isempty(ME.stack)
                    errorstr = ['ERROR: NSB_Workflow_LIMS >> ',ME.message];
                    errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
                NSBlog(LIMS.logfile,errorstr);
                end
                
                txt = get(handles.status_stxt,'String');
                if iscell(txt)
                    StatusLines = LIMS.PreClinicalFramework.StatusLines -2;
                    if length(txt) > StatusLines
                        txt = txt(end-(StatusLines-1):end);
                    end
                    rows = length(txt);
                else
                    txt = {txt}; %create cell array
                    rows = 1;
                end
                rows = rows+1;
                txt{rows,1} = errorstr;
                set(handles.status_stxt,'String',txt);
                
            end
        end     
    end   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% This is the END of the main section for processing each Data FILE of StudyDesign       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try, delete(LIMS.hWaitbar); end

txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = LIMS.PreClinicalFramework.StatusLines -5;
    if StatusLines < 1, StatusLines = 1; end;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array
    rows = 1;
end

if isempty(LIMS.StudyDesign)
    rows = rows+1;
    txt{rows,1} = 'No Data Selected to Run';
end
rows = rows+1;
txt{rows,1} = 'Finished Analysis';
set(handles.status_stxt,'String',txt);
NSBlog(LIMS.logfile,['>> NSB_Workflow_LIMS: Finished Signal Processing: ',datestr(now)]);

%% Cleanup
clear DataStruct;
clear inputParms;
clear FileInfo;

%% Stats Table
if handles.AnalysisStruct.doStatsTable
    %now that analysis is complete, aggrigate results in table
    txt = get(handles.status_stxt,'String');
    if iscell(txt)
        StatusLines = LIMS.PreClinicalFramework.StatusLines -2;
        if length(txt) > StatusLines
            txt = txt(end-(StatusLines-1):end);
        end
        rows = length(txt);
    else
        txt = {txt}; %create cell array
        rows = 1;
    end
    rows = rows+1;
    txt{rows,1} = 'Generating Statistical Table';
    set(handles.status_stxt,'String',txt);
    NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Generating Statistical Table: ',datestr(now)]);
    drawnow();
    if ~isempty(handles.AnalysisStruct.StudyDesignFilePath)
        inputParms.logfile = LIMS.logfile;
        inputParms.progress = handles.parameters.PreClinicalFramework.useWaitBar;
        inputParms.doMeanBaseline = handles.parameters.PreClinicalFramework.StatsTable.doMeanBaseline;
        
        status = NSB_GenerateStatTable(handles.AnalysisStruct.StudyDesignFilePath,...
            handles.parameters.PreClinicalFramework.StatsTable.BaselineMeanTimeStart,...
            handles.parameters.PreClinicalFramework.StatsTable.BaselineMeanTimeEnd,inputParms);
        
        if status
            rows = rows+1;
            txt{rows,1} = '...Statistical Table Generation Sucessful';
            set(handles.status_stxt,'String',txt);
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Write Statistical Table Sucessful: ',datestr(now)]);
            drawnow();
        else
            rows = rows+1;
            txt{rows,1} = '...Statistical Table Generation Failed';
            set(handles.status_stxt,'String',txt);
            NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Write Statistical Table Failed: ',datestr(now)]);
            drawnow();
        end
    else
        rows = rows+1;
        txt{rows,1} = 'No Study Design File to Analyze. Not Generating Stats Table.';
        set(handles.status_stxt,'String',txt);
        NSBlog(LIMS.logfile,['NSB_Workflow_LIMS: ...Statistical Table Failed. No Study Design File: ',datestr(now)]);
    end
end

try, delete(LIMS.hWaitbar); end
status = true;
end

function [status, AbortProcessing] = updateProgress(LIMS,pct,str)
status = false;
AbortProcessing = false;
if LIMS.progress
    if getappdata(LIMS.hWaitbar,'Canceling')
        AbortProcessing = true;
    end
    if nargin > 1
        waitbar( pct ,LIMS.hWaitbar, str); %WaitBAr uses tex interpreter
    end
end
end

function status = updatePreClinicalFrameworkStatus(handles, LIMS, msg)
    status = false;
    txt = get(handles.status_stxt,'String');
    if iscell(txt)
        StatusLines = LIMS.PreClinicalFramework.StatusLines -3;
        if length(txt) > StatusLines
            txt = txt(end-(StatusLines-1):end);
        end
        rows = length(txt);
    else
        txt = {txt}; %create cell array
        rows = 1;
    end
    rows = rows+1;
    txt{rows,1} = msg;
    set(handles.status_stxt,'String',txt);
    status = true;
end