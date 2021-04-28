function [status, filenames] = NSB_SaveSeizureData(RecordingStruct, options, curFile, chan, ChanLabel)
%[status, filenames] = NSB_SaveSeizureData(RecordingStruct, options, curFile, chan, ScoredChan)
%
% Inputs:
%   RecordingStruct              - (struct) NSB DataStruct
%   options                      - (struct) NSB Handles Structure
%   curFile                      - (double) current file/line of StudyDesign
%   chan                         - (double) Channel Number (UID)
%   ChanLabel                    - (double) Channel used to score Hypnogram (used for labeling)
%
% Outputs:
%   status                      - (logical) return value
%   filenames                   - (struct) status message if error
%       .type
%       .metadata
%       .filename
%
% NOTES: Writes standardized filename with a total of 6 fields seperated by
% underscore '_'.
% "NSB_{Filetype}_{SubjectID}_{ChannelName}_{ChannelNumber}_{format}.{ext}"
% Three files can be generated:
% 1a) Metadata file and 1b) Data file/sheet as a .CSV
% 2a) Metadata file and 2b) Data file/sheet as a .XLS
% 3) Biobook compatable Instrument file
% 
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% ---

[OutputDir,trash1,trash2] = fileparts(RecordingStruct.Filename);
OutputDir = fullfile(OutputDir,'NSB_Output');
OutputFile = ['NSB_SeizureAnalysis_',datestr(RecordingStruct.StartDate,29),'_',RecordingStruct.SubjectID,'_',RecordingStruct.Channel(chan).Name,'_',num2str(ChanLabel)];
%make sure output file has no special characters.
OutputFile = regexprep(OutputFile, '[<>:"?*\s]', '-', 'preservecase');

existXLSax = true;
if exist(OutputDir,'dir') == 0
    mkdir(OutputDir)
end
status = false;
filenames.type = 'seizure';
disp(['NSB_SaveSeizureData - Saving Seizure Files...']);

%% generate MetaData Sheet
MetaDataArray = cell(0);
MetaDataArray{1,1} = 'NexStep Biomarkers Seizure Data';
MetaDataArray{1,2} = get(options.ver_stxt,'String');
MetaDataArray{2,1} = 'Analysis Date';
MetaDataArray{2,2} = regexprep(get(options.date_stxt,'String'),',',''); %remove commas

MetaDataArray{4,1} = 'Group';
MetaDataArray{5,1} = 'Project';
MetaDataArray{6,1} = 'Study ID';
MetaDataArray{7,1} = 'Dose';
MetaDataArray{8,1} = 'Recording Date';

%we are now using  the Study Design
if iscell(options.StudyDesign{curFile,2})
MetaDataArray{4,2} = options.StudyDesign{curFile,2}.CompMtx.group;
MetaDataArray{5,2} = options.StudyDesign{curFile,2}.CompMtx.project;
MetaDataArray{6,2} = options.StudyDesign{curFile,2}.CompMtx.studyID;
MetaDataArray{7,2} = options.StudyDesign{curFile,2}.CompMtx.dose;
MetaDataArray{8,2} = options.StudyDesign{curFile,2}.CompMtx.date;
end
MetaDataArray{9,1} = 'Subject ID';
MetaDataArray{9,2} = RecordingStruct.SubjectID;
MetaDataArray{10,1} = 'Channel';
MetaDataArray{10,2} = chan;
MetaDataArray{10,3} = RecordingStruct.Channel(chan).Name;

MetaDataArray{12,1} = 'Path/File Name';
if isfield(RecordingStruct,'Filename')
    MetaDataArray{12,2} = RecordingStruct.Filename;
end
MetaDataArray{13,1} = 'Start Time';
% if strcmpi(RecordingStruct.FileFormat,'.dsi')
%     MetaDataArray{13,2} = datestr(RecordingStruct.StartDate + options.parameters.PreClinicalFramework.File.DSIoffset);
% else
    MetaDataArray{13,2} = datestr(RecordingStruct.StartDate);
%end
MetaDataArray{14,1} = 'Sampling Rate';
MetaDataArray{14,2} = RecordingStruct.Channel(chan).Hz;

%Seizure Analysis Parameters
StartCell = 16;
MetaDataArray(StartCell,1:7) = {'Signal Filtering', 'Filter Type', 'Stop Band 1 (Hz)', 'Pass Band 1 (Hz)','Pass Band 2(Hz)','Stop Band 2(Hz)', 'Stop Band Attenuation'};
MetaDataArray{StartCell+1,2} = 'FIR';
MetaDataArray{StartCell+1,3} = options.parameters.PreClinicalFramework.SeizureAnalysis.filter.Fstop1;
MetaDataArray{StartCell+1,4} = options.parameters.PreClinicalFramework.SeizureAnalysis.filter.Fpass1;
MetaDataArray{StartCell+1,5} = options.parameters.PreClinicalFramework.SeizureAnalysis.filter.Fpass2;
MetaDataArray{StartCell+1,6} = options.parameters.PreClinicalFramework.SeizureAnalysis.filter.Fstop2;
MetaDataArray{StartCell+1,7} = options.parameters.PreClinicalFramework.SeizureAnalysis.filter.Astop1;

MetaDataArray(StartCell+3,1:9) = {'Detector Settings', 'RMS Multiplier', 'Min. Spike Hz', 'Max. Spike Hz','Train Min. Hz','Train Max. Hz', 'Min. Train Duration (sec)', 'Min. Train Spikes (n= )', 'Join Trains < Interval (sec)'};
MetaDataArray{StartCell+4,2} = options.parameters.PreClinicalFramework.SeizureAnalysis.RMSMultiplier;
MetaDataArray{StartCell+4,3} = options.parameters.PreClinicalFramework.SeizureAnalysis.detector.Hzlow;
MetaDataArray{StartCell+4,4} = options.parameters.PreClinicalFramework.SeizureAnalysis.detector.Hzhigh;
MetaDataArray{StartCell+4,5} = 1/ options.parameters.PreClinicalFramework.SeizureAnalysis.detector.maxSpikeInt; %Yes These are Backwards because Max interval is Min Hz
MetaDataArray{StartCell+4,6} = 1/ options.parameters.PreClinicalFramework.SeizureAnalysis.detector.minSpikeInt;
MetaDataArray{StartCell+4,7} = options.parameters.PreClinicalFramework.SeizureAnalysis.detector.minTrainDur;
MetaDataArray{StartCell+4,8} = options.parameters.PreClinicalFramework.SeizureAnalysis.detector.minSpikes;
MetaDataArray{StartCell+4,9} = options.parameters.PreClinicalFramework.SeizureAnalysis.detector.minTrainGap;

%Seizure Analysis Summary << This is for the whole file
StartCell = 22;
MetaDataArray{StartCell,1} = 'Total Number of Spike Trains';
if ~isempty(RecordingStruct.Channel(chan).SeizureStruct)
MetaDataArray{StartCell,2} = length(RecordingStruct.Channel(chan).SeizureStruct.Spikes);
else
    MetaDataArray{StartCell,2} = 0;
end
MetaDataArray{StartCell+1,1} = 'Total Spike Train Duration (min)';
if ~isempty(RecordingStruct.Channel(chan).SeizureStruct)
MetaDataArray{StartCell+1,2} = sum( RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts) /60; %%%% <<< What happnes if none are found and no int ends??
else
    MetaDataArray{StartCell+1,2} = 0;
end
MetaDataArray{StartCell+1,3} = 'Percent of Recording';
MetaDataArray{StartCell+1,4} = 'N/A'; %<< TBA
MetaDataArray{StartCell+2,1} = 'Mean Spike Train Duration (sec)';
if ~isempty(RecordingStruct.Channel(chan).SeizureStruct)
MetaDataArray{StartCell+2,2} = mean( RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts);
else
    MetaDataArray{StartCell+2,2} = 0;
end
MetaDataArray{StartCell+3,1} = 'Longest Spike Train Duration (sec)';
if ~isempty(RecordingStruct.Channel(chan).SeizureStruct)
MetaDataArray{StartCell+3,2} = max( RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts);
else
    MetaDataArray{StartCell+3,2} = 0;
end
MetaDataArray{StartCell+4,1} = 'Shortest Spike Train Duration (sec)';
if ~isempty(RecordingStruct.Channel(chan).SeizureStruct)
MetaDataArray{StartCell+4,2} = min( RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts);
else
    MetaDataArray{StartCell+4,2} = 0;
end
MetaDataArray{StartCell+5,1} = 'Mean Number of Spikes/Train';
if ~isempty(RecordingStruct.Channel(chan).SeizureStruct)
MetaDataArray{StartCell+5,2} = mean(RecordingStruct.Channel(chan).SeizureStruct.Spikes);
else
    MetaDataArray{StartCell+5,2} = 0;
end
%Write Meta data
[status,msg] = NSB_WriteGenericCSV(MetaDataArray, fullfile(OutputDir,[OutputFile,'_MetaData.csv']));
if status
    filenames.metadata = fullfile(OutputDir,[OutputFile,'_MetaData.csv']);
end
%Write Meta data (XLS)
if options.parameters.PreClinicalFramework.XLSoutput
[xlsstatus,msg] = xlswrite(fullfile(OutputDir,[OutputFile,'.xls']),MetaDataArray,'MetaData');
if ~isempty(msg.message) && ~isempty(strfind(msg.message,'NoCOMServer'))
    %did not write properly and is likely not installed.
    existXLSax = false;
    delete(fullfile(OutputDir,OutputFile,'.xls'))
    %DLM does not accept cell arrays
    dlmwrite(fullfile(OutputDir,OutputFile,'_MetaData.csv'),MetaDataArray,',');
end
end

%% generate Data Sheet
%generate headers
SheetHeader = ['Epoch No,Calendar Time,Relative Time,Duration (sec),Spikes (n),Spike Rate (Hz),'];
SheetHeader = regexp(SheetHeader,'[ ()\w\s\.]*','match');

%Generate Tables
if ~isempty(RecordingStruct.Channel(chan).SeizureStruct)
    EpochNumber = 1:length(RecordingStruct.Channel(chan).SeizureStruct.Spikes); EpochNumber = EpochNumber(:); %RowVec
    CalendarTime = RecordingStruct.StartDate;
    
    if ~isempty(EpochNumber)
        CalendarTime = datevec(CalendarTime);
        
        % Bin time can actually be empty because it is possible that no seizure is
        % detected.
        if ~isempty(RecordingStruct.Channel(chan).SeizureStruct.intStarts)
            
            BinTime = RecordingStruct.Channel(chan).SeizureStruct.intStarts; BinTime = BinTime(:);
            % if strcmpi(RecordingStruct.FileFormat,'.dsi')
            %     CalendarTime(:,4) = CalendarTime(:,4) + options.parameters.PreClinicalFramework.File.DSIoffset;
            % end
            CalendarTime = datenum([repmat(CalendarTime(1:5),length(BinTime),1), BinTime+CalendarTime(6)]);
            
            CellTable(:,1) = num2cell(EpochNumber); %this one seems wrong
            CellTable(:,2) = num2cell(CalendarTime);
            CellTable(:,3) = num2cell(BinTime);
            CellTable(:,4) = num2cell(RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts);
            CellTable(:,5) = num2cell(RecordingStruct.Channel(chan).SeizureStruct.Spikes);
            CellTable(:,6) = num2cell((RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts) ./ RecordingStruct.Channel(chan).SeizureStruct.Spikes);
        else
            CellTable = cell(0);
        end
    else
        CellTable = cell(0);
    end
else
    CellTable = cell(0);
end
[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_SeizureData.csv']),false);
[status,msg] = NSB_WriteGenericCSV(CellTable, fullfile(OutputDir,[OutputFile,'_SeizureData.csv']),true);
if status
    filenames.filename = fullfile(OutputDir,[OutputFile,'_SeizureData.csv']);
end

%%%%%Write BioBook Format
if options.parameters.PreClinicalFramework.BioBookoutput
%offset times in Windows Excel compatable manner
CalendarTime = CalendarTime  - 693960;
CellTable(:,2) = num2cell(CalendarTime);

[status,msg] = NSB_WriteGenericCSV(MetaDataArray, fullfile(OutputDir,[OutputFile,'_Seizure_BioBook.csv']),false);
[status,msg] = NSB_WriteGenericCSV(cell(12,1), fullfile(OutputDir,[OutputFile,'_Seizure_BioBook.csv']),true);  % <<<<< Check if overwrites No but makes incompatable
[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_Seizure_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(CellTable, fullfile(OutputDir,[OutputFile,'_Seizure_BioBook.csv']),true);
%%%
end

%%%%%Write XLS sheet
if options.parameters.PreClinicalFramework.XLSoutput
if existXLSax
    [xlsstatus,msg] = xlswrite(fullfile(OutputDir,[OutputFile,'.xls']),SheetHeader,'SeizureData','A1'); 
    [xlsstatus,msg] = xlswrite(fullfile(OutputDir,[OutputFile,'.xls']),CellTable,'SeizureData','A2');
else
    dlmwrite(fullfile(OutputDir,OutputFile,'_SeizureData.csv'),MetaDataArray,',');  
end
end

%Generate Summary Table
SheetHeader = ['Total Number of Spike Trains,Total Spike Train Duration (min),Percent of Recording,Mean Spike Train Duration (sec),Longest Spike Train Duration (sec),Shortest Spike Train Duration (sec),Mean Number of Spikes/Train,'];
SheetHeader = regexp(SheetHeader,'[/ ()\w\s\.]*','match');
CellTable = cell(0);
if ~isempty(RecordingStruct.Channel(chan).SeizureStruct)
    CellTable(1,1) = num2cell(length(RecordingStruct.Channel(chan).SeizureStruct.Spikes));
    if CellTable{1,1} ~= 0
        CellTable(1,2) = num2cell(sum( RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts) /60);
        CellTable(1,3) = {'N/A'};
        
        if ~isempty(RecordingStruct.Channel(chan).SeizureStruct.intStarts)
            CellTable(1,4) = num2cell(mean( RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts));
            CellTable(1,5) = num2cell(max( RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts));
            CellTable(1,6) = num2cell(min( RecordingStruct.Channel(chan).SeizureStruct.intEnds - RecordingStruct.Channel(chan).SeizureStruct.intStarts));
        else
            CellTable(1,4) = {'N/A'};
            CellTable(1,5) = {'N/A'};
            CellTable(1,6) = {'N/A'};
        end
        CellTable(1,7) = num2cell(mean(RecordingStruct.Channel(chan).SeizureStruct.Spikes));
    else
        CellTable = cell(0);
    end
end
[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_SeizureDataSummary.csv']),false);
[status,msg] = NSB_WriteGenericCSV(CellTable, fullfile(OutputDir,[OutputFile,'_SeizureDataSummary.csv']),true);

status = true;