function [DataStruct, status] = NSB_EDFreader(filename,options)
% NSB_EDFreader() - EDF and EDF+ reader
%
% Inputs:
%   filename          - (string) Path+FileName of Existing file
%   options           - (struct) of options
%                           options.logfile
%                           options.chans
%                           options.progress
%
% Outputs:
%   DataStruct          - (struct) NSB DataStructure
%   status              - (logical) return value
%
% See also:
%   http://www.edfplus.info/specs/edfplus.html
%
% Dependencies: 
% NSBlog
%
% Validated. Same read as Spike 2 and NeuroScore
% 
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0
% Feb 21 2012, Version 1.1 Fix for nRecords
% ToDo: add edf+ spec


status = false;
switch nargin
    case 0
        [filename,filepath] = uigetfile({'*.rec;*.edf','European Data Format (*.edf,*.rec)';},'Select an EDF file...');
        filename = fullfile(filepath,filename);
        options.logfile = '';
        options.chans = [];
        options.progress = true;
    case 1
        options.logfile = '';
        options.chans = [];
        options.progress = true;
        %set default options
        %log file
        %chan read vector
        %progress Bar
    case 2
        %check otptions
end
if exist(filename,'file') ~= 2
    DataStruct = [];
    errorstr = ['ERROR: NSB_EDFreader >> File does not exist: ',filename];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_EDFreader');
        end
    return;
end

try
    fid = fopen(filename,'r');
    if fid < 0
        DataStruct = [];
        errorstr = ['ERROR: NSB_EDFreader >> Cannot open: ',filename];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_EDFreader');
        end
        fclose(fid);
        return;
    end

pos = fseek(fid,0,'bof');
%% Read EDF Header
DataStruct.Version = str2double(char(fread(fid, 8, 'char')'));
DataStruct.SubjectID = strtrim(char(fread(fid,80,'char')'));
%Later the SubjectID will be used to write a file name and cannot contain
% '\' or :\ in it
%if it contains "tanks in it" 
%edit in
%illegalCharsPat = ['(\',filesep,'|[:\',filesep,'])'];
illegalCharsPat = ['(\',filesep,')|(:\',filesep,')'];
DataStruct.SubjectID = regexprep(DataStruct.SubjectID, illegalCharsPat, '-');
DataStruct.SubjectID = regexprep(DataStruct.SubjectID, '[<>:|?*_]', '');

%this can be further parsed into
% 1) Subject Code, 2) gender, 3) birthdate in dd-MMM-yyyy, 4) Subject Name, 5) other Subfields
DataStruct.Comment = strtrim(char(fread(fid,80,'char')'));
%this can be further parsed into
% 1) text 'Startdate', 2) dd-MMM-yyyy, 3) administration code UID, 4) technician, 5) equipment used
 StartDate = char(fread(fid,8,'char')'); %post 2084 the year will contain "yy"
 StartTime = char(fread(fid,8,'char')');
DataStruct.StartDate = datenum([StartDate,'.',StartTime],'dd.mm.yy.HH.MM.SS');
DataStruct.HeaderLength = str2double(char(fread(fid,8,'char')'));
FileFormat = strtrim(char(fread(fid,44,'char')'));
if isempty(FileFormat)
    DataStruct.FileFormat = '.edf';
else
    DataStruct.FileFormat = FileFormat; %This would indicate EDF+
end
DataStruct.nRecords = str2double(char(fread(fid, 8, 'char')'));% how many data records
DataStruct.RecordnSeconds = str2double(char(fread(fid, 8, 'char')'));%length of each record (sec)
DataStruct.nSeconds = DataStruct.RecordnSeconds * DataStruct.nRecords; %total length
DataStruct.nChannels = str2double(char(fread(fid, 4, 'char')'));

%For each channel populate subheader
%get Channel Names
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).Name = strtrim(char(fread(fid,16,'char')'));
    DataStruct.Channel(curCell,1).Name = regexprep(DataStruct.Channel(curCell,1).Name, '_', '-'); %Do not allow underscores!
end
%Generate Channel Number
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).ChNumber = curCell; 
end
%get electrodetype
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).Transducer = strtrim(char(fread(fid,80,'char')')); 
end
%get dimension label
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).Units = strtrim(char(fread(fid,8,'char')')); 
end
%get phys Min
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).PhysMin = str2double(char(fread(fid, 8, 'char')'));
end
%get phys Max
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).PhysMax = str2double(char(fread(fid, 8, 'char')'));
end
%get dig Min
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).DigMin = str2double(char(fread(fid, 8, 'char')'));
end
%get dig Max
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).DigMax = str2double(char(fread(fid, 8, 'char')'));
end
%get pre-Filtering
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).PreFilter = strtrim(char(fread(fid,80,'char')')); 
end
%get nSamples
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).RecordnSamples = str2double(char(fread(fid, 8, 'char')'));%SamplesPer Record
end
%Calculate Hz
for curCell = 1:DataStruct.nChannels
    DataStruct.Channel(curCell,1).Hz = DataStruct.Channel(curCell,1).RecordnSamples/DataStruct.RecordnSeconds;
end

%jump to data area
pos = fseek(fid,DataStruct.HeaderLength,'bof');

%% Read EDF Data
if options.progress, h = waitbar(0,'Loading Channel 0 ...'); end

for curRecord = 1:DataStruct.nRecords
    if options.progress, waitbar(curRecord/DataStruct.nRecords,h,['Loading Record ',num2str(curRecord),' ...']); end
    for curCell = 1:DataStruct.nChannels
    channel(curCell).record(curRecord).data = fread(fid, DataStruct.Channel(curCell).RecordnSamples, 'int16');
    channel(curCell).record(curRecord).data = DataStruct.Channel(curCell,1).PhysMin + ...
        (channel(curCell).record(curRecord).data - DataStruct.Channel(curCell,1).DigMin) * ...
        (DataStruct.Channel(curCell,1).PhysMax - DataStruct.Channel(curCell,1).PhysMin)/(DataStruct.Channel(curCell,1).DigMax - DataStruct.Channel(curCell,1).DigMin); 
    %voltage (i.e. signal) in the file by definition equals [(physical miniumum) + (digital value in the data record - digital minimum) x (physical maximum - physical minimum) / (digital maximum - digital minimum)]. 
    end
end
for curCell = 1:DataStruct.nChannels 
    DataStruct.Channel(curCell,1).Data = vertcat(channel(curCell).record.data);
    %subtract off mean
    DataStruct.Channel(curCell,1).Data = DataStruct.Channel(curCell,1).Data-mean(DataStruct.Channel(curCell,1).Data);
end
%old loop (for posterity) 
% for curCell = 1:DataStruct.nChannels
%     if options.progress, waitbar(curCell/DataStruct.nChannels,h,['Loading Channel ',num2str(curCell),' ...']); end
%     data = fread(fid, DataStruct.Channel(curCell).nSamples, 'int16');
%     DataStruct.Channel(curCell,1).Data = DataStruct.Channel(curCell,1).PhysMin + ...
%         (data - DataStruct.Channel(curCell,1).DigMin) * ...
%         (DataStruct.Channel(curCell,1).PhysMax - DataStruct.Channel(curCell,1).PhysMin)/(DataStruct.Channel(curCell,1).DigMax - DataStruct.Channel(curCell,1).DigMin); 
%     %voltage (i.e. signal) in the file by definition equals [(physical miniumum) + (digital value in the data record - digital minimum) x (physical maximum - physical minimum) / (digital maximum - digital minimum)]. 
% end
close(h)

catch ME
        errorstr = ['ERROR: NSB_EDFreader >> ',ME.message];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_EDFreader');
        end
        fclose(fid);
        return;
    
end
fclose(fid);
status = true;
