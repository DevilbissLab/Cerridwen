function [status, filenames] = NSB_SaveSomnogramData(RecordingStruct, options, curFile, chan, ChanLabel)
%[status, filenames] = NSB_SaveSomnogramData(RecordingStruct, options, curFile, chan, ScoredChan)
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
% December 8 2011, Version 1.0

[OutputDir,trash1,trash2] = fileparts(RecordingStruct.Filename);
OutputDir = fullfile(OutputDir,'NSB_Output');
OutputFile = ['NSB_SleepScoringAnalysis_',datestr(RecordingStruct.StartDate,29),'_',RecordingStruct.SubjectID,'_',RecordingStruct.Channel(chan).Name,'_',num2str(ChanLabel)];
%make sure output file has no special characters.
OutputFile = regexprep(OutputFile, '[<>:"?*\s]', '-', 'preservecase');

existXLSax = true;
if exist(OutputDir,'dir') == 0
    mkdir(OutputDir)
end
status = false;
filenames.type = 'somnogram';

%% generate MetaData Sheet
MetaDataArray = cell(0);
MetaDataArray{1,1} = 'NexStep Biomarkers Hypnogram Data';
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
% end
MetaDataArray{14,1} = 'Sampling Rate';
MetaDataArray{14,2} = RecordingStruct.Channel(chan).Hz;
MetaDataArray{15,1} = 'Epoch Length';
MetaDataArray{15,2} = options.parameters.PreClinicalFramework.Scoring.StageEpoch;

%Somnogram PArameters
StartCell = 16;
MetaDataArray{StartCell,1} = 'Scoring Type';
MetaDataArray{StartCell,2} = options.parameters.PreClinicalFramework.Scoring.ScoringType;

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
SheetHeader = ['Epoch No,Calendar Time,Bin Time,Stage Value,Stage Label,'];
SheetHeader = regexp(SheetHeader,'[\w\s\.]*','match');

%Generate Tables
EpochNumber = 1:length(RecordingStruct.Channel(chan).Data); EpochNumber = EpochNumber(:); %RowVec
BinTime = (EpochNumber-1)*options.parameters.PreClinicalFramework.Scoring.StageEpoch;
CalendarTime = datevec(RecordingStruct.StartDate);
% if strcmpi(RecordingStruct.FileFormat,'.dsi')
%     CalendarTime(:,4) = CalendarTime(:,4) + options.parameters.PreClinicalFramework.File.DSIoffset;
% end
CalendarTime = datenum([repmat(CalendarTime(1:5),length(BinTime),1), BinTime+CalendarTime(6)]);

ScoreIndex = [RecordingStruct.Channel(chan).Data]; ScoreIndex = ScoreIndex(:);
ScoreLabel = RecordingStruct.Channel(chan).Labels; ScoreLabel = ScoreLabel(:);

CellTable(:,1) = num2cell(EpochNumber);
CellTable(:,2) = num2cell(CalendarTime);
CellTable(:,3) = num2cell(BinTime);
CellTable(:,4) = num2cell(ScoreIndex);
CellTable(:,5) = ScoreLabel;

[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_SomnogramData.csv']),false);
[status,msg] = NSB_WriteGenericCSV(CellTable, fullfile(OutputDir,[OutputFile,'_SomnogramData.csv']),true);
if status
    filenames.filename = fullfile(OutputDir,[OutputFile,'_SomnogramData.csv']);
end

%%%%%Write BioBook Format
if options.parameters.PreClinicalFramework.BioBookoutput
%offset times in Windows Excel compatable manner
CalendarTime = CalendarTime  - 693960;
CellTable(:,2) = num2cell(CalendarTime);

[status,msg] = NSB_WriteGenericCSV(MetaDataArray, fullfile(OutputDir,[OutputFile,'_Somnogram_BioBook.csv']),false);
[status,msg] = NSB_WriteGenericCSV(cell(12,1), fullfile(OutputDir,[OutputFile,'_Somnogram_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_Somnogram_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(CellTable, fullfile(OutputDir,[OutputFile,'_Somnogram_BioBook.csv']),true);
%%%
end

%%%%%Write XLS sheet
if options.parameters.PreClinicalFramework.XLSoutput
if existXLSax
    [xlsstatus,msg] = xlswrite(fullfile(OutputDir,[OutputFile,'.xls']),SheetHeader,'SomnogramData','A1'); 
    [xlsstatus,msg] = xlswrite(fullfile(OutputDir,[OutputFile,'.xls']),CellTable,'SomnogramData','A2');
else
    dlmwrite(fullfile(OutputDir,OutputFile,'_SomnogramData.csv'),MetaDataArray,',');  
end
end
status = true;