function [status, StudyDesign] = NSB_BuildAnalysisStruct(FilePathName,type)
% [status, StudyDesign] = NSB_BuildAnalysisStruct(FilePathName,type)
%
% Inputs:
%   FilePathName          - (string) Path or Path+FileName of data
%   type                  - (string) 'dir','xls','xml'
%                           'dir' - looks in the curent directory only
%                           'xls' - processes an NSB_Formatted excel file
%                           'xml' - processes an NSB XML database file
%
% Outputs:
%   StudyDesign          - (cell) NSB DataStructure for analysis and internal record keeping
%   status               - (logical) return value
%
%StudyDesign is:
% 1-file name (Struct)
%    .type
%    .path
%    .name ( this will be animal name for dsi or full file name)
%    .DoseTime (optional)
%    .DoseChan (optional)
%    .LightsOff (optional)
%    .LightsOn (optional)
%    .GlobalParamsFile
%    .RefChannel
%    .EMGchan
%    .AnalysisChan false if Analyze all channels, struct if analyzing
%                    selective channels
%       .AnalysisChan(n).Name
%       .AnalysisChan(n).ParamsFile
%    .PositionTemplate
% 2-comparison mtx
%   .group
%   .project
%   .studyID
%   .dose
%   .animalID
%   .date
% 3:n cols- processed data
%    .type
%    .filenames
%    .metadata
%    .data
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0
% Febuary 1, 2013, Version 1.1 minor bug fix when importing spreadsheet
% with bad headers.
% March 1 2013, Version 1.2 added handling of:
%    .DoseChan (optional)
%    .GlobalParamsFile
%    .RefChannel
%    .EMGchan
%    .AnalysisChan false if Analyze all channels, struct if analyzing
%                    selective channels
%       .AnalysisChan(n).Name
%       .AnalysisChan(n).ParamsFile
%
% 30Nov2016, Version 1.3 bug fix for multiple channels indicated but one
% missing.
%ToDo better report errors in generating table to GUI (use cell array)
%
% Dir Structure
%   .dsi, .opp, .acq
%
% Independent Files:
%   .edf, .rec, .nex, .smr, .fif, .sag, .acq
%

%ToDo line 293+ add .opp dir 

status = false;
StudyDesign = cell(0);

if nargin < 2
    type = 'dir';
end
if ~ischar(FilePathName) || ~ischar(type)
    return;
end

switch lower(type)
    case 'dir'
        try
            filelist = fuf(FilePathName,0,'detail'); %recursive file find << 'false' = limit to cur dir (no recursion)
            %Determine if DSI(Segment) Directories
            [filepath,filename,fileext] = cellfun(@fileparts,filelist,'UniformOutput', false);
            %there is the rare occasion that if a folder contains a small number of files
            %with different extensions (not DSI) this will fail
            if (length(unique(fileext)) == length(filelist) || any(cell2mat(strfind(fileext,'.P')))) && (any(cell2mat(strfind(fileext,'.1'))) || any(cell2mat(strfind(fileext,'.2'))))
                SegmentFolders = true;
                filepath = unique(filepath);
                FileName.type = '.DSI';
            elseif any(cell2mat(strfind(fileext,'.opp')))  % << loading in here is a bad idea bwcause they have unique file names this way is a bad idea because the file nammes are uniques
                SegmentFolders = true;
                filepath = unique(filepath);
                FileName.type = '.opp';
             elseif any(cell2mat(strfind(fileext,'.acq')))
                SegmentFolders = true;
                filepath = unique(filepath);
                FileName.type = '.acq';
            else
                SegmentFolders = false;
                FileName.type = '';
            end
            
            
            %loop through all 1) files or 2) DSI(Segment) Directories
            if ~SegmentFolders
                % directory with single files
                for curfile = 1:length(filelist)
                    [filepath, filename, fileext] = fileparts(filelist{curfile});
                    FileName.type = fileext;
                    FileName.path = filepath;
                    FileName.name = [filename,fileext];
                    %FileName.DoseTime = []; %optional
                    %FileName.DoseChan = ''; %optional
                    FileName.GlobalParamsFile = '';
                    FileName.RefChannel = '';
                    FileName.EMGchan = '';
                    FileName.AnalysisChan = false;
                    FileName.PositionTemplate = '';
                    StudyDesign{curfile,1} = FileName;
                    StudyDesign{curfile,2} = 'File';
                end
            else
                UniqueAnimals = unique(filename);
                %handle 'opp' exception because the ID is embedded in the filename
                if strcmp(FileName.type,'.opp')
                    [~, ID] = cellfun(@NSB_parseOppFilename, filename, 'UniformOutput', false);
                    UniqueAnimals = unique(ID);
                end
                for curfile = 1:length(UniqueAnimals)
                    [filepath, filename, fileext] = fileparts(filelist{curfile});
                    %FileName.type = '.DSI'; %moved up because there are now 2 dir file types
                    FileName.path = filepath;
                    FileName.name = UniqueAnimals{curfile};
                    %FileName.DoseTime = []; %optional
                    %FileName.DoseChan = ''; %optional
                    FileName.GlobalParamsFile = '';
                    FileName.RefChannel = '';
                    FileName.EMGchan = '';
                    FileName.AnalysisChan = false;
                    FileName.PositionTemplate = '';
                    StudyDesign{curfile,1} = FileName;
                    StudyDesign{curfile,2} = 'File';
                end
            end
        catch ME
            disp(ME.message);
        end
    case 'xls'
        try
            [num,txt,raw] = xlsread(FilePathName);
            PathCol = find(strcmpi(raw(1,:),'File Path'));
            GroupsCol = find(strcmpi(raw(1,:),'Functional Group'));
            ProjectCol = find(strcmpi(raw(1,:),'Project/Compound'));
            StudyIDCol = find(strcmpi(raw(1,:),'StudyID'));
            DoseCol = find(strcmpi(raw(1,:),'Manipulation/Dose'));
            DateCol = find(strcmpi(raw(1,:),'Date'));
            AnimalCol = find(strcmpi(raw(1,:),'Animal')); %also see ...NSB_GenerateStatTable
            if isempty(AnimalCol)
                AnimalCol = find(strcmpi(raw(1,:),'Subject'));
            end
            if isempty(AnimalCol)
                AnimalCol = find(strcmpi(raw(1,:),'SubjectID'));
            end
            DoseTimeCol = find(strcmpi(raw(1,:),'Dose Time'));
            DoseChanCol = find(strcmpi(raw(1,:),'Dose Channel'));
            AnalysisChanCol = find(strcmpi(raw(1,:),'Analysis Channel'));
            ParamsChanCol = find(strcmpi(raw(1,:),'Parameter File'));
            ReferenceChanCol = find(strcmpi(raw(1,:),'Reference'));
            EMGChanCol = find(strcmpi(raw(1,:),'EMG Channel'));
            PosTemplateCol = find(strcmpi(raw(1,:),'Position Template'));
            SleepCycleStartCol = find(strcmpi(raw(1,:),'SleepCycle Start'));
            SleepCycleEndCol = find(strcmpi(raw(1,:),'SleepCycle End'));
            
            if any([isempty(PathCol),isempty(GroupsCol),isempty(ProjectCol),isempty(StudyIDCol),...
                    isempty(DoseCol),isempty(DateCol),isempty(AnimalCol),isempty(DoseTimeCol),...
                    isempty(DoseChanCol)]) %,isempty(AnalysisChanCol) DMD remove
                errordlg({'Warning >> Spreadsheet does not contain proper column headers.','Please fix headers and re-import sheet.'},'NSB_BuildAnalysisStruct >> Spreadsheet issue.');
            end
            
            filelist = raw(2:end,PathCol);
            hdrLength = 1;
            curRow = 0;
            for curfile = 1:length(filelist)
                FileName = struct(); %Start each itir with blank struct
                CompMtx = struct();
                
                if ~isempty(filelist{curfile})
                    if ~any(isnan(filelist{curfile}))
                        entryStatus = exist(filelist{curfile});
                    else
                        %NaN entry
                        continue;
                    end
                else
                    %Blank entry
                    continue;
                end
                if entryStatus == 2
                    %Process Entery as a real File
                    curRow = curRow +1;
                    [filepath, filename, fileext] = fileparts(filelist{curfile});
                    FileName.type = fileext;
                    FileName.path = filepath;
                    FileName.name = [filename,fileext];
                    FileName.DoseTime = datevec(raw{curfile+hdrLength,DoseTimeCol});
                    % new Entries v1.26
                    FileName.DoseChan = raw{curfile+hdrLength,DoseChanCol};
                    if length(ParamsChanCol) == 1
                        FileName.GlobalParamsFile = raw{curfile+hdrLength,ParamsChanCol};
                    else
                        FileName.GlobalParamsFile = '';
                    end
                    if length(ReferenceChanCol) == 1
                        if ~isnan(raw{curfile+hdrLength,ReferenceChanCol}) %Data exists in this cell
                            FileName.RefChannel = raw{curfile+hdrLength,ReferenceChanCol};
                        else
                            FileName.RefChannel = '';
                        end
                    else
                        FileName.RefChannel = '';
                    end
                    if length(EMGChanCol) == 1
                        if ~isnan(raw{curfile+hdrLength,EMGChanCol}) %Data exists in this cell
                            FileName.EMGchan = raw{curfile+hdrLength,EMGChanCol};
                        else
                            FileName.EMGchan = '';
                        end
                    else
                        FileName.EMGchan = '';
                    end
                    if length(PosTemplateCol) == 1
                        if ~isnan(raw{curfile+hdrLength,PosTemplateCol}) %Data exists in this cell
                            FileName.PositionTemplate = raw{curfile+hdrLength,PosTemplateCol};
                        else
                            FileName.PositionTemplate = '';
                        end
                    else
                        FileName.PositionTemplate = '';
                    end
                    %end new v1.26
                    % new Entries v1.5
                                if ~isempty(SleepCycleStartCol)
                                FileName.SleepCycleStart = datevec(raw{curfile+hdrLength,SleepCycleStartCol});
                                end
                                if ~isempty(SleepCycleEndCol)
                                FileName.SleepCycleEnd = datevec(raw{curfile+hdrLength,SleepCycleEndCol});
                                end
                    %end new v1.5
                    
                    CompMtx.group = raw{curfile+hdrLength,GroupsCol};
                    CompMtx.project = raw{curfile+hdrLength,ProjectCol};
                    CompMtx.studyID = raw{curfile+hdrLength,StudyIDCol};
                    CompMtx.dose = raw{curfile+hdrLength,DoseCol};
                    CompMtx.animalID = raw{curfile+hdrLength,AnimalCol};
                    CompMtx.date = raw{curfile+hdrLength,DateCol};
                    
                    %Now Deal with channels v1.26
                    badParmsChanLength = false;
                    chanCNTR = 1;
                    for curChan = 1:length(AnalysisChanCol)
                        if isnan(raw{curfile+hdrLength,AnalysisChanCol(curChan)})
                            FileName.AnalysisChan(curChan).Name = NaN;
                            %ignore extra columns
                            continue;
                        end
                        FileName.AnalysisChan(curChan).Name = raw{curfile+hdrLength,AnalysisChanCol(curChan)};
                        if length(ParamsChanCol) == length(AnalysisChanCol) %parm chan per file
                            FileName.AnalysisChan(curChan).ParamsFile = raw{curfile+hdrLength,ParamsChanCol(curChan)};
                        elseif length(ParamsChanCol) ~= length(AnalysisChanCol) && length(ParamsChanCol) > 1
                            FileName.AnalysisChan(curChan).ParamsFile = '';
                            badParmsChanLength = true;
                        else
                            FileName.AnalysisChan(curChan).ParamsFile = '';
                        end
                        chanCNTR = chanCNTR +1;
                    end
                    if badParmsChanLength
                        errordlg({'Spreadsheet has a mismatch between the number of Analysis Channels and Parameter Channels. No Channel-Specific parameters are being used; Only GLOBAL parameters.','Please fix headers and re-import sheet.'},'NSB_BuildAnalysisStruct >> Spreadsheet issue.');
                    end
                    %If there are no analysis columns or there
                    %is no data in those columns set FileName.AnalysisChan to flase insted of struct
                    if ~isempty(AnalysisChanCol) && isfield(FileName,'AnalysisChan')
                        if length(FileName.AnalysisChan) > 1
                            try %if this fails there is likely only some of the columns filled
                            if all(cellfun(@isnan,{FileName.AnalysisChan(:).Name})) ||  all(cellfun(@isempty,{FileName.AnalysisChan(:).Name}))
                            %if all are a non-empty non-char array (NaN or empty)
                            FileName.AnalysisChan = false;
                            end
                            end
                        else
                            try %if this fails there is likely only some of the columns filled
                            if all(isnan(FileName.AnalysisChan.Name)) ||  all(cellfun(@isempty,{FileName.AnalysisChan(:).Name}))
                                %if all are a non-empty non-char array (NaN or empty)
                                FileName.AnalysisChan = false;
                            end
                            end
                        end
                    else
                        FileName.AnalysisChan = false;
                    end
                    StudyDesign{curRow,1} = FileName;
                    StudyDesign{curRow,2} = CompMtx;
                    
                elseif entryStatus == 7
                    %Process entry as a real Folder
                    
                    curRow = curRow +1;
                    segfilelist = fuf(filelist{curfile},0,'detail');  %recursive file find << 'false' = limit to cur dir (no recursion)
                    if isempty(segfilelist)
                        SegmentFolders = false;
                        filepath = filelist{curfile};
                    else
                        %Determine if DSI(Segment) Directories
                        [filepath,filename,fileext] = cellfun(@fileparts,segfilelist,'UniformOutput', false);
                        %look for 1) every file has a unique extension (1 DSI
                        %subject in folder) 2) Files with a .Pxxx extension 3) Files with a .1xxx/ .2xxx/ .3/xxx extension
                        if length(unique(fileext)) == length(segfilelist) || any(cell2mat(strfind(fileext,'.P'))) || ...
                                any(cell2mat(strfind(fileext,'.1'))) || any(cell2mat(strfind(fileext,'.2'))) || any(cell2mat(strfind(fileext,'.2')))
                            SegmentFolders = true;
                            filepath = unique(filepath);
                            FileName.type = '.DSI';
                        elseif any(cell2mat(strfind(fileext,'.opp')))
                            SegmentFolders = true;
                            filepath = unique(filepath);
                            FileName.type = '.opp';
                        elseif any(cell2mat(strfind(fileext,'.acq')))
                            SegmentFolders = true;
                            filepath = unique(filepath);
                            FileName.type = '.acq';
                        else
                            SegmentFolders = false;
                            FileName.type = '';
                        end
                    end
                    if SegmentFolders
                        % DSI, .acq, or .opp data in specified folder
                        UniqueAnimals = unique(filename);
                        %deal with $System
                        ID_IDX = ~(~cellfun(@isempty,(strfind(UniqueAnimals,'$ystem'))) | ~cellfun(@isempty,(strfind(UniqueAnimals,'$tudy')))); %Get valid ID's
                        UniqueAnimals = UniqueAnimals(ID_IDX);
                        
                        %
                        % Single folders that contain ONE animal ID in a folder (?ignoring? $ystem and $tudy files) are the CORRECT Specification    
                        %
                        if length(UniqueAnimals) == 1 % 1 animal per folder
                            %FileName.type = '.DSI'; %moved up because there are now 2 dir file types
                            FileName.path = filepath{1};
                            FileName.name = UniqueAnimals{1};
                            FileName.DoseTime = datevec(raw{curfile+hdrLength,DoseTimeCol});
                            FileName.DoseChan = raw{curfile+hdrLength,DoseChanCol};
                            if length(ParamsChanCol) == 1
                                FileName.GlobalParamsFile = raw{curfile+hdrLength,ParamsChanCol};
                            else
                                FileName.GlobalParamsFile = '';
                            end
                            if length(ReferenceChanCol) == 1
                                if ~isnan(raw{curfile+hdrLength,ReferenceChanCol}) %Data exists in this cell
                                    FileName.RefChannel = raw{curfile+hdrLength,ReferenceChanCol};
                                else
                                    FileName.RefChannel = '';
                                end
                            else
                                FileName.RefChannel = '';
                            end
                            if length(EMGChanCol) == 1
                                if ~isnan(raw{curfile+hdrLength,EMGChanCol}) %Data exists in this cell
                                    FileName.EMGchan = raw{curfile+hdrLength,EMGChanCol};
                                else
                                    FileName.EMGchan = '';
                                end
                            else
                                FileName.EMGchan = '';
                            end
                            if length(PosTemplateCol) == 1
                                if ~isnan(raw{curfile+hdrLength,PosTemplateCol}) %Data exists in this cell
                                    FileName.PositionTemplate = raw{curfile+hdrLength,PosTemplateCol};
                                else
                                    FileName.PositionTemplate = '';
                                end
                            else
                                FileName.PositionTemplate = '';
                            end
                            % new Entries v1.5
                                if ~isempty(SleepCycleStartCol)
                                FileName.SleepCycleStart = datevec(raw{curfile+hdrLength,SleepCycleStartCol});
                                end
                                if ~isempty(SleepCycleEndCol)
                                FileName.SleepCycleEnd = datevec(raw{curfile+hdrLength,SleepCycleEndCol});
                                end
                            %end new v1.5
                            
                            CompMtx.group = raw{curfile+hdrLength,GroupsCol};
                            CompMtx.project = raw{curfile+hdrLength,ProjectCol};
                            CompMtx.studyID = raw{curfile+hdrLength,StudyIDCol};
                            CompMtx.dose = raw{curfile+hdrLength,DoseCol};
                            CompMtx.animalID = raw{curfile+hdrLength,AnimalCol};
                            CompMtx.date = raw{curfile+hdrLength,DateCol};
                            
                            %Now Deal with channels v1.26
                            badParmsChanLength = false;
                            chanCNTR = 1;
                            for curChan = 1:length(AnalysisChanCol)
                                if isnan(raw{curfile+hdrLength,AnalysisChanCol(curChan)})
                                    FileName.AnalysisChan(curChan).Name = NaN;
                                    %ignore extra columns
                                    continue;
                                end
                                FileName.AnalysisChan(curChan).Name = raw{curfile+hdrLength,AnalysisChanCol(curChan)};
                                if length(ParamsChanCol) == length(AnalysisChanCol) %parm chan per file
                                    FileName.AnalysisChan(curChan).ParamsFile = raw{curfile+hdrLength,ParamsChanCol(curChan)};
                                elseif length(ParamsChanCol) ~= length(AnalysisChanCol) && length(ParamsChanCol) > 1
                                    FileName.AnalysisChan(curChan).ParamsFile = '';
                                    badParmsChanLength = true;
                                else
                                    FileName.AnalysisChan(curChan).ParamsFile = '';
                                end
                                chanCNTR = chanCNTR +1;
                            end
                            if badParmsChanLength
                                errordlg({'Spreadsheet has a mismatch between the number of Analysis Channels and Parameter Channels. No Channel-Specific parameters are being used; Only GLOBAL parameters.','Please fix headers and re-import sheet.'},'NSB_BuildAnalysisStruct >> Spreadsheet issue.');
                            end
                            %If there are no analysis columns or there
                            %is no data in those columns set FileName.AnalysisChan to flase insted of struct
                            if ~isempty(AnalysisChanCol)
                                try
                                if all(cellfun(@isnan,{FileName.AnalysisChan(:).Name})) ||  all(cellfun(@isempty,{FileName.AnalysisChan(:).Name}))
                                    %if all are a non-empty non-char array (NaN or empty)
                                    FileName.AnalysisChan = false;
                                end
                                end
                            else
                                FileName.AnalysisChan = false;
                            end
                            StudyDesign{curRow,1} = FileName;
                            StudyDesign{curRow,2} = CompMtx;
                            
                        else
                            %
                            % Multiple animals found in dir - Incorrect
                            %  file structure specification.
                            %
                            %first check to see if Animal ID is specified in xls sheet
                            %
                            if isnumeric(raw{curfile+hdrLength,AnimalCol})
                                if ~isnan(raw{curfile+hdrLength,AnimalCol})
                                    AnimalName = num2str(raw{curfile+hdrLength,AnimalCol});
                                else
                                    AnimalName = ''; %field not filled
                                end
                            else
                                AnimalName = raw{curfile+hdrLength,AnimalCol};
                            end
                                                       
                            if strcmp(FileName.type,'.opp')
                                [~, ID, ~] = cellfun(@NSB_parseOppFilename, UniqueAnimals, 'UniformOutput', false);
                                tempAnimalID = regexp(AnimalName,'\d*','match');
                                tempAnimalID = tempAnimalID{:};
                                AnimalID_IDX = strcmp(ID,tempAnimalID);
                            else
                                AnimalID_IDX = ~cellfun(@isempty,(strfind(UniqueAnimals, AnimalName)));
                            end
                            
                            if any(AnimalID_IDX)
                                %FileName.type = '.DSI'; %moved up because there are now 2 dir file types
                                FileName.path = filepath{1};
                                FileName.name = AnimalName;
                                FileName.DoseTime = datevec(raw{curfile+hdrLength,DoseTimeCol});
                                % new Entries v1.26
                                FileName.DoseChan = raw{curfile+hdrLength,DoseChanCol};
                                if length(ParamsChanCol) == 1
                                    FileName.GlobalParamsFile = raw{curfile+hdrLength,ParamsChanCol};
                                else
                                    FileName.GlobalParamsFile = '';
                                end
                                if length(ReferenceChanCol) == 1
                                    if ~isnan(raw{curfile+hdrLength,ReferenceChanCol}) %Data exists in this cell
                                        FileName.RefChannel = raw{curfile+hdrLength,ReferenceChanCol};
                                    else
                                        FileName.RefChannel = '';
                                    end
                                else
                                    FileName.RefChannel = '';
                                end
                                if length(EMGChanCol) == 1
                                    if ~isnan(raw{curfile+hdrLength,EMGChanCol}) %Data exists in this cell
                                        FileName.EMGchan = raw{curfile+hdrLength,EMGChanCol};
                                    else
                                        FileName.EMGchan = '';
                                    end
                                else
                                    FileName.EMGchan = '';
                                end
                                if length(PosTemplateCol) == 1
                                    if ~isnan(raw{curfile+hdrLength,PosTemplateCol}) %Data exists in this cell
                                        FileName.PositionTemplate = raw{curfile+hdrLength,PosTemplateCol};
                                    else
                                        FileName.PositionTemplate = '';
                                    end
                                else
                                    FileName.PositionTemplate = '';
                                end
                                %end new
                                % new Entries v1.5
                                if ~isempty(SleepCycleStartCol)
                                FileName.SleepCycleStart = datevec(raw{curfile+hdrLength,SleepCycleStartCol});
                                end
                                if ~isempty(SleepCycleEndCol)
                                FileName.SleepCycleEnd = datevec(raw{curfile+hdrLength,SleepCycleEndCol});
                                end
                                %end new v1.5
                                
                                CompMtx.group = raw{curfile+hdrLength,GroupsCol};
                                CompMtx.project = raw{curfile+hdrLength,ProjectCol};
                                CompMtx.studyID = raw{curfile+hdrLength,StudyIDCol};
                                CompMtx.dose = raw{curfile+hdrLength,DoseCol};
                                CompMtx.animalID = AnimalName;
                                CompMtx.date = raw{curfile+hdrLength,DateCol};
                                %Now Deal with channels v1.26
                                badParmsChanLength = false;
                                chanCNTR = 1;
                                for curChan = 1:length(AnalysisChanCol)
                                    if isnan(raw{curfile+hdrLength,AnalysisChanCol(curChan)})
                                        FileName.AnalysisChan(curChan).Name = NaN;
                                        %ignore extra columns
                                        continue;
                                    end
                                    FileName.AnalysisChan(chanCNTR).Name = raw{curfile+hdrLength,AnalysisChanCol(curChan)};
                                    if length(ParamsChanCol) == length(AnalysisChanCol) %parm chan per file
                                        FileName.AnalysisChan(chanCNTR).ParamsFile = raw{curfile+hdrLength,ParamsChanCol(curChan)};
                                    elseif length(ParamsChanCol) ~= length(AnalysisChanCol) && length(ParamsChanCol) > 1
                                        FileName.AnalysisChan(chanCNTR).ParamsFile = '';
                                        badParmsChanLength = true;
                                    else
                                        FileName.AnalysisChan(chanCNTR).ParamsFile = '';
                                    end
                                    chanCNTR = chanCNTR +1;
                                end
                                if badParmsChanLength
                                    errordlg({'Spreadsheet has a mismatch between the number of Analysis Channels and Parameter Channels. No Channel-Specific parameters are being used; Only GLOBAL parameters.','Please fix headers and re-import sheet.'},'NSB_BuildAnalysisStruct >> Spreadsheet issue.');
                                end
                                %If there are no analysis columns or there
                                %is no data in those columns set FileName.AnalysisChan to flase insted of struct
                                if ~isempty(AnalysisChanCol)
                                    try
                                    if ~isfield(FileName,'AnalysisChan')
                                        FileName.AnalysisChan = false;
                                    elseif all(cellfun(@isnan,{FileName.AnalysisChan(:).Name})) ||  all(cellfun(@isempty,{FileName.AnalysisChan(:).Name}))
                                        %if all are a non-empty non-char array (NaN or empty)
                                        FileName.AnalysisChan = false;
                                    end
                                    end
                                else
                                    FileName.AnalysisChan = false;
                                end
                                StudyDesign{curRow,1} = FileName;
                                StudyDesign{curRow,2} = CompMtx;
                                
                            elseif ~isempty(AnimalName) && ~any(~cellfun(@isempty,(strfind(UniqueAnimals, AnimalName)))) 
                                % Animal name present but not matched (ID not found).
                                % ACTION: skip line
                                %Blank entry
                                curRow = curRow -1; %Backstep one because we are not assigning the current struct.
                                errordlg({[AnimalName, ' in row#' ,num2str(curfile),' does not match data in folder.'],'Please check SubjectID andd re-import sheet.'},'NSB_BuildAnalysisStruct >> Spreadsheet issue.');
                                continue;
                                
                            else
                                % USER did not define an animal name = all
                                % ACTION: handle exception
                                % ASSUME: animals in folder got same treatment
                                for curAnimal = 1:length(UniqueAnimals)

                                    %FileName.type = '.DSI'; %moved up because there are now 2 dir file types
                                    FileName.path = filepath{1};
                                    FileName.name = UniqueAnimals{curAnimal};
                                    FileName.DoseTime = datevec(raw{curfile+hdrLength,DoseTimeCol});
                                    % new Entries v1.26
                                    FileName.DoseChan = raw{curfile+hdrLength,DoseChanCol};
                                    if length(ParamsChanCol) == 1
                                        FileName.GlobalParamsFile = raw{curfile+hdrLength,ParamsChanCol};
                                    else
                                        FileName.GlobalParamsFile = '';
                                    end
                                    if length(ReferenceChanCol) == 1
                                        if ~isnan(raw{curfile+hdrLength,ReferenceChanCol}) %Data exists in this cell
                                            FileName.RefChannel = raw{curfile+hdrLength,ReferenceChanCol};
                                        else
                                            FileName.RefChannel = '';
                                        end
                                    else
                                        FileName.RefChannel = '';
                                    end
                                    if length(EMGChanCol) == 1
                                        if ~isnan(raw{curfile+hdrLength,EMGChanCol}) %Data exists in this cell
                                            FileName.EMGchan = raw{curfile+hdrLength,EMGChanCol};
                                        else
                                            FileName.EMGchan = '';
                                        end
                                    else
                                        FileName.EMGchan = '';
                                    end
                                    if length(PosTemplateCol) == 1
                                        if ~isnan(raw{curfile+hdrLength,PosTemplateCol}) %Data exists in this cell
                                            FileName.PositionTemplate = raw{curfile+hdrLength,PosTemplateCol};
                                        else
                                            FileName.PositionTemplate = '';
                                        end
                                    else
                                        FileName.PositionTemplate = '';
                                    end
                                    %end new
                                    % new Entries v1.5
                                if ~isempty(SleepCycleStartCol)
                                FileName.SleepCycleStart = datevec(raw{curfile+hdrLength,SleepCycleStartCol});
                                end
                                if ~isempty(SleepCycleEndCol)
                                FileName.SleepCycleEnd = datevec(raw{curfile+hdrLength,SleepCycleEndCol});
                                end
                                    %end new v1.5
                                    
                                    CompMtx.group = raw{curfile+hdrLength,GroupsCol};
                                    CompMtx.project = raw{curfile+hdrLength,ProjectCol};
                                    CompMtx.studyID = raw{curfile+hdrLength,StudyIDCol};
                                    CompMtx.dose = raw{curfile+hdrLength,DoseCol};
                                    CompMtx.animalID = UniqueAnimals{curAnimal};
                                    CompMtx.date = raw{curfile+hdrLength,DateCol};
                                    
                                    %Now Deal with channels v1.26
                                    badParmsChanLength = false;
                                    chanCNTR = 1;
                                    for curChan = 1:length(AnalysisChanCol)
                                        if isnan(raw{curfile+hdrLength,AnalysisChanCol(curChan)})
                                            FileName.AnalysisChan(curChan).Name = NaN;
                                            %ignore extra columns
                                            continue;
                                        end
                                        FileName.AnalysisChan(curChan).Name = raw{curfile+hdrLength,AnalysisChanCol(curChan)}; %if cols exist AnalysisChan is logical and cannto convert
                                        if length(ParamsChanCol) == length(AnalysisChanCol) %parm chan per file
                                            FileName.AnalysisChan(curChan).ParamsFile = raw{curfile+hdrLength,ParamsChanCol(curChan)};
                                        elseif length(ParamsChanCol) ~= length(AnalysisChanCol) && length(ParamsChanCol) > 1
                                            FileName.AnalysisChan(curChan).ParamsFile = '';
                                            badParmsChanLength = true;
                                        else
                                            FileName.AnalysisChan(curChan).ParamsFile = '';
                                        end
                                    end
                                    if badParmsChanLength
                                        errordlg({'Spreadsheet has a mismatch between the number of Analysis Channels and Parameter Channels. No Channel-Specific parameters are being used; Only GLOBAL parameters.','Please fix headers and re-import sheet.'},'NSB_BuildAnalysisStruct >> Spreadsheet issue.');
                                    end
                                    %If there are no analysis columns or there
                                    %is no data in those columns set FileName.AnalysisChan to flase insted of struct
                                    if ~isempty(AnalysisChanCol)
                                        try
                                        if all(cellfun(@isnan,{FileName.AnalysisChan(:).Name})) ||  all(cellfun(@isempty,{FileName.AnalysisChan(:).Name}))
                                            FileName.AnalysisChan = false;
                                        end
                                        end
                                    else
                                        FileName.AnalysisChan = false;
                                    end
                                    FileName = rmfield(FileName,'AnalysisChan'); %Special case to remove field in local animal loop
                                    StudyDesign{curRow,1} = FileName;
                                    StudyDesign{curRow,2} = CompMtx;
                                    curRow = curRow +1;
                                end
                            end
                        end
                    else
%                         
%                         % this is badly handled here should be incorporated
%                         % above - folder specified but no segment folder 
%                         
%                         
%                         FileName.type = '.acq';
%                         if iscell(filepath)
%                             if length(filepath) > 1
%                                 FileName.path = unique(filepath);
%                             end
%                             FileName.path = FileName.path{1};
%                         end
%                         
%                          %incorrect format and multiple animals in dir
%                             %first check to see if Animal ID is specified in xls sheet
%                             if isnumeric(raw{curfile+hdrLength,AnimalCol})
%                                 if ~isnan(raw{curfile+hdrLength,AnimalCol})
%                                     AnimalName = num2str(raw{curfile+hdrLength,AnimalCol});
%                                 else
%                                     AnimalName = ''; %field not filled
%                                 end
%                             else
%                                 AnimalName = raw{curfile+hdrLength,AnimalCol};
%                             end
%                         FileName.name = AnimalName;
%                         FileName.DoseTime = datevec(raw{curfile+hdrLength,DoseTimeCol});
%                         FileName.DoseChan = raw{curfile+hdrLength,DoseChanCol};
%                         if length(ParamsChanCol) == 1
%                                 FileName.GlobalParamsFile = raw{curfile+hdrLength,ParamsChanCol};
%                             else
%                                 FileName.GlobalParamsFile = '';
%                         end
%                             if length(ReferenceChanCol) == 1
%                                 if ~isnan(raw{curfile+hdrLength,ReferenceChanCol}) %Data exists in this cell
%                                     FileName.RefChannel = raw{curfile+hdrLength,ReferenceChanCol};
%                                 else
%                                     FileName.RefChannel = '';
%                                 end
%                             else
%                                 FileName.RefChannel = '';
%                             end
%                             if length(EMGChanCol) == 1
%                                 if ~isnan(raw{curfile+hdrLength,EMGChanCol}) %Data exists in this cell
%                                     FileName.EMGchan = raw{curfile+hdrLength,EMGChanCol};
%                                 else
%                                     FileName.EMGchan = '';
%                                 end
%                             else
%                                 FileName.EMGchan = '';
%                             end
%                             if length(PosTemplateCol) == 1
%                                 if ~isnan(raw{curfile+hdrLength,PosTemplateCol}) %Data exists in this cell
%                                     FileName.PositionTemplate = raw{curfile+hdrLength,PosTemplateCol};
%                                 else
%                                     FileName.PositionTemplate = '';
%                                 end
%                             else
%                                 FileName.PositionTemplate = '';
%                             end
%                             % new Entries v1.5
%                                 if ~isempty(SleepCycleStartCol)
%                                 FileName.SleepCycleStart = datevec(raw{curfile+hdrLength,SleepCycleStartCol});
%                                 end
%                                 if ~isempty(SleepCycleEndCol)
%                                 FileName.SleepCycleEnd = datevec(raw{curfile+hdrLength,SleepCycleEndCol});
%                                 end
%                             %end new v1.5
%                         badParmsChanLength = false;
%                             chanCNTR = 1;
%                             for curChan = 1:length(AnalysisChanCol)
%                                 if isnan(raw{curfile+hdrLength,AnalysisChanCol(curChan)})
%                                     FileName.AnalysisChan(curChan).Name = NaN;
%                                     %ignore extra columns
%                                     continue;
%                                 end
%                                 FileName.AnalysisChan(curChan).Name = raw{curfile+hdrLength,AnalysisChanCol(curChan)};
%                                 if length(ParamsChanCol) == length(AnalysisChanCol) %parm chan per file
%                                     FileName.AnalysisChan(curChan).ParamsFile = raw{curfile+hdrLength,ParamsChanCol(curChan)};
%                                 elseif length(ParamsChanCol) ~= length(AnalysisChanCol) && length(ParamsChanCol) > 1
%                                     FileName.AnalysisChan(curChan).ParamsFile = '';
%                                     badParmsChanLength = true;
%                                 else
%                                     FileName.AnalysisChan(curChan).ParamsFile = '';
%                                 end
%                                 chanCNTR = chanCNTR +1;
%                             end
%                             if badParmsChanLength
%                                 errordlg({'Spreadsheet has a mismatch between the number of Analysis Channels and Parameter Channels. No Channel-Specific parameters are being used; Only GLOBAL parameters.','Please fix headers and re-import sheet.'},'NSB_BuildAnalysisStruct >> Spreadsheet issue.');
%                             end
%                             %If there are no analysis columns or there
%                             %is no data in those columns set FileName.AnalysisChan to flase insted of struct
%                             if ~isempty(AnalysisChanCol)
%                                 try
%                                     if all(cellfun(@isnan,{FileName.AnalysisChan(:).Name})) ||  all(cellfun(@isempty,{FileName.AnalysisChan(:).Name}))
%                                         %if all are a non-empty non-char array (NaN or empty)
%                                         FileName.AnalysisChan = false;
%                                     end
%                                 catch
%                                     FileName.AnalysisChan = false;
%                                 end
%                             else
%                                 FileName.AnalysisChan = false;
%                             end
%                             CompMtx.group = raw{curfile+hdrLength,GroupsCol};
%                             CompMtx.project = raw{curfile+hdrLength,ProjectCol};
%                             CompMtx.studyID = raw{curfile+hdrLength,StudyIDCol};
%                             CompMtx.dose = raw{curfile+hdrLength,DoseCol};
%                             CompMtx.animalID = AnimalName;
%                             CompMtx.date = raw{curfile+hdrLength,DateCol};
%                             
%                             
%                         StudyDesign{curfile,1} = FileName;
%                         StudyDesign{curfile,2} = CompMtx;
                        
                        %wrong format multiple EDF's etc in folder
                        disp(['WARNING>> Invalid Dir entry: line ',num2str(curfile+hdrLength),' must be .acq, .opp, or DSI format']);
                        
                    end
                else
                    disp(['Invalid Dir entry - File/dir Does not exist is StudyDesign Sheet (xls): line ',num2str(curfile+hdrLength)]);
                end
            end
        catch ME
            disp(ME.message);
        end
        
    case 'xml'
        disp('Not Currently Implemented');
    otherwise
        disp('Not a Valid Input type');
end
status = true;