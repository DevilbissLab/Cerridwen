function [status, filenames] = NSB_SaveActiveInformationData(RecordingStruct, options, curFile, chan, ChanLabel)
%[status, filenames] = NSB_SaveSpectralData(RecordingStruct, options, curFile, chan)
%
% Inputs:
%   RecordingStruct              - (struct) NSB DataStruct
%   options                      - (struct) NSB Handles Structure
%   curFile                      - (double) current file/line of StudyDesign
%   chan                         - (double) Channel Number (UID)
%   ChanLabel                    - (double) Channel number (Used for labeling)
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
% "NSB_{Filetype}_{RecordingDate(ISO 8601)}_{SubjectID}_{ChannelName}_{ChannelNumber}_{format}.{ext}"
% Three files can be generated:
% 1a) Metadata file and 1b) Data file/sheet as a .CSV
% 2a) Metadata file and 2b) Data file/sheet as a .XLS
% 3) Biobook compatable Instrument file
% 
%
% Written By David M. Devilbiss
% Rowan University, Department of Neuroscience (devilbiss @ rowan.edu)
% April 13 2025, Version 1.0

[OutputDir,trash1,trash2] = fileparts(RecordingStruct.Filename);
OutputDir = fullfile(OutputDir,'NSB_Output');
OutputFile = ['NSB_AISAnalysis_',datestr(RecordingStruct.StartDate,29),'_',RecordingStruct.SubjectID,'_',RecordingStruct.Channel(chan).Name,'_',num2str(ChanLabel)];
%make sure output file has no special characters.
OutputFile = regexprep(OutputFile, '[<>:"?*\s]', '-', 'preservecase');

existXLSax = true;
if exist(OutputDir,'dir') == 0
    mkdir(OutputDir);
end
status = false;
filenames.type = 'ais';

%% generate MetaData Sheet
MetaDataArray = cell(0);
MetaDataArray{1,1} = 'NexStep Biomarkers AIS Data';
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
elseif isstruct(options.StudyDesign{curFile,2})
    MetaDataArray{4,2} = options.StudyDesign{curFile,2}.group;
    MetaDataArray{5,2} = options.StudyDesign{curFile,2}.project;
    MetaDataArray{6,2} = options.StudyDesign{curFile,2}.studyID;
    MetaDataArray{7,2} = options.StudyDesign{curFile,2}.dose;
    MetaDataArray{8,2} = options.StudyDesign{curFile,2}.date;
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
MetaDataArray{13,2} = datestr(RecordingStruct.StartDate);
MetaDataArray{14,1} = 'Sampling Rate';
MetaDataArray{14,2} = RecordingStruct.Channel(chan).Hz;
MetaDataArray{15,1} = 'Epoch Length';
MetaDataArray{15,2} = options.parameters.PreClinicalFramework.SpectralAnalysis.FinalTimeResolution;
% MetaDataArray{16,1} = 'Unit Measurement';
% if options.parameters.PreClinicalFramework.SpectralAnalysis.normSpectaTotalPower
%     MetaDataArray{16,2} = 'Ratio of Total Power';
%     MetaDataArray{16,3} = 'Normalized Power';    
% else
%     MetaDataArray{16,2} = RecordingStruct.Channel(chan).Units;
%     MetaDataArray{16,3} = 'Power';      
% end

[status,msg] = NSB_WriteGenericCSV(MetaDataArray, fullfile(OutputDir,[OutputFile,'_MetaData.csv']));
if status
    filenames.metadata = fullfile(OutputDir,[OutputFile,'_MetaData.csv']);
end
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
SheetHeader = ['Epoch No,Valid Epoch,Calendar Time,Bin Time,mean,optimal_k_history,NullMean,NullStd,Nullp'];
SheetHeader = regexp(SheetHeader,'[\w\s\.]*','match');

%Generate Tables
if isfield(RecordingStruct.Channel(chan),'Spectrum')
    %typically you would want to do both spectral and AIC/entropy
    EpochNumber = 1:size(RecordingStruct.Channel(chan).Spectrum,1); EpochNumber = EpochNumber(:); %RowVec
    BinTime = RecordingStruct.Channel(chan).Spectrum_ts(:);
    CalendarTime = datevec(RecordingStruct.StartDate);
    CalendarTime = datenum([repmat(CalendarTime(1:5),length(BinTime),1), BinTime+CalendarTime(6)]);

    DataTable = [EpochNumber,RecordingStruct.Channel(chan).ActiveInformationCalculator.validBins(:),CalendarTime,BinTime,...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.mean(:),...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.optimal_k_history(:),...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.NullMean(:),...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.NullStd(:),...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.Nullp(:)];
else
    EpochNumber = 1:length(RecordingStruct.Channel(chan).ActiveInformationCalculator.mean); EpochNumber = EpochNumber(:); %RowVec
    FinalTimeBinSize = options.parameters.PreClinicalFramework.SpectralAnalysis.FinalTimeResolution;
    BinTime = [0:FinalTimeBinSize:length(EpochNumber)*FinalTimeBinSize]; %returns in seconds
    BinTime = BinTime(1:length(EpochNumber));BinTime = BinTime(:);
    CalendarTime = datevec(RecordingStruct.StartDate);
    CalendarTime = datenum([repmat(CalendarTime(1:5),length(BinTime),1), BinTime+CalendarTime(6)]);

    DataTable = [EpochNumber,RecordingStruct.Channel(chan).ActiveInformationCalculator.validBins(:), CalendarTime,BinTime,...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.mean(:),...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.optimal_k_history(:),...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.NullMean(:),...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.NullStd(:),...
        RecordingStruct.Channel(chan).ActiveInformationCalculator.Nullp(:)];

end

[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_AISData.csv']),false);
[status,msg] = NSB_WriteGenericCSV(DataTable, fullfile(OutputDir,[OutputFile,'_AISData.csv']),true);
if status 
    filenames.filename = fullfile(OutputDir,[OutputFile,'_AISData.csv']);
end

%%%%%Write BioBook Format
if options.parameters.PreClinicalFramework.BioBookoutput
%offset times in Windows Excel compatable manner
CalendarTime = CalendarTime  - 693960;
DataTable = [EpochNumber,RecordingStruct.Channel(chan).ActiveInformationCalculator.validBins(:),CalendarTime,BinTime,...
    RecordingStruct.Channel(chan).ActiveInformationCalculator.mean(:),...
    RecordingStruct.Channel(chan).ActiveInformationCalculator.optimal_k_history(:),...
    RecordingStruct.Channel(chan).ActiveInformationCalculator.NullMean(:),...
    RecordingStruct.Channel(chan).ActiveInformationCalculator.NullStd(:),...
    RecordingStruct.Channel(chan).ActiveInformationCalculator.Nullp(:)];

%now write sheet
[status,msg] = NSB_WriteGenericCSV(MetaDataArray, fullfile(OutputDir,[OutputFile,'_AIS_BioBook.csv']),false);
[status,msg] = NSB_WriteGenericCSV(cell(12,1), fullfile(OutputDir,[OutputFile,'_AIS_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_AIS_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(DataTable, fullfile(OutputDir,[OutputFile,'_AIS_BioBook.csv']),true);
%%%
end
%%%%%Write xls sheet
if options.parameters.PreClinicalFramework.XLSoutput
if existXLSax
    [xlsstatus,msg] = xlswrite(fullfile(OutputDir,[OutputFile,'.xls']),SheetHeader,'ChanData','A1'); 
    [xlsstatus,msg] = xlswrite(fullfile(OutputDir,[OutputFile,'.xls']),DataTable,'ChanData','A2');
else
       dlmwrite(fullfile(OutputDir,OutputFile,'_MetaData.csv'),MetaDataArray,',');  
end
end
status = true;
