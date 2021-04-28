function [DataStruct, status, msg] = NSB_OPPreader(path,SubjectID,options)
% multiple files in a directory
% File Naming Spec is MMDDHH[ID].txt with .opp extension


% Read Like DSI.
%NSB_DSIreader(path,SubjectID,options)

% Check for Metadata .xml
%.SampleRate
%.Channel.ID
%.Channel.Gain
%.Channel.loPass
%.Channel.highPass

%1) search Dir to find animal ID matches
%2) sort by date and Recording start time (HH)

%3) Read each channel for each time file
%4) Add zeros byuffer between file(S)

%list = fuf('F:\MARS\Praxis\Data\24May2017\Chan-1',0,'detail');
%for curfile = 1:length(list), dos(['move ',list{curfile},' ',[list{curfile}(1:end-3),'opp']],'-echo'); end

if nargin < 3
    options.logfile = '';
    options.progress = true;
    options.parallel = false;
end

status = false;
DataStruct = [];
existParameterFile = false;
MaxChannels = 10; %Max channels that system would ever output E0-E9
DefaultSampleRate = 512; %Hz

%% Begin opening files
filelist = fuf(path,0,'detail');
[~,filenames,ext] = cellfun(@fileparts,filelist,'UniformOutput', false);

%check for metadata
if exist(fullfile(path,'OppMetaData.xml'),'file') ~= 0
    Parameters = tinyxml2_wrap('load', fullfile(path,'OppMetaData.xml') );
    existParameterFile = true;
end

[FileStartDate, ID, Ch] = cellfun(@NSB_parseOppFilename, filenames, 'UniformOutput', false);
Chans = unique(Ch);

%Begin Building DataStruct
DataStruct.Version = 1.0;
DataStruct.SubjectID = SubjectID;
DataStruct.Comment = '';
DataStruct.StartDate = [];
DataStruct.FileFormat = '.opp.';
if existParameterFile, DataStruct.Hz = Parameters.SampleRate; else, DataStruct.Hz = DefaultSampleRate; end
DataStruct.nSeconds = [];
DataStruct.nChannels = length(Chans);
DataStruct.Filename = '';

%1) search Dir to find animal ID matches
SubjectID_IDX = strcmp(ID,SubjectID); %<< this should work but may not be back compatible with 2010a
if nnz(SubjectID_IDX) == 0   %mayba a number
    tempSubjectID = regexp(SubjectID,'\d*','match');
    tempSubjectID = tempSubjectID{:};
    SubjectID_IDX = strcmp(ID,tempSubjectID);
end

if nnz(SubjectID_IDX) == 0
    %err - no aminal ID matches.
    %return
end


if options.progress
    options.hWaitbar = waitbar(0,'Importing Channel ... ','Name',['Subject ID: ',SubjectID]);
end

% Theretically you could just sort file names:
%1) search Chan to find animal ID matches
for curChan = 1:length(Chans)
    SubjectFilenames = filenames(SubjectID_IDX);
    SubjectFileStartDate = FileStartDate(SubjectID_IDX);
    SubjectCh = Ch(SubjectID_IDX);
    
    Ch_IDX = strcmp(SubjectCh,Chans(curChan));
    ChSubjectFilenames = SubjectFilenames(Ch_IDX);
    ChSubjectFileStartDate = SubjectFileStartDate(Ch_IDX);
    
    %2) sort by date and Recording start time (HH)
    [~,DateOrder] = sort([ChSubjectFileStartDate{:}]);
    
    %update DataStruct
    if curChan == 1
        DataStruct.StartDate = ChSubjectFileStartDate{DateOrder(curChan)};
    end
    
    %3) Read each channel for each time file
    %4) Add zeros buffer between file(S)
    
    for curFile = 1:length(ChSubjectFilenames)
        
        if options.progress
            waitbar(curFile/length(ChSubjectFilenames),options.hWaitbar,['Importing Channel ... ',Chans(curChan)]);
        end
        if existParameterFile
            %return a concatinated Channnel
            logstr = ['NSB_OPPreader >> Reading Data File - ',fullfile(path, [ChSubjectFilenames{DateOrder(curFile)}, '.opp'] )];
            disp(logstr);
            logstatus = NSBlog(options.logfile,logstr);
        end
        
        [HDR, DATA, fOpenStatus, msg] = readOppFile(fullfile(path, [ChSubjectFilenames{DateOrder(curFile)}, '.opp'] ));
        if fOpenStatus
            logstr = ['NSB_OPPreader >> Read Success - ',HDR];
        else
            logstr = ['ERROR: NSB_OPPreader >> Cannot read SubjectID ', SubjectID, ME.message];
        end
        if ~isempty(options.logfile)
            logstatus = NSBlog(options.logfile,logstr);
        end
        
        %Read in Parameter channel and GLM INfo
        
        %validate HDR
        %for now assume that files are contiguous !!!!!
        
        if curFile == 1
            DataStruct.Channel(curChan).Name = strtrim(Chans{curChan});
            DataStruct.Channel(curChan).ChNumber = curChan;
            DataStruct.Channel(curChan).Units = HDR{7};
            DataStruct.Channel(curChan).nSamples = [];
            DataStruct.Channel(curChan).Hz = DataStruct.Hz;
            DataStruct.Channel(curChan).Data = DATA; %rowvec
            DataStruct.Filename = fullfile(path, [ChSubjectFilenames{DateOrder(curFile)}, '.opp'] );
        else
            DataStruct.Channel(curChan).Data = [DataStruct.Channel(curChan).Data; DATA];
            
            %here test for gap
            
        end
        DataStruct.Channel(curChan).nSamples = size(DataStruct.Channel(curChan).Data,1);
    end
    %update DataStruct
    if curChan == 1, DataStruct.nSeconds = DataStruct.Channel(curChan).nSamples/DataStruct.Hz; end
    
    
end
if options.progress
    try, close(options.hWaitbar); end
end
status = true;

function [HDR, DATA, status, msg] = readOppFile(filename)
status = false;HDR = [];DATA = [];msg = '';
FID = fopen(filename);
try
    HDR = fgetl(FID);
    HDR = regexp(HDR,'\t','split');
    DATA = textscan(FID,'%f');
    DATA = DATA{:};
    fclose(FID);
    status = true;
catch ME
    try, fclose(FID); end
    error(ME.message);
    msg = ME.message;
end







