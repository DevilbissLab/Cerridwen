function [status, filenames] = NSB_SaveTransferEntropyData(RecordingStruct, handles, curFile, chans)
%[status, filenames] = NSB_SaveTransferEntropyData(RecordingStruct, handles, curFile, chans)
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

status = false;
filenames.type = 'TransferEntropy';
if isempty(chans)
    return;
end
%tempory fix for incomplete TE analysis
if length(chans) < 2
    return;
end

%Find ChanLabel
% Find the channel that the data struct is on.
for ch = chans  %<<<< 
    if isstruct(RecordingStruct.Channel(ch).TransferEntropyCalculator)
        MetaDataArray{10,3} = RecordingStruct.Channel(ch).TransferEntropyCalculator.name;
    else
        MetaDataArray{10,3} = RecordingStruct.Channel(chan).Name;
    end
end

[OutputDir,trash1,trash2] = fileparts(RecordingStruct.Filename);
OutputDir = fullfile(OutputDir,'NSB_Output');
OutputFile = ['NSB_TEAnalysis_',datestr(RecordingStruct.StartDate,29),'_',RecordingStruct.SubjectID,'_',RecordingStruct.Channel(chans(1)).Name,'_',num2str(ChanLabel)];
%make sure output file has no special characters.
OutputFile = regexprep(OutputFile, '[<>:"?*\s]', '-', 'preservecase');

existXLSax = true;
if exist(OutputDir,'dir') == 0
    mkdir(OutputDir);
end

%% generate MetaData Sheet
MetaDataArray = cell(0);
MetaDataArray{1,1} = 'NexStep Biomarkers TE Data';
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
MetaDataArray{10,2} = chans;
for ch = LIMS.ValidDataChans
    if isstruct(DataStruct.Channel(ch).TransferEntropyCalculator)
        MetaDataArray{10,3} = DataStruct.Channel(ch).TransferEntropyCalculator.name;
    else
        MetaDataArray{10,3} = RecordingStruct.Channel(chan).Name;
    end
end

MetaDataArray{12,1} = 'Path/File Name';
if isfield(RecordingStruct,'Filename')
    MetaDataArray{12,2} = RecordingStruct.Filename;
end
MetaDataArray{13,1} = 'Start Time';
MetaDataArray{13,2} = datestr(RecordingStruct.StartDate);
MetaDataArray{14,1} = 'Sampling Rate';
MetaDataArray{14,2} = RecordingStruct.Channel(chans).Hz;
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
EpochNumber = 1:size(RecordingStruct.Channel(chan).Spectrum,1); EpochNumber = EpochNumber(:); %RowVec
BinTime = RecordingStruct.Channel(chan).Spectrum_ts(:);
CalendarTime = datevec(RecordingStruct.StartDate);
CalendarTime = datenum([repmat(CalendarTime(1:5),length(BinTime),1), BinTime+CalendarTime(6)]);

DataTable = [EpochNumber,RecordingStruct.Channel(chan).Spectrum_validBins(:),CalendarTime,BinTime,...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.mean(:),...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.optimal_k_history(:),...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.NullMean(:),...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.NullStd(:),...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.Nullp(:)];

[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_TEData.csv']),false);
[status,msg] = NSB_WriteGenericCSV(DataTable, fullfile(OutputDir,[OutputFile,'_TEData.csv']),true);
if status 
    filenames.filename = fullfile(OutputDir,[OutputFile,'_TEData.csv']);
end


%%%%%Write BioBook Format
if options.parameters.PreClinicalFramework.BioBookoutput
%offset times in Windows Excel compatable manner
CalendarTime = CalendarTime  - 693960;
DataTable = [EpochNumber,RecordingStruct.Channel(chan).Spectrum_validBins(:),CalendarTime,BinTime,...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.mean(:),...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.optimal_k_history(:),...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.NullMean(:),...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.NullStd(:),...
    RecordingStruct.Channel(chan).TransferEntropyCalculator.Nullp(:)];

%now write sheet
[status,msg] = NSB_WriteGenericCSV(MetaDataArray, fullfile(OutputDir,[OutputFile,'_TE_BioBook.csv']),false);
[status,msg] = NSB_WriteGenericCSV(cell(12,1), fullfile(OutputDir,[OutputFile,'_TE_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_TE_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(DataTable, fullfile(OutputDir,[OutputFile,'_TE_BioBook.csv']),true);
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
