function [status] = NSB_EDFwriter(DataStruct, filename, options)
% If we are to include Sleep stages, we should update this to EDF+ http://www.edfplus.info/specs/edfplus.html
%
%DMD 6/7/2017 Ok and validated

% Known issues, 
%1) if data is sampled REALLY slowly i.e. activity 1/20 seconds recordSamples
%maybe < 1 (non interger)
%2) no curent support for labels or other time stamps
%
%line 97 out of memory!


status = false;
if nargin < 3
        options.logfile = '';
        options.chans = [];
        options.progress = true;
end
    
%Create folder if non exists
[fnPath,fn,fnExt] = fileparts(filename);
if exist(fnPath,'dir') ~= 7
    mkdir(fnPath);
end

%Handle < 1Hz Channels
%This is certainly not the right solution but a hack to get it to work.
sub1HzIDX = find([DataStruct.Channel(:).Hz] < 1);
OneHzIDX = find([DataStruct.Channel(:).Hz] == 1);
for curIDX = sub1HzIDX
    if ~isempty(OneHzIDX)
        sampleSpacing = floor(length(DataStruct.Channel(OneHzIDX).Data)/length(DataStruct.Channel(curIDX).Data));
        data(1:sampleSpacing:length(DataStruct.Channel(curIDX).Data)*sampleSpacing) = DataStruct.Channel(curIDX).Data;
        if length(DataStruct.Channel(OneHzIDX).Data) > length(data)
            data = [data(:); zeros(length(DataStruct.Channel(OneHzIDX).Data)-length(data),1)];
        else
            data = data(1:length(DataStruct.Channel(OneHzIDX).Data));
            data = data(:);
        end
        DataStruct.Channel(curIDX).Data = data;
        DataStruct.Channel(curIDX).nSamples = length(data);
        DataStruct.Channel(curIDX).Hz = 1;
    else
        if isfield(DataStruct.Channel(curIDX),'ts')
            if length(NSB_uniqueDiffTS(DataStruct.Channel(curIDX).ts)) ~= 1
                %handle gaps in data
                %todo
                errorstr = ['Warning: NSB_EDFwriter >> ',DataStruct.Channel(curIDX).Name,' is not continuously sampled (missing data samples). Data may not be aligned in .edf!!'];
                disp(errorstr);
                if ~isempty(options.logfile)
                    status = NSBlog(options.logfile,errorstr);
                else
                    errordlg(errorstr,'NSB_EDFwriter');
                end
                
                
                sampleSpacing =  1/DataStruct.Channel(curIDX).Hz;
                data = zeros(DataStruct.nSeconds,1);
                data(1:sampleSpacing: sampleSpacing*DataStruct.Channel(curIDX).nSamples) = DataStruct.Channel(curIDX).Data;
                DataStruct.Channel(curIDX).Data = data;
                DataStruct.Channel(curIDX).nSamples = length(data);
                DataStruct.Channel(curIDX).Hz = 1;
                
            else
                sampleSpacing =  1/DataStruct.Channel(curIDX).Hz;
                data(1:sampleSpacing:DataStruct.nSeconds) = DataStruct.Channel(curIDX).Data(1:DataStruct.nSeconds/sampleSpacing); % This can fail if samples are dropped / not the same as high Hz data.
                data = data(:);
                DataStruct.Channel(curIDX).Data = data;
                DataStruct.Channel(curIDX).nSamples = length(data);
                DataStruct.Channel(curIDX).Hz = 1;
            end
        else
            sampleSpacing =  1/DataStruct.Channel(curIDX).Hz;
            data(1:sampleSpacing:DataStruct.nSeconds) = DataStruct.Channel(curIDX).Data(1:DataStruct.nSeconds/sampleSpacing); % This can fail if samples are dropped / not the same as high Hz data.
            data = data(:);
            DataStruct.Channel(curIDX).Data = data;
            DataStruct.Channel(curIDX).nSamples = length(data);
            DataStruct.Channel(curIDX).Hz = 1;
        end
    end
end
% -OR- change spec to edf+/bdf

    
%Gather some File data
% RecSize = roundn(61440/(sum([DataStruct.Channel(:).Hz])*2),1);
% if RecSize > floor(61440/(sum([DataStruct.Channel(:).Hz])*2))
%     RecSize = RecSize-10;
% end
% nRecords = ceil(DataStruct.nSeconds/RecSize); %Last record could be unfilled !!!

%calculate Data record Durations
%In EDF(+), data record Durations are specified in an 8-character string, for instance 0.123456 or 1234567
%In one datarecord, maximum 61440 bytes are available for all signals (including the Annotation signal).
% encoded as int16 so 61440/2 values avalvble.
AvalBytes = 61440 / 2;
MaxDuration = str2double(sprintf('%8f',AvalBytes/ sum(ceil([DataStruct.Channel(:).Hz]))));
MaxDuration = round(MaxDuration,-1);
SampDurs = 0.000001:0.000001:MaxDuration;
relativeError = mod(SampDurs * min([DataStruct.Channel(:).Hz]),1)/ min([DataStruct.Channel(:).Hz]);
RecSize = single(SampDurs(find(relativeError == min(relativeError),1,'last'))); %duration in seconds as single to deal with eps issue

nRecords = ceil(DataStruct.nSeconds/RecSize); %Last record could be unfilled !!!
%check this for validity because some data (DSI) does not report this
%accurately?
for curChan = 1:DataStruct.nChannels
    nRecord(curChan) = length(DataStruct.Channel(curChan).Data) / DataStruct.Channel(curChan).Hz /RecSize;
end
if nRecords <= max(nRecord)
    errorstr = 'Warning: NSB_EDFwriter >> Reported file duration does not equal samples recorded. Using file data to determine duration.';
    if ~isempty(options.logfile)
        status = NSBlog(options.logfile,errorstr);
    else
        errordlg(errorstr,'NSB_EDFwriter');
    end
    nRecords = ceil(max(nRecord));
end

try
fid = fopen(filename,'w+','ieee-le'); %use W for no flush & faster write
    if fid < 0
        DataStruct = [];
        errorstr = ['ERROR: NSB_EDFwriter >> Cannot open: ',filename];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_EDFwriter');
        end
        fclose(fid);
        return;
    end
    
pos = fseek(fid,0,'bof');

%% Write EDF Header
%Version
element = char(num2str(0), sprintf('%8s',' ')); element = element(1,:);
nElements = fwrite(fid, element, 'char');
%Patient ID
if isfield(DataStruct,'SubjectID') && isfield(DataStruct.Channel(1),'MatrixLoc')
    element = [DataStruct.SubjectID,' X X ',DataStruct.Channel(1).MatrixLoc]; 
    element(80:end) = []; %truncate to 80 char
elseif isfield(DataStruct,'SubjectID')
    element = DataStruct.SubjectID; 
    element(74:end) = []; %truncate to 80 char
    element = [element, ' X X X'];
else
    element = 'X X X X';
end
element = char(element, sprintf('%80s',' ')); element = element(1,:);
nElements = fwrite(fid, element, 'char');
%REcording ID
if isfield(DataStruct,'VersionName')
    element = DataStruct.VersionName; element(80:end) = []; %truncate to 80 char
elseif isfield(DataStruct,'Comment')
    element = DataStruct.Comment; element(80:end) = []; %truncate to 80 char
else
    element = '';
end
element = char(element, sprintf('%80s',' ')); element = element(1,:);
nElements = fwrite(fid, element, 'char');
%startdate (dd.mm.yy) 
nElements = fwrite(fid, datestr(DataStruct.StartDate, 'dd.mm.yy'), 'char'); 
%starttime (hh.mm.ss) 
nElements = fwrite(fid, datestr(DataStruct.StartDate, 'HH.MM.SS'), 'char'); 
%number of bytes in header record
element = char(num2str(256+256*DataStruct.nChannels), sprintf('%8s',' ')); element = element(1,:);
nElements = fwrite(fid, element, 'char');
%44 ascii : reserved 
element = char( sprintf('%44s',' ')); element = element(1,:);
nElements = fwrite(fid, element, 'char');
%number of Data Records 
element = char(num2str(nRecords), sprintf('%8s',' ')); element = element(1,:);
nElements = fwrite(fid, element, 'char');
%Duration of Data RECORD
element = char(num2str(RecSize), sprintf('%8s',' ')); element = element(1,:);
nElements = fwrite(fid, element, 'char');
%Num Channels
element = char(num2str(DataStruct.nChannels), sprintf('%4s',' ')); element = element(1,:); 
nElements = fwrite(fid, element, 'char');

%% Write EDF Channel Headers
%calculate Channel scaling factor to int
for curChan = 1:DataStruct.nChannels
    %gain(curChan) = min( (32767 /max(DataStruct.Channel(curChan).Data) ), (-32767 / min(DataStruct.Channel(curChan).Data) ) );
    PhysMax(curChan) = ceil (max( abs(max(DataStruct.Channel(curChan).Data)) , abs(min(DataStruct.Channel(curChan).Data)) ));
    gain(curChan) = 32767 / PhysMax(curChan);
    DCoffset(curChan) = 0;
%    gain(curChan) = (PhysicalMax(curChan) - PhysicalMin(curChan)) / (32767 - -32767);
%    DCoffset(curChan) = PhysicalMin(curChan) - (gain(curChan) * -32767);
end


%Label
for curChan = 1:DataStruct.nChannels
element = DataStruct.Channel(curChan).Name; element(16:end) = []; %truncate to 16 char
element = char(element, sprintf('%16s',' ')); element = element(1,:); 
nElements = fwrite(fid, element, 'char');
end

%Transducer %This should be the unit like D70-EEE
for curChan = 1:DataStruct.nChannels
element = char(sprintf('%80s',' ')); element = element(1,:); 
nElements = fwrite(fid, element, 'char');
end

%Physical Dimension
for curChan = 1:DataStruct.nChannels
element = DataStruct.Channel(curChan).Units; element(8:end) = []; %truncate to 80 char
element = char(element, sprintf('%8s',' ')); element = element(1,:); 
nElements = fwrite(fid, element, 'char');
end

%Physical min
for curChan = 1:DataStruct.nChannels
%PhysicalMin(curChan) = min(DataStruct.Channel(curChan).Data);
PhysicalMin(curChan) = -PhysMax(curChan);
element = char(num2str(PhysicalMin(curChan)), sprintf('%8s',' ')); element = element(1,1:8); %force truncation here since MatLAb doesnt thingk (-) is a character
nElements = fwrite(fid, element, 'char');
end
%Physical Max
for curChan = 1:DataStruct.nChannels
%PhysicalMax(curChan) = max(DataStruct.Channel(curChan).Data);
PhysicalMax(curChan) = PhysMax(curChan);
element = char(num2str(PhysicalMax(curChan)), sprintf('%8s',' ')); element = element(1,1:8); %force truncation here since MatLAb doesnt thingk (-) is a character
nElements = fwrite(fid, element, 'char');
end
%Dig Min int 16 = -32768
for curChan = 1:DataStruct.nChannels
element = char(num2str(-32767), sprintf('%8s',' ')); element = element(1,1:8); %force truncation here since MatLAb doesnt thingk (-) is a character
nElements = fwrite(fid, element, 'char');
end
%Dig Max
for curChan = 1:DataStruct.nChannels
element = char(num2str(32767), sprintf('%8s',' ')); element = element(1,1:8); %force truncation here since MatLAb doesnt thingk (-) is a character
nElements = fwrite(fid, element, 'char');
end

%Prefiltering
for curChan = 1:DataStruct.nChannels
element = char(sprintf('%80s',' ')); element = element(1,:); 
nElements = fwrite(fid, element, 'char');
end
%samples per record
for curChan = 1:DataStruct.nChannels
recordSamples(curChan) = DataStruct.Channel(curChan).Hz*RecSize;
element = char(num2str(recordSamples(curChan)), sprintf('%8s',' ')); element = element(1,:); 
nElements = fwrite(fid, element, 'char');
end

%reserved
for curChan = 1:DataStruct.nChannels
element = char(sprintf('%32s',' ')); element = element(1,:); 
nElements = fwrite(fid, element, 'char');
end

%% Write EDF Data
% note: watch out for incomplete final frame
if options.progress, h = waitbar(0,'Saving Record 0 ...','Name','Writing EDF...'); end
recordSamples = double(recordSamples); %Cast as double for future calculations
recSampleStart = ones(DataStruct.nChannels,1);
recSampleEnd = recordSamples;

%loop through each record
for curRecord = 1:nRecords
    if options.progress, waitbar(curRecord/nRecords,h,['Saving Record ',num2str(curRecord),' ...']); end
    %loop through each channel
    for curChan = 1:DataStruct.nChannels
        if recSampleEnd(curChan) <= length(DataStruct.Channel(curChan).Data)
            writeData = DataStruct.Channel(curChan).Data(recSampleStart(curChan):recSampleEnd(curChan));
        else
            writeData = DataStruct.Channel(curChan).Data(recSampleStart(curChan):end);
            buffer = zeros(recSampleEnd(curChan) - (recSampleStart(curChan) -1) - length(writeData) ,1);
            writeData = [writeData; buffer];
        end
        %Handle beg/end of segment differently for each channel since they are likely different
        %writeData = DataStruct.Channel(curChan).Data(recSampleStart(curChan):recSampleEnd(curChan));
        %scale data as interger
        %writeData =  writeData / (PhysicalMax(curChan) - PhysicalMin(curChan)) / (32767 - -32768);

        writeData =  writeData * gain(curChan) + DCoffset(curChan);
        nElements = fwrite(fid, writeData, 'int16');
        if nElements ~= DataStruct.Channel(curChan).Hz * RecSize
            fprintf(2, 'Bad num elements written. Record %i Chan %i NumElements %i\n',curRecord,curChan, nElements);
            
        end
        
        %voltage (i.e. signal) in the file by definition equals [(physical miniumum) + (digital value in the data record - digital minimum) x (physical maximum - physical minimum) / (digital maximum - digital minimum)]. 
        %update file positions
        recSampleStart(curChan) = recSampleStart(curChan) + recordSamples(curChan);
        recSampleEnd(curChan) = recSampleEnd(curChan) + recordSamples(curChan);
    end
end

fclose(fid);
try, close(h); end
status = true;

catch ME
        errorstr = ['ERROR: NSB_EDFwriter >> ',ME.message];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_EDFwriter');
        end
        fclose(fid);
        try, close(h); end
        return;
    
end

