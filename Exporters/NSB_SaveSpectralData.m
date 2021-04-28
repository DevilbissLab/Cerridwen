function [status, filenames] = NSB_SaveSpectralData(RecordingStruct, options, curFile, chan, ChanLabel)
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
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0

[OutputDir,trash1,trash2] = fileparts(RecordingStruct.Filename);
OutputDir = fullfile(OutputDir,'NSB_Output');
OutputFile = ['NSB_SpectralAnalysis_',datestr(RecordingStruct.StartDate,29),'_',RecordingStruct.SubjectID,'_',RecordingStruct.Channel(chan).Name,'_',num2str(ChanLabel)];
%make sure output file has no special characters.
OutputFile = regexprep(OutputFile, '[<>:"?*\s]', '-', 'preservecase');

existXLSax = true;
if exist(OutputDir,'dir') == 0
    mkdir(OutputDir);
end
status = false;
filenames.type = 'spectral';

%% generate MetaData Sheet
MetaDataArray = cell(0);
MetaDataArray{1,1} = 'NexStep Biomarkers Spectral Data';
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
MetaDataArray{15,2} = options.parameters.PreClinicalFramework.SpectralAnalysis.FinalTimeResolution;
MetaDataArray{16,1} = 'Unit Measurement';
if options.parameters.PreClinicalFramework.SpectralAnalysis.normSpectaTotalPower
    MetaDataArray{16,2} = 'Ratio of Total Power';
    MetaDataArray{16,3} = 'Normalized Power';    
else
    MetaDataArray{16,2} = RecordingStruct.Channel(chan).Units;
    MetaDataArray{16,3} = 'Power';      
end

%band ratios
StartCell = 18;
MetaDataArray{StartCell,1} = 'Band Frequencies';
MetaDataArray{StartCell,2} = 'Start';
MetaDataArray{StartCell,3} = 'Stop';
for curRatio = 1:length(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralBands)
    MetaDataArray{StartCell+curRatio,1} = ['Band ',num2str(curRatio)];
    if isnan(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralBands(curRatio).Start) ||  isnan(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralBands(curRatio).Stop)
        MetaDataArray{StartCell+curRatio,2} = '';
        MetaDataArray{StartCell+curRatio,3} = '';
    else
        MetaDataArray{StartCell+curRatio,2} = options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralBands(curRatio).Start;
        MetaDataArray{StartCell+curRatio,3} = options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralBands(curRatio).Stop;
    end
end
StartCell = StartCell + curRatio +1;
MetaDataArray{StartCell,1} = 'Band Ratios';
MetaDataArray{StartCell,2} = 'Numerator';
MetaDataArray{StartCell,3} = 'Denominator';
for curRatio = 1:length(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio)
    MetaDataArray{StartCell+curRatio,1} = ['Ratio ',num2str(curRatio)];
    if isnan(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).num) ||  isnan(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).den)
        MetaDataArray{StartCell+curRatio,2} = '';
        MetaDataArray{StartCell+curRatio,3} = '';
    else
        MetaDataArray{StartCell+curRatio,2} = options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).num;
        MetaDataArray{StartCell+curRatio,3} = options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).den;
    end
end

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
SheetHeader = ['Epoch No,Valid Epoch,Calendar Time,Bin Time,Band 1,Band 2,Band 3,Band 4,Band 5,Ratio 1,Ratio 2,Ratio 3,Ratio 4,Ratio 5,',regexprep(num2str(RecordingStruct.Channel(chan).Spectrum_freqs),'\s*',',')];
SheetHeader = regexp(SheetHeader,'[\w\s\.]*','match');

%Generate Tables
EpochNumber = 1:size(RecordingStruct.Channel(chan).Spectrum,1); EpochNumber = EpochNumber(:); %RowVec
BinTime = RecordingStruct.Channel(chan).Spectrum_ts(:);
CalendarTime = datevec(RecordingStruct.StartDate);
% if strcmpi(RecordingStruct.FileFormat,'.dsi')
%     CalendarTime(:,4) = CalendarTime(:,4) + options.parameters.PreClinicalFramework.File.DSIoffset;
% end
CalendarTime = datenum([repmat(CalendarTime(1:5),length(BinTime),1), BinTime+CalendarTime(6)]);

%Generate Spectral norm (total power) << there are other ways to do htis i.e. l_1 norm
if options.parameters.PreClinicalFramework.SpectralAnalysis.normSpectaTotalPower
    SpectralNorm = sum(RecordingStruct.Channel(chan).Spectrum(:,2:end),2); %get sum for each row (i.e. each time slice)
    [r,c] = size(RecordingStruct.Channel(chan).Spectrum);
    NormSpectralMatrix = RecordingStruct.Channel(chan).Spectrum./(repmat(SpectralNorm,1,c));
else
    NormSpectralMatrix = RecordingStruct.Channel(chan).Spectrum;
end

%calculate bands
for curBand = 1:length(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralBands)
    lowIDX = find(RecordingStruct.Channel(chan).Spectrum_freqs >= options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralBands(curBand).Start,1,'first');
    highIDX = find(RecordingStruct.Channel(chan).Spectrum_freqs <= options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralBands(curBand).Stop,1,'last');
    BandMatrix(:,curBand) = sum(NormSpectralMatrix(:,lowIDX:highIDX),2);
end
%calculate bandRatios
for curRatio = 1:length(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio)
    if isnan(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).num) ||...
            isnan(options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).den)
        RatioMatrix(:,curRatio) = BandMatrix(:,curRatio);
    elseif options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).num == ...
        options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).den
        RatioMatrix(:,curRatio) = ones(length(BandMatrix(:,curRatio)),1);
    else
        RatioMatrix(:,curRatio) = BandMatrix(:,options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).num)./...
            BandMatrix(:,options.parameters.PreClinicalFramework.SpectralAnalysis.SpectralRatio(curRatio).den);
    end
end

DataTable = [EpochNumber,RecordingStruct.Channel(chan).Spectrum_validBins(:),CalendarTime,BinTime,...
    BandMatrix, RatioMatrix, NormSpectralMatrix];

[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_SpectralData.csv']),false);
[status,msg] = NSB_WriteGenericCSV(DataTable, fullfile(OutputDir,[OutputFile,'_SpectralData.csv']),true);
if status
    filenames.filename = fullfile(OutputDir,[OutputFile,'_SpectralData.csv']);
end

%%%%%Write BioBook Format
if options.parameters.PreClinicalFramework.BioBookoutput
%offset times in Windows Excel compatable manner
CalendarTime = CalendarTime  - 693960;
DataTable = [EpochNumber,RecordingStruct.Channel(chan).Spectrum_validBins(:),CalendarTime,BinTime,...
    BandMatrix, RatioMatrix, NormSpectralMatrix];

%now write sheet
[status,msg] = NSB_WriteGenericCSV(MetaDataArray, fullfile(OutputDir,[OutputFile,'_Spectral_BioBook.csv']),false);
[status,msg] = NSB_WriteGenericCSV(cell(12,1), fullfile(OutputDir,[OutputFile,'_Spectral_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[OutputFile,'_Spectral_BioBook.csv']),true);
[status,msg] = NSB_WriteGenericCSV(DataTable, fullfile(OutputDir,[OutputFile,'_Spectral_BioBook.csv']),true);
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
