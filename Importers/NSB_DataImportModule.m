function [status, DataStruct] = NSB_DataImportModule(fileinfo,options)
%[status, DataStruct] = NSB_DataImportModule(fileinfo,options)
%
% Inputs:
%   fileinfo              - (Struct) StudyDesign cell(:,1)
%                               .type - file type (.edf,.rec,.nex,.smr,(dsi file folder),.fif,.sag(Sage Prop text format),.acq)
%                               .path - file path
%                               .name - file name
%   options               - (Struct) 'dir','xls','xml'
%                               .progress - (logical) show progress bar
%                               .logfile - logfile path+name
%                               .subjectID - Subjedt ID that is to be loaded
%
% Outputs:
%   DataStruct           - (struct) NSB File DataStructure
%                       returns a single struct representing the file for that Subject (ID)
%   status               - (logical) return value
%
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0
% October 12 2016, Ver 1.1 updated to use new EDF block reader
%
%NSB File DataStructure:
%All fields are requisite. others can be added and are optional
% .Version
% .SubjectID
% .Comment
% .StartDate
% .FileFormat
% .nRecords
% .nSeconds
% .nChannels
% .Channel
%     .Name
%     .ChNumber
%     .Units
%     .nSamples
%     .Hz
%     .Data
% .FileName

status = false;

if nargin == 1
    options.SegmentFolders = false;
    options.progress = true;
    options.logfile = '';
    options.Licensing = [];
    options.chans = 'all';
    options.showHeadPlot = false;
    options.assumeTemplateChOrderCorrect = false;
    options.PositionTemplate = '';
    options.DSIoffset = 0;
    options.subjectID = '';
end

try
switch lower(fileinfo.type)
        case {'.edf','.rec'}
            FileName = fullfile(fileinfo.path,fileinfo.name);
            if nargin == 2
                [DataStruct, status] = NSB_EDFreader2(FileName,options);
            else
                [DataStruct, status] = NSB_EDFreader2(FileName);
            end
            if status
                DataStruct.Filename = FileName; % < this is used by NSB_SaveSpectralData and other 'save' functions to put data in a NSBOutput subfolder
                % Determine whether there is a mismatch between subjectID in file and in study design
                if ~isempty(options.subjectID)
                    if ~strcmpi(DataStruct.SubjectID, options.subjectID) %returns false if is empty, true if both empty
                        if strcmpi(DataStruct.SubjectName, options.subjectID)
                            DataStruct.SubjectID = DataStruct.SubjectName;
                            infostr = ['Warning: NSB_DataImportModule >> PID in EDF file does not contain SubjectID. SubjectID is found in Patient Name and EDF may not conform to official specifications.'];
                            
                        elseif strcmpi(DataStruct.Gender, options.subjectID)
                            DataStruct.SubjectID = DataStruct.Gender;
                            infostr = ['Warning: NSB_DataImportModule >> PID in EDF file does not contain SubjectID. SubjectID is found in Gender field and EDF may not conform to official specifications.'];
                        elseif strcmpi(DataStruct.BirthDate, options.subjectID)
                            DataStruct.SubjectID = DataStruct.BirthDate;
                            infostr = ['Warning: NSB_DataImportModule >> PID in EDF file does not contain SubjectID. SubjectID is found in BirthDate and EDF may not conform to official specifications.'];
                        else
                            DataStruct.SubjectID = options.subjectID;
                            infostr = ['Warning: NSB_DataImportModule >> SubjectID not found in EDF header. Study Design .xls SubjectID will be used for PID field.'];
                        end
                        
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            disp(infostr);
                        end
                        
                    %else - do not check for other PID locations
               %else - do not check
                    end
                end
            end
            
        case {'.nex'}
            FileName = fullfile(fileinfo.path,fileinfo.name);
            %Warning Does not produce .nSamples
            [DataStruct, status] = NSB_NEXreader(FileName,5); %Read only Continuous channels
            if status
                DataStruct.Filename = FileName;
                if ~isempty(options.subjectID)
                    DataStruct.SubjectID = options.subjectID;
                    infostr = ['Warning: NSB_DataImportModule >> SubjectID not found in NEX header. Study Design .xls SubjectID will be used for SubjectID field.'];
                end
            end
            
        case {'.smr'}
            parms.dataset = fullfile(fileinfo.path,fileinfo.name);
            parms.DataChannels = 'ALL';
            parms.EventChannel = 'ALL';
            [DataStruct, status] = Spike2DataLoader(parms); %untested << incompatable structure
            if status
                DataStruct.Filename = fullfile(fileinfo.path,fileinfo.name);
            end
            
        case {'.dsi'}
            %
            % As part of an agreement with DSI - All DSI related functions
            % have been removed from this repository
            %
            [DataStruct,status] = NSB_DSIreader(fileinfo.path,fileinfo.name,options);
            if status
                %DataStruct.Filename = fullfile(char(fileinfo.path),char(fileinfo.name));%Here path can be a cellarray
                DataStruct.Filename = fullfile(char(fileinfo.path),filesep); %Force a trailing slash that way fileparts knows how to handle this
            end
            
        case {'.fif'}        
            FileName = fullfile(fileinfo.path,fileinfo.name);
            [DataStruct, status] = NSB_FIFreader(FileName,options);
            if status
                %here remap chan names using coordinates file.
                [DataStruct,map_status] = NSB_mapElectrodePosition(DataStruct,options);
                DataStruct.Filename = FileName;
            end
        case {'.sag','.s2t'}
            %. sag is Sage's propriatory text output
            FileName = fullfile(fileinfo.path,fileinfo.name);
            [DataStruct,status] = NSB_TXTreader(FileName);
            if status
                DataStruct.Filename = fullfile(char(fileinfo.path),char(fileinfo.name));%Here path can be a cellarray
            end
        case {'.acq'}
            FileName = fullfile(fileinfo.path,fileinfo.name);
            if exist(FileName) == 0
                FileName = fileinfo.path;
            end
            [DataStruct, status, msg] = NSB_ACQreader(FileName,fileinfo.name,options);
            if status
                DataStruct.Filename = FileName;
            end
            
        case {'.opp'}
            %.opp is Mark Opp's ICELUS LabView recording software
            %This is a renamed .txt file
%             FileName = fullfile(fileinfo.path,fileinfo.name);
%             if exist(FileName) == 0
%                 
%             end
            FileName = fileinfo.path;
            [DataStruct, status, msg] = NSB_OPPreader(FileName,fileinfo.name,options);
            if status
                DataStruct.Filename = FileName;
            end
            
        case {'.ns1','.ns2','.ns3','.ns4','.ns5'}
            %Blackrock Microsystems
            %disp('loading Blackrock');
            FileName = fullfile(fileinfo.path,fileinfo.name);
            [DataStruct, status, msg] = NSB_NSreader(fileinfo.path,fileinfo.name,options);
            if ~status
                infostr = ['Error: NSB_DataImportModule:NSB_NSreader >> ',msg];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    disp(infostr);
                end
            end
            %update fields if possible
            if isfield(options,'subjectID')
                if ~isempty(options.subjectID)
                    DataStruct.SubjectID = options.subjectID;
                     infostr = ['Warning: NSB_DataImportModule >> Blackrock Microsystem files do not contain SubjectID. Study Design .xls SubjectID will be used for SubjectID field.'];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            disp(infostr);
                        end
                end
            end
        otherwise
            %add other importers here ....
            status = false;
            DataStruct = [];
            return;
end

%Validate Critical Fields needed for file naming
if isempty(DataStruct.StartDate)
    infostr = ['Warning: NSB_DataImportModule >> File does not contain StartDate. User will not be able to create statistial table from Study Design.'];
    if ~isempty(options.logfile)
        NSBlog(options.logfile,infostr);
    else
        disp(infostr);
    end
elseif  DataStruct.StartDate ~= options.RecordingDate
    infostr = ['Warning: NSB_DataImportModule >> File StartDate and StudyDesign StartDate are not the same! User will not be able to create statistial table from Study Design.'];
    infostr2 = ['Warning: NSB_DataImportModule >> File StartDate: ',datestr(DataStruct.StartDate,29),' StudyDesign StartDate: ',datestr(options.RecordingDate,29)];
    if ~isempty(options.logfile)
        NSBlog(options.logfile,infostr);
        NSBlog(options.logfile,infostr2);
    else
        disp(infostr);
        disp(infostr2);
    end
end
if isempty(DataStruct.SubjectID)
    if ~isempty(options.subjectID)
        DataStruct.SubjectID = options.subjectID;
        infostr = ['Warning: NSB_DataImportModule >> File does not contain SubjectID. Using SubjectID in Study Design.'];
    else
        infostr = ['Warning: NSB_DataImportModule >> File does not contain SubjectID. User will not be able to create statistial table from Study Design.'];
        %status = false;
    end
    if ~isempty(options.logfile)
        NSBlog(options.logfile,infostr);
    else
        disp(infostr);
    end
elseif contains(DataStruct.SubjectID,'_')
        DataStruct.SubjectID = regexprep(DataStruct.SubjectID,'_','-'); %Replace all Underscores with hyphens
        infostr = ['Warning: NSB_DataImportModule >> SubjectID contains "_" and will be replaced with hyphens: ',DataStruct.SubjectID];
        if ~isempty(options.logfile)
            NSBlog(options.logfile,infostr);
        else
            disp(infostr);
        end
end
if isempty(DataStruct.Channel(end).Name)
    infostr = ['Warning: NSB_DataImportModule >> File does not contain Channel Names. User will not be able to create statistial table from Study Design.'];
    %status = false;
    if ~isempty(options.logfile)
        NSBlog(options.logfile,infostr);
    else
        disp(infostr);
    end
else
    %validate names.
    for curChan = 1:length(DataStruct.Channel)
        if contains(DataStruct.Channel(curChan).Name,'_')
            DataStruct.Channel(curChan).Name = regexprep(DataStruct.Channel(curChan).Name,'_','-'); %Replace all Underscores with hyphens
            infostr = ['Warning: NSB_DataImportModule >> ChannelName contains "_" and will be replaced with hyphens: ',DataStruct.Channel(curChan).Name];
            if ~isempty(options.logfile)
                NSBlog(options.logfile,infostr);
            else
                disp(infostr);
            end
        end
    end
end
if isempty(DataStruct.Channel(end).ChNumber)
    infostr = ['Warning: NSB_DataImportModule >> File does not contain Channel Numbers. User will not be able to create statistial table from Study Design.'];
    %status = false;
    if ~isempty(options.logfile)
        NSBlog(options.logfile,infostr);
    else
        disp(infostr);
    end
end
% This is used by NSB_SaveSpectralData and other 'save' functions to put data in a NSBOutput subfolder
[~,~,Ext] = fileparts(DataStruct.Filename);
if ~strcmp(DataStruct.Filename(end),'\') && isempty(Ext)
    DataStruct.Filename = [DataStruct.Filename,filesep];
end

catch ME
    errorstr = ['ERROR: NSB_DataImportModule >> ',ME.message];
    if ~isempty(ME.stack)
        errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
    end
    if ~isempty(options.logfile)
        NSBlog(options.logfile,errorstr);
    else
        disp(errorstr);
    end

    status = false;
   DataStruct = [];
end