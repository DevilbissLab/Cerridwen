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

%Also see MATLAB Memory Shielding
%StudyDesign{1,1}.path sometime is cell when loading DSI DATA from Dir. 

status = false;
msg = '';
AbortFileLoad = false;
NSBlog(handles.parameters.PreClinicalFramework.LogFile,'NSB_Workflow_LIMS: Begin');
%Here setup Log files and Licencing
options.logfile = handles.parameters.PreClinicalFramework.LogFile;
handles.parameters.PreClinicalFramework.SpectralAnalysis.logfile = handles.parameters.PreClinicalFramework.LogFile;
if handles.parameters.PreClinicalFramework.useWaitBar
    options.progress = true;
else
    options.progress = false;
end
options.Licensing = handles.licensing;
options.showHeadPlot = handles.parameters.PreClinicalFramework.File.FIF.showHeadPlot;
options.assumeTemplateChOrderCorrect = handles.parameters.PreClinicalFramework.File.FIF.assumeTemplateChOrderCorrect;
options.ChanLocFiles_Dir = handles.parameters.PreClinicalFramework.File.FIF.ChanLocFiles_Dir;
options.DSIoffset = handles.parameters.PreClinicalFramework.File.DSIoffset;

if ~isempty(handles.StudyDesign)
    StudyDesign = handles.StudyDesign; %This is a duplicate because we never want it changed except by this fcn
    if options.progress
        %hWaitbar = waitbar(0,'Processing File List ...','Name','Processing Files...',...
        %    'CreateCancelBtn','setappdata(gcbf,''Canceling'',1)');
        hWaitbar = waitbar(0,'Processing File List ...','Name','Processing Files...',...
            'CreateCancelBtn',@NSB_ProgressCloseReq);
        setappdata(hWaitbar,'Canceling',0);
        if handles.parameters.PreClinicalFramework.MatlabPost2014
            hWaitbar.Children(2).Title.Interpreter = 'none';
        else
            hWaitBarChild = get(hWaitbar,'Children');
            hWaitBarTitle = get(hWaitBarChild(1),'Title');
            set(hWaitBarTitle,'Interpreter','none')
        end
    end
    
%% Parse file specific data from Study design
%parallize here -> undocumented -> feature('numcores')
    for curFile = 1:size(StudyDesign,1)
        %determine whether to run specific channels
        if islogical(StudyDesign{curFile,1}.AnalysisChan) %no channels specified in (false)
            if strcmpi(StudyDesign{curFile,1}.type, '.fif')
                options.chans = handles.parameters.PreClinicalFramework.File.FIFtype;
            else
                options.chans = [];
            end
        else
            %this is a struct let it be because we will process each cahnnel seperately later
            %contains .Name and .ParamsFile
            try
                options.chans = StudyDesign{curFile, 1}.AnalysisChan;
            catch
                options.chans = StudyDesign{1, 1}.AnalysisChan;
                msg = ['Warning: NSB_Workflow_LIMS >> Channels not specified in row ',num2str(curFile +1),'. Using channels from first row.'];
                NSBlog(handles.parameters.PreClinicalFramework.LogFile,msg);
            end
        end
        %determine whether there is a dose channel (not sure how to
        %processes yet) <<optional???
        if isfield(StudyDesign{curFile,1},'DoseChan')
            if all(isnan(StudyDesign{curFile,1}.DoseChan)) || isempty(StudyDesign{curFile,1}.DoseChan) %all() because this fould also be a string
                options.DoseChan = '';
            else
                options.DoseChan = StudyDesign{curFile,1}.DoseChan;
            end
        else
            options.DoseChan = '';
        end
        % EMG Channel
        if ~isempty(StudyDesign{curFile,1}.EMGchan)
            options.EMGChan = StudyDesign{curFile,1}.EMGchan;
        else
            options.EMGChan = '';
        end
        % Reference Chan
        if ~isempty(StudyDesign{curFile,1}.RefChannel)
            options.RefChan = StudyDesign{curFile,1}.RefChannel;
            handles.parameters.PreClinicalFramework.Reference.doReRef = true;
        else
            options.RefChan = '';
            handles.parameters.PreClinicalFramework.Reference.doReRef = false;
        end
        %Position Template
        if ~isempty(StudyDesign{curFile,1}.PositionTemplate)
            options.PositionTemplate = StudyDesign{curFile,1}.PositionTemplate;
        else
            options.PositionTemplate = '';
        end
        %Subject ID to analyze <<make sure it is a str
        % This can also be a str ('File')
        if isfield(StudyDesign{curFile,2},'animalID')
            if ~isempty(StudyDesign{curFile,2}.animalID)
                if isnumeric(StudyDesign{curFile,2}.animalID)
                    StudyDesign{curFile,2}.animalID = num2str(StudyDesign{curFile,2}.animalID);
                end
                options.subjectID = StudyDesign{curFile,2}.animalID;
            else
                options.subjectID = '';
            end
        else
            options.subjectID = '';
        end
        %Store date to compare with file stored date.
        if isfield(StudyDesign{curFile,2},'date')
            if ~isempty(StudyDesign{curFile,2}.date)
                options.RecordingDate = datenum(StudyDesign{curFile,2}.date);
            else
                options.RecordingDate = [];
            end
        else
            options.RecordingDate = [];
        end
        % Per File - Parameter File
                % options.chans
                % update ONLY Reref, resample, artifact detection, seizure, and sleep detection
        
        
        
        %not implemented yet
        %this will rewrite each struct
        
        
%% Load in files
        if options.progress
            if getappdata(hWaitbar,'Canceling')
                AbortFileLoad = true;
                break;
            end
            waitbar(curFile/size(StudyDesign,1),hWaitbar,['Subject: ',StudyDesign{curFile,1}.name]); %WaitBAr uses tex interpreter
        end
        
        try
            if ischar(StudyDesign{curFile,1}.path)
                logstr = ['NSB_Workflow_LIMS: Opening - ',StudyDesign{curFile,1}.path,' : '];
            else
                logstr = ['NSB_Workflow_LIMS: Opening - ',StudyDesign{curFile,1}.path{1},' : '];
            end
            if ischar(StudyDesign{curFile,1}.name)
                 logstr = [logstr,StudyDesign{curFile,1}.name];
            else
                logstr = [logstr,StudyDesign{curFile,1}.name{1}];
            end   
            disp(logstr);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,logstr);
            ReadTic = tic;
            %Load Files (Import)
            [readstatus, DataStruct] = NSB_DataImportModule(StudyDesign{curFile,1},options);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Read Time = ',num2str(toc(ReadTic)), ' (sec)']);
            try
            %NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: File Start Time = ',datestr(DataStruct.Channel(1).ts(1))]);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: File Start Time = ',datestr(DataStruct.StartDate)]);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: File End Time = ',datestr(DataStruct.Channel(1).ts(end))]);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Timestamp Offset (To Be Applied) = ',...
                num2str(handles.parameters.PreClinicalFramework.File.DSIoffset),' hours']);
            catch
                 NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: No Timestamp/DSI Offset found in file']);
            end
            
            %just clear the pannel
            txt = cell(0); %create cell array
            rows = 0;
%             txt = get(handles.status_stxt,'String');
%             if iscell(txt)
%                 StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
%                 if length(txt) > StatusLines
%                     txt = txt(end-(StatusLines-1):end);
%                 end
%                 rows = length(txt);
%             else
%                 txt = {txt}; %create cell array
%                 rows = 1;
%             end
            if readstatus
                rows = rows+1;
                txt{rows,1} = 'Loaded File...';
                rows = rows+1;
                txt{rows,1} = char(StudyDesign{curFile,1}.name);
                %txt{rows,1} = char([StudyDesign{curFile,1}.path, StudyDesign{curFile,1}.name]);
                set(handles.status_stxt,'String',txt);
                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Read OK - ',[StudyDesign{curFile,1}.path, ' : ', StudyDesign{curFile,1}.name]]);
            else
                 rows = rows+1;
                 txt{rows,1} = 'Read Failed...';
                 rows = rows+1;
                 txt{rows,1} = char(StudyDesign{curFile,1}.name);
                 set(handles.status_stxt,'String',txt);
                 msg = ['NSB_Workflow_LIMS: Read FAILED - ',[StudyDesign{curFile,1}.path, ' : ', StudyDesign{curFile,1}.name]];
                 NSBlog(handles.parameters.PreClinicalFramework.LogFile,msg);
                 disp(msg);
                continue;
            end
        catch ME
            msg = ME.message;
            return;
        end
        
        if AbortFileLoad
            msg = 'File Import Aborted.';
            txt = get(handles.status_stxt,'String');
            if iscell(txt)
                StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
                if length(txt) > StatusLines
                    txt = txt(end-(StatusLines-1):end);
                end
                rows = length(txt);
            else
                txt = {txt}; %create cell array
                rows = 1;
            end
            rows = rows+1;
            txt{rows,1} = txt;
            set(handles.status_stxt,'String',txt);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Read ABORTED - ',msg]);
            return;
        end
        
%% Re-Reference if Requested
if options.progress
    if getappdata(hWaitbar,'Canceling')
        AbortFileLoad = true;
        break;
    end
end
if handles.parameters.PreClinicalFramework.Reference.doReRef
                txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    
                    rows = rows+1;
                    txt{rows,1} = '...Re-Referencing';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Re-referencing Channels: ',datestr(now)]);
                    drawnow();
    
                    [DataStruct, status] = NSB_reReference(DataStruct,options.RefChan,options);
                    
                    if status
                        rows = rows+1;
                        txt{rows,1} = '...Re-Referencing Sucessful';
                        set(handles.status_stxt,'String',txt);
                        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Re-referencing Channels Sucessful: ',datestr(now)]);
                        drawnow();
                    else
                        rows = rows+1;
                        txt{rows,1} = '...Re-Referencing Failed';
                        set(handles.status_stxt,'String',txt);
                        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Re-referencing Channels Failed: ',datestr(now)]);
                        drawnow();
                    end
                    
end

%% Remove unwanted Channels
if options.progress
    if getappdata(hWaitbar,'Canceling')
        AbortFileLoad = true;
        break;
    end
end
if isstruct(StudyDesign{curFile}.AnalysisChan)
    %only use selected channels
    keepChannels = [];
    keepEMGChannels = [];
    keepDoseChannels = [];
    ChannelNames = {DataStruct.Channel(:).Name};
    ChannelNumbers = [DataStruct.Channel(:).ChNumber];
    if ~isempty(options.EMGChan)
        %explicitly save EMG
        if isnumeric(options.EMGChan) && all(~isnan(StudyDesign{curFile}.EMGchan))
            keepEMGChannels = options.EMGChan;
            %keepChannels = [keepChannels, StudyDesign{curFile}.EMGchan];
        elseif ischar(options.EMGChan)
            selectedChan = find(strcmpi(ChannelNames, options.EMGChan));
            if ~isempty(selectedChan)
                keepEMGChannels = selectedChan;
                %keepChannels = [keepChannels, selectedChan];
            else
                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Selecting Channels >> Chan. not found: ',StudyDesign{curFile}.EMGchan ]);
            end
        end
    else %is empty
        keepEMGChannels = find(strcmpi(ChannelNames, 'EMG'));
        %keepChannels = [keepChannels, find(strcmpi(ChannelNames, 'EMG'))];
    end
    
    if ~isempty(options.DoseChan)
        %explicitly save DoseChan
        if isnumeric(options.DoseChan) && all(~isnan(StudyDesign{curFile}.DoseChan))
            keepDoseChannels = options.DoseChan;
            %keepChannels = [keepChannels, StudyDesign{curFile}.DoseChan];
        elseif ischar(options.DoseChan)
            selectedChan = find(strcmpi(ChannelNames, options.DoseChan));
            if ~isempty(selectedChan)
                keepDoseChannels = selectedChan;
                %keepChannels = [keepChannels, selectedChan];
            else
                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Selecting Channels >> Chan. not found: ',StudyDesign{curFile}.DoseChan ]);
            end
        end
    end
    
    %find requested channels
    for curChannel = 1:length(StudyDesign{curFile}.AnalysisChan)
        if isnumeric(StudyDesign{curFile}.AnalysisChan(curChannel).Name) && ~isnan(StudyDesign{curFile}.AnalysisChan(curChannel).Name)
            %channel numbers may be different so check like names
            selectedChan = find(StudyDesign{curFile}.AnalysisChan(curChannel).Name == ChannelNumbers);
            if ~isempty(selectedChan)
                keepChannels = [keepChannels, selectedChan];
            else
                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Selecting Channels >> Chan. not found: ',StudyDesign{curFile}.AnalysisChan(curChannel).Name ]);
            end
        elseif ischar(StudyDesign{curFile}.AnalysisChan(curChannel).Name)
            selectedChan = find(strcmpi(ChannelNames, StudyDesign{curFile}.AnalysisChan(curChannel).Name));
            if ~isempty(selectedChan)
                keepChannels = [keepChannels, selectedChan];
            else
                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Selecting Channels >> Chan. not found: ',StudyDesign{curFile}.AnalysisChan(curChannel).Name ]);
                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: Selecting Channels >> Avail. Channels: ',ChannelNames{:} ]);
            end
        end
    end
    %now remove Channels
    keepChannels = sort([keepChannels, keepEMGChannels, keepDoseChannels]);
    removeChannels = setdiff(1:length(DataStruct.Channel), keepChannels);   
    DataStruct.Channel(removeChannels) = [];
    DataStruct.nChannels = length(keepChannels);
    
    % now that you have deleted data channels, update EMG channel and Dose
    % Channel IDX
    if ~isempty(keepEMGChannels) && isnumeric(options.EMGChan)
        %recalculate EMD Chan IDX since it moved
        EMGchanOffset = sum(removeChannels < keepEMGChannels);
        options.EMGChan = options.EMGChan - EMGchanOffset;
    end
    if ~isempty(keepDoseChannels)  && isnumeric(options.DoseChan)
        DoseChanOffset = sum(removeChannels < keepDoseChannels);
        options.DoseChan = options.DoseChan - DoseChanOffset;
    end

    
end

%% Resample if requested
if options.progress
    if getappdata(hWaitbar,'Canceling')
        AbortFileLoad = true;
        break;
    end
end
if handles.parameters.PreClinicalFramework.Resample.doResample
    txt = get(handles.status_stxt,'String');
    if iscell(txt)
        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
        if length(txt) > StatusLines
            txt = txt(end-(StatusLines-1):end);
        end
        rows = length(txt);
    else
        txt = {txt}; %create cell array
        rows = 1;
    end
    rows = rows+1;
    txt{rows,1} = ['...Resampling data to ',num2str(handles.parameters.PreClinicalFramework.Resample.newSampleRate),' Hz' ];
    set(handles.status_stxt,'String',txt);
    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: resampling data to ',num2str(handles.parameters.PreClinicalFramework.Resample.newSampleRate),' Hz' ]);
    [DataStruct,status, msg] = NSB_Resample(DataStruct, handles.parameters.PreClinicalFramework.Resample);
end

%% This is the main section for processing
 %Process each Channel of DataStruct
        for curChannel = 1:length(DataStruct.Channel)
            if options.progress
                if getappdata(hWaitbar,'Canceling')
                    AbortFileLoad = true;
                    break;
                end
            end
           
            try
                txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    
                    % check/ignore channel 1st for Sample rate less than 60Hz = nyquist 30Hz
                    if DataStruct.Channel(curChannel).Hz > 60
                    rows = rows+1;
                    txt{rows,1} = ['...Analyzing Ch#',num2str(curChannel),' ',DataStruct.Channel(curChannel).Name];
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Analyzing Ch#',num2str(curChannel),' ',DataStruct.Channel(curChannel).Name,': ',datestr(now)]);
                    else
                    rows = rows+1;
                    txt{rows,1} = ['...Analyzing Ch#',num2str(curChannel),' ',DataStruct.Channel(curChannel).Name];
                    rows = rows+1;
                    txt{rows,1} = ['...Sample Rate < 60Hz. Skipping Channel.'];
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Analyzing Ch#',num2str(curChannel),' ',DataStruct.Channel(curChannel).Name,': ',datestr(now)]);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Sample Rate < 60Hz. Skipping invalid data.']);
                    continue;
                    end
                    
                    
                    %detect whether current channel is EMG channel
                    EMGchannel = '';
                    if ~isempty(options.EMGChan)
                        if isnumeric(options.EMGChan) %used chan number instead of name
                            EMGchannel = options.EMGChan;
                        else %string
                            EMGchannel = find(strcmpi(options.EMGChan,{DataStruct.Channel(:).Name})); %theoreticall only one chan but...
                            if length(EMGchannel) > 1
                                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Warning: NSB_Workflow_LIMS >> Found Multiple EMG Channels #',num2str(EMGchannel),' ',DataStruct.Channel(curChannel).Name,': ',datestr(now)]);
                                EMGchannel = '';
                            end
                        end
                    else
                        % huristically try to find EMG channel
                        %EMGchannel = find(strcmpi('EMG',{DataStruct.Channel(:).Name})); %theoretically only one chan but may not be...
                        EMGchannel = find(~cellfun(@isempty,strfind({DataStruct.Channel(:).Name},'EMG')));
                        if length(EMGchannel) ~= 1
                              NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Warning: NSB_Workflow_LIMS >> Found Multiple EMG Channels #',num2str(EMGchannel),' ',DataStruct.Channel(curChannel).Name,': ',datestr(now)]);
                              EMGchannel = '';         
                        else
                            options.EMGChan = EMGchannel; %update options struct
                        end
                    end
                    if ~isempty(EMGchannel)
                        rows = rows+1;
                        txt{rows,1} = ['...EMG Channel detected.'];
                        set(handles.status_stxt,'String',txt);
                        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS >> Found EMG Channel #',num2str(EMGchannel),' ',DataStruct.Channel(curChannel).Name,': ',datestr(now)]);
                    end
                    isNotEMGChannel = true;
                    if curChannel == EMGchannel %you need this in two steps because EMGchannel may be empty and as such returns empty not false
                        isNotEMGChannel = false;
                    end
                              
% Run Calculate User Spectral Setting GUI
% Do not do this for EMG
                if handles.AnalysisStruct.useNewAnalysisParameters  
                    if isNotEMGChannel %Don't Process EMG Channel
                     
                    txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    rows = rows+1;
                    txt{rows,1} = '...Generating User Spectral Settings';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Generating User Spectral Settings: ',datestr(now)]);
                    drawnow();
                    
                    %open DynamicParameterGUI for each Channel !!!!
                    clear inputParms;
                    %inputParms.ArtifactDetection = handles.parameters.PreClinicalFramework.ArtifactDetection;
                    %inputParms.SpectralAnalysis = handles.parameters.PreClinicalFramework.SpectralAnalysis;
                    %inputParms.Channel = DataStruct.Channel(curChannel);
                    %inputParms.Filename = DataStruct.Filename;
                    inputParms.PreClinicalFramework = handles.parameters.PreClinicalFramework;
                    inputParms.Filename = DataStruct.Filename;
                    
                    [handles.parameters.PreClinicalFramework.ArtifactDetection, handles.parameters.PreClinicalFramework.SpectralAnalysis] = ...
                        DynamicParameterGUI(DataStruct.Channel(curChannel),inputParms);
                    %[handles.parameters.PreClinicalFramework.ArtifactDetection, handles.parameters.PreClinicalFramework.SpectralAnalysis] = ...
                    %    DynamicParameterGUI(inputParms,handles.parameters.PreClinicalFramework.LogFile);
                    end
                end
                
% %%%%%%%%%%%%%%%%%%%   Run artifact detection
%assign options
%channel sample rate; generate artifact plot
%Do not do this for EMG
if options.progress
    if getappdata(hWaitbar,'Canceling')
        AbortFileLoad = true;
        break;
    end
end
                if isNotEMGChannel %Don't Process EMG Channel
                    if handles.AnalysisStruct.doSpectralAnalysis || handles.AnalysisStruct.doSomnogram

                        txt = get(handles.status_stxt,'String');
                        if iscell(txt)
                            StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                            if length(txt) > StatusLines
                                txt = txt(end-(StatusLines-1):end);
                            end
                            rows = length(txt);
                        else
                            txt = {txt}; %create cell array
                            rows = 1;
                        end
                        rows = rows+1;
                        txt{rows,1} = '...Detecting Artifacts';
                        set(handles.status_stxt,'String',txt);
                        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Detecting Artifacts: ',datestr(now)]);
                        drawnow();

                        handles.parameters.PreClinicalFramework.ArtifactDetection.SampleRate = DataStruct.Channel(curChannel).Hz;
                        %we dont need this next line any more since it now caried
                        %through in this struct
                        %handles.parameters.PreClinicalFramework.ArtifactDetection.plot=handles.AnalysisStruct.doArtifactPlot;
                        handles.parameters.PreClinicalFramework.ArtifactDetection.logfile = handles.parameters.PreClinicalFramework.LogFile;
                        handles.parameters.PreClinicalFramework.ArtifactDetection.plotTitle = {DataStruct.Filename,[DataStruct.SubjectID, ' ',DataStruct.Channel(curChannel).Name]};

                        [DataStruct.Channel(curChannel).Artifacts, AnalysisStatus] = NSB_ArtifactDetection(DataStruct.Channel(curChannel).Data,...
                            handles.parameters.PreClinicalFramework.ArtifactDetection);
                    end
                else
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Not Detecting Artifacts on EMG Channel: ',datestr(now)]);
                end
                
% %%%%%%%%%%%%%%%%%%%   Run Seizure Detection
if options.progress
    if getappdata(hWaitbar,'Canceling')
        AbortFileLoad = true;
        break;
    end
end
                if handles.AnalysisStruct.doSeizureAnalysis
                    if isNotEMGChannel %Don't Process EMG Channel

                    txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    rows = rows+1;
                    txt{rows,1} = '...Running Seizure Analysis';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Running Seizure Analysis: ',datestr(now)]);
                    drawnow();
                    
                    clear inputParms;
                    inputParms = handles.parameters.PreClinicalFramework.SeizureAnalysis;
                    inputParms.SampleRate = DataStruct.Channel(curChannel).Hz;
                    inputParms.logfile = handles.parameters.PreClinicalFramework.LogFile;
                    %inputParms.Artifacts = DataStruct.Channel(curChannel).Artifacts;
                    inputParms.Artifacts =handles.parameters.PreClinicalFramework.ArtifactDetection;
                    inputParms.plotTitle = {DataStruct.Filename,[DataStruct.SubjectID, ' ',DataStruct.Channel(curChannel).Name]};
                    
                    %Currently This handles a single channel at a time _> returns additional struct within a channel
                    %ToDo better error and reporting   
                    [DataStruct.Channel(curChannel).SeizureStruct, status] = NSB_SeizureDetection(DataStruct.Channel(curChannel).Data, inputParms);
                    
%CSV/Xls output here
                    txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    rows = rows+1;
                    txt{rows,1} = '...Saving Seizure Analysis';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Saving Seizure Analysis: ',datestr(now)]);
                    drawnow();
          %ToDo better error and reporting          
                    [AnalysisStatus, MetaData] = NSB_SaveSeizureData(DataStruct, handles, curFile, curChannel, DataStruct.Channel(curChannel).ChNumber);
                    
  % % % % % %    Temp hack << AnalysisParameterEditor is not handling this correctly !!              %
                    handles.parameters.PreClinicalFramework.SeizureAnalysis.doSeizureReport = false;
  % % % % % %  
                    if handles.parameters.PreClinicalFramework.SeizureAnalysis.doSeizureReport
                        clear inputParms;
                        inputParms.handles = handles;
                        inputParms.EEGChannel = curChannel;
                        inputParms.ActivityChannel = [];
                        %options.SeizureChannel = SeizureChannel;
                        inputParms.curFile = curFile;
                        inputParms.logfile = handles.parameters.PreClinicalFramework.LogFile;
                        inputParms.TemplateFile = handles.parameters.PreClinicalFramework.SeizureAnalysis.SeizureReport_Template;
                        try
                        [status, filenames] = NSB_SaveSeizureReport(DataStruct, inputParms);
                        catch ME2
                        errorstr = ['ERROR: NSB_Workflow_LIMS >> Failed to save seizure report for Channel #',num2str(curChannel),' file: ',[StudyDesign{curFile,1}.path, StudyDesign{curFile,1}.name],' ',ME2.message];
                        NSBlog(options.logfile,errorstr);
                        disp(errorstr);
                        end
                    end
                    
                    end
                end
                
                
% %%%%%%%%%%%%%%%%%%%   Run Spectral Analysis
if options.progress
    if getappdata(hWaitbar,'Canceling')
        AbortFileLoad = true;
        break;
    end
end
                if handles.AnalysisStruct.doSpectralAnalysis
                   if isNotEMGChannel %Don't Process EMG Channel

                    txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    rows = rows+1;
                    txt{rows,1} = '...Running Spectral Analysis';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Running Spectral Analysis: ',datestr(now)]);
                    drawnow();
                    
                    clear inputParms;
                    inputParms = handles.parameters.PreClinicalFramework.SpectralAnalysis;
                    if strcmpi(handles.parameters.PreClinicalFramework.SpectralAnalysis.FFTWindowSizeMethod,'Auto')
                        inputParms.FFTWindowSize = [];
                    else
                        inputParms.FFTWindowSize = handles.parameters.PreClinicalFramework.SpectralAnalysis.FFTWindowSize;
                    end
                    inputParms.nanMean = handles.parameters.PreClinicalFramework.SpectralAnalysis.nanMean;
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
                        handles.parameters.PreClinicalFramework.SpectralAnalysis.FinalTimeResolution,...
                        handles.parameters.PreClinicalFramework.SpectralAnalysis.FinalFreqResolution,...
                        handles.parameters.PreClinicalFramework.ArtifactDetection.SampleRate, inputParms);
                                   
%CSV/Xls output here
                    txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    rows = rows+1;
                    txt{rows,1} = '...Saving Spectral Analysis';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Saving Spectral Analysis: ',datestr(now)]);
                    drawnow();
                    
                    [AnalysisStatus, MetaData] = NSB_SaveSpectralData(DataStruct, handles, curFile, curChannel, DataStruct.Channel(curChannel).ChNumber);
                    %Add file location meta data to Study Design for
                    %analysis later
                    MetaData.channel = curChannel;
                    if ~isfield(MetaData,'type'),MetaData.type='';end
                    if ~isfield(MetaData,'metadata'),MetaData.metadata='';end
                    if ~isfield(MetaData,'filename'),MetaData.filename='';end
   
                    if size(StudyDesign,2) < 3
                        %first entry
                        StudyDesign{curFile,3} = MetaData;
                    elseif isempty(StudyDesign{curFile,3})
                        %first entry for file
                        StudyDesign{curFile,3} = MetaData;
                    else
                        FileInfo = StudyDesign{curFile,3};%get structure
                        if length(FileInfo)+1 == curChannel
                            FileInfo = [FileInfo, MetaData];
                        else
                            curFieldnames = fieldnames(MetaData);
                            for curField = 1:length(curFieldnames)
                                FileInfo(curChannel).(curFieldnames{curField}) = MetaData.(curFieldnames{curField});
                            end
                        end
                        StudyDesign{curFile,3} = FileInfo;%return it
                    end
                   end
                end
                
% %%%%%%%%%%%%%%%%%%%   Run Sleep scoring
if options.progress
    if getappdata(hWaitbar,'Canceling')
        AbortFileLoad = true;
        break;
    end
end
                if handles.AnalysisStruct.doSomnogram
 
                    txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    rows = rows+1;
                    txt{rows,1} = '...Running Sleep Scoring';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Running Sleep Scoring: ',datestr(now)]);
                    drawnow();
                    
                    % Need to ID EEG and EMG Channel
                    inputParms = handles.parameters.PreClinicalFramework;
                    
                    %detect EMG channel
                    if ~isempty(options.EMGChan)
                        if isnumeric(options.EMGChan) %used chan number instead of name
                            EMGchannel = options.EMGChan;
                        else %string
                            EMGchannel = find(strcmpi(options.EMGChan,{DataStruct.Channel(:).Name})); %theoreticall only one chan but...
                            if length(EMGchannel) > 1
                                EMGchannel = [];
                                %report error
                                txt = get(handles.status_stxt,'String');
                                if iscell(txt)
                                    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                                    if length(txt) > StatusLines
                                        txt = txt(end-(StatusLines-1):end);
                                    end
                                    rows = length(txt);
                                else
                                    txt = {txt}; %create cell array
                                    rows = 1;
                                end
                                rows = rows+1;
                                txt{rows,1} = 'Warning: More than 1 EMG channel found. Ignoring EMG for Sleep Scoring';
                                set(handles.status_stxt,'String',txt);
                                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Warning: NSB_Workflow_LIMS >> More than 1 EMG channel found. Ignoring EMG for Sleep Scoring: ',datestr(now)]);
                            end
                        end
                    else
                        %try to find EMG channel
                        %EMGchannel = find(strcmpi('EMG',{DataStruct.Channel(:).Name})); %theoreticall only one chan but...
                        EMGchannel = find(~cellfun(@isempty,strfind({DataStruct.Channel(:).Name},'EMG')));
                        if length(EMGchannel) ~= 1
                              EMGchannel = [];
                                %report error
                                txt = get(handles.status_stxt,'String');
                                if iscell(txt)
                                    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                                    if length(txt) > StatusLines
                                        txt = txt(end-(StatusLines-1):end);
                                    end
                                    rows = length(txt);
                                else
                                    txt = {txt}; %create cell array
                                    rows = 1;
                                end
                                rows = rows+1;
                                txt{rows,1} = 'Warning: Did not find 1 EMG channel. Ignoring EMG for Sleep Scoring';
                                set(handles.status_stxt,'String',txt);
                                NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Warning: NSB_Workflow_LIMS >> Did not find 1 EMG channel. Ignoring EMG for Sleep Scoring: ',datestr(now)]);
                           
                        else
                            options.EMGChan = EMGchannel; %update options struct
                            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS >> Using Found EMG Channel #',num2str(EMGchannel),' for Sleep Scoring: ',datestr(now)]);
                        end
                    end
                    doSleepScoring = true;
                    if curChannel == EMGchannel %you need this in two steps because EMGchannel may be empty and as such returns empty not false
                        doSleepScoring = false;
                        status = false;
                    end
                    if doSleepScoring %Don't Score EMG Channel
                        %will need to figure out how to deal with the rest
                        %of the channels then... Maybe leverage file type
                        %but for now do all channels
                        
                        %SleepScoring now returns a new channel
                        HypnogramChannel = length(DataStruct.Channel) +1;
                        [SleepScore, status] = NSB_SleepScoring(DataStruct.Channel(curChannel), DataStruct.Channel(EMGchannel), [], inputParms);
                        %Because these may have different structures, manually populate new struct.
                        if status
                            SleepScoreFieldnames = fieldnames(SleepScore);
                            for curField = 1:length(SleepScoreFieldnames)
                                DataStruct.Channel(HypnogramChannel).(SleepScoreFieldnames{curField}) = SleepScore.(SleepScoreFieldnames{curField});
                            end
                            clear SleepScore SleepScoreFieldnames curField;
                            DataStruct.nChannels = DataStruct.nChannels +1;
                        end
                    end
                    %CSV/Xls output here
                    txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    rows = rows+1;
                    txt{rows,1} = '...Saving Somnogram Data';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Saving Somnogram Data: ',datestr(now)]);
                    drawnow();
                    
                    MetaData = [];
                    %[AnalysisStatus, MetaData] = NSB_SaveSomnogramData(DataStruct, handles, curFile, HypnogramChannel);
                    if status && doSleepScoring
                        [AnalysisStatus, MetaData] = NSB_SaveSomnogramData(DataStruct, handles, curFile, HypnogramChannel, DataStruct.Channel(curChannel).ChNumber);
                    else
                        %report error
                        txt = get(handles.status_stxt,'String');
                        if iscell(txt)
                            StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
                            if length(txt) > StatusLines
                                txt = txt(end-(StatusLines-1):end);
                            end
                            rows = length(txt);
                        else
                            txt = {txt}; %create cell array
                            rows = 1;
                        end
                        rows = rows+1;
                        txt{rows,1} = 'Warning: Could not generate hypnogram channel. Will not save Sleep Scoring';
                        set(handles.status_stxt,'String',txt);
                        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Warning: NSB_Workflow_LIMS >> Could not generate hypnogram channel. Will not save Sleep Scoring: ',datestr(now)]);
                    end
                    %Add file location meta data to Study Desighn for
                    %analysis later
                    MetaData.channel = curChannel;
                    if ~isfield(MetaData,'type'),MetaData.type='';end
                    if ~isfield(MetaData,'metadata'),MetaData.metadata='';end
                    if ~isfield(MetaData,'filename'),MetaData.filename='';end
   
                    if size(StudyDesign,2) < 3 + handles.AnalysisStruct.doSpectralAnalysis
                        %first entry
                        StudyDesign{curFile,end+1} = MetaData;
                    elseif isempty(StudyDesign{curFile,3+handles.AnalysisStruct.doSpectralAnalysis})
                        %first entry for file
                        StudyDesign{curFile,3} = MetaData;
                    else
                        FileInfo = StudyDesign{curFile,3};%get structure
                        if length(FileInfo)+1 == curChannel
                            FileInfo = [FileInfo, MetaData];
                        else
                            curFieldnames = fieldnames(MetaData);
                            for curField = 1:length(curFieldnames)
                                FileInfo(curChannel).(curFieldnames{curField}) = MetaData.(curFieldnames{curField});
                            end
                        end
                        StudyDesign{curFile,3} = FileInfo;%return it
                    end
%Generate Sleep Report
                    if handles.parameters.PreClinicalFramework.Scoring.doSomnogramReport && doSleepScoring
                        options.handles = handles;
                        options.EEGChannel = curChannel;
                        options.EMGChannel = EMGchannel;
                        options.ActivityChannel = [];
                        options.HypnogramChannel = HypnogramChannel;
                        options.curFile = curFile;
                        options.logfile = handles.parameters.PreClinicalFramework.LogFile;
                        options.TemplateFile = handles.parameters.PreClinicalFramework.Scoring.SomnogramReport_Template;
                        try
                        [status, filenames] = NSB_SaveHypnogramReport(DataStruct, options);
                        catch ME2
                        errorstr = ['ERROR: NSB_Workflow_LIMS >> Failed to save sleep report for Channel #',num2str(curChannel),' file: ',[StudyDesign{curFile,1}.path, StudyDesign{curFile,1}.name],' ',ME2.message];
                        NSBlog(options.logfile,errorstr);
                        end
                    end
                end
%Channel error catch
            catch ME
                errorstr = ['ERROR: NSB_Workflow_LIMS >> Failed Processing Channel #',num2str(curChannel),' file: ',[StudyDesign{curFile,1}.path, ' ',StudyDesign{curFile,1}.name]];
                NSBlog(options.logfile,errorstr);
                errorstr = ['ERROR: NSB_Workflow_LIMS >> ',ME.message];
                if ~isempty(ME.stack)
                    errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
                NSBlog(options.logfile,errorstr);
                end
                errordlg({['Failed Processing Channel #',num2str(curChannel),' file: ',[StudyDesign{curFile,1}.path, ' ', StudyDesign{curFile,1}.name]],...
                    errorstr},'NSB_SpectralAnalysis');
                
                txt = get(handles.status_stxt,'String');
                if iscell(txt)
                    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
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
        
%% Save as EDF if Requested (this will be moved after sleep scoring so that sleep stages can be saved to EDF)
        if handles.AnalysisStruct.doWriteEDF
            try
            txt = get(handles.status_stxt,'String');
                    if iscell(txt)
                        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
                        if length(txt) > StatusLines
                            txt = txt(end-(StatusLines-1):end);
                        end
                        rows = length(txt);
                    else
                        txt = {txt}; %create cell array
                        rows = 1;
                    end
                    
                    %if ~strcmpi(StudyDesign{curFile}.type,'.edf') %<< you
                    %will want to write sleep scoring.
                    rows = rows+1;
                    txt{rows,1} = '...Writing EDF';
                    set(handles.status_stxt,'String',txt);
                    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Writing EDF: ',datestr(now)]);
                    drawnow();
                    %\/\/ StudyDesign{curFile}.path{1} shuuld be a string <may be diff if dir load \/\/\/
                    status = NSB_EDFplusWriter(DataStruct, fullfile(char(StudyDesign{curFile}.path), 'NSB_Output', [StudyDesign{curFile}.name,'.edf']),options);
                    if status
                        rows = rows+1;
                        txt{rows,1} = '...Write Sucessful';
                        set(handles.status_stxt,'String',txt);
                        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Write EDF Sucessful: ',datestr(now)]);
                        drawnow();
                    else
                        rows = rows+1;
                        txt{rows,1} = '...Write Failed';
                        set(handles.status_stxt,'String',txt);
                        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Write EDF Failed: ',datestr(now)]);
                        drawnow();
                    end
%                     else
%                     rows = rows+1;
%                     txt{rows,1} = '...Skipping EDF->EDF';
%                     set(handles.status_stxt,'String',txt);
%                     NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Skipping EDF->EDF: ',datestr(now)]);
%                     drawnow();
%                     end
        %EDF error catch
            catch ME
                errorstr = ['ERROR: NSB_Workflow_LIMS >> Failed Writing: ',fullfile(char(StudyDesign{curFile}.path), 'NSB_Output', [StudyDesign{curFile}.name,'.edf']),' ',ME.message];
                NSBlog(options.logfile,errorstr);
                errordlg(errorstr,'EDF+ Writer');
                if ~isempty(ME.stack)
                    errorstr = ['ERROR: NSB_Workflow_LIMS >> ',ME.message];
                    errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
                NSBlog(options.logfile,errorstr);
                end
                
                txt = get(handles.status_stxt,'String');
                if iscell(txt)
                    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
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
try, delete(hWaitbar); end
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -5;
    if StatusLines < 1, StatusLines = 1; end;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array
    rows = 1;
end

if isempty(handles.StudyDesign)
    rows = rows+1;
    txt{rows,1} = 'No Data Selected to Run';
end
rows = rows+1;
txt{rows,1} = 'Finished Analysis';
set(handles.status_stxt,'String',txt);
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['>> NSB_Workflow_LIMS: Finished Signal Processing: ',datestr(now)]);

%% Cleanup
clear DataStruct;
clear inputParms;
clear FileInfo;

%% Stats Table
if handles.AnalysisStruct.doStatsTable
    %now that analysis is complete, aggrigate results in table
    txt = get(handles.status_stxt,'String');
    if iscell(txt)
        StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
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
    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Generating Statistical Table: ',datestr(now)]);
    drawnow();
    if ~isempty(handles.AnalysisStruct.StudyDesignFilePath)
        inputParms.logfile = handles.parameters.PreClinicalFramework.LogFile;
        inputParms.progress = handles.parameters.PreClinicalFramework.useWaitBar;
        inputParms.doMeanBaseline = handles.parameters.PreClinicalFramework.StatsTable.doMeanBaseline;
        
        status = NSB_GenerateStatTable(handles.AnalysisStruct.StudyDesignFilePath,...
            handles.parameters.PreClinicalFramework.StatsTable.BaselineMeanTimeStart,...
            handles.parameters.PreClinicalFramework.StatsTable.BaselineMeanTimeEnd,inputParms);
        
        if status
            rows = rows+1;
            txt{rows,1} = '...Statistical Table Generation Sucessful';
            set(handles.status_stxt,'String',txt);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Write Statistical Table Sucessful: ',datestr(now)]);
            drawnow();
        else
            rows = rows+1;
            txt{rows,1} = '...Statistical Table Generation Failed';
            set(handles.status_stxt,'String',txt);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Write Statistical Table Failed: ',datestr(now)]);
            drawnow();
        end
    else
        rows = rows+1;
        txt{rows,1} = 'No Study Design File to Analyze. Not Generating Stats Table.';
        set(handles.status_stxt,'String',txt);
        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Statistical Table Failed. No Study Design File: ',datestr(now)]);
    end
end

status = true;
