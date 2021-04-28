function [DataStruct, status] = NSB_TXTreader(filename)
% NSB_TXTreader() - TXT reader
% 5529600.00000000	0.10498047
% relative seconds and mV?
%
% Input file names should conform to the standard:
% SubjectID_StartDate('mmddyyyy')_Group(and other comments).xxx

DataStruct = [];
status = false;
switch nargin
    case 0
        [filename,filepath] = uigetfile({'*.sag','Sage Text Data Format (*.sag)';...
            '*.opp','ICELUS Text Data Format (*.opp)';...
            '*.s2t','Spike2 Spreadsheet Text Format';...
            '*.*',  'All Files (*.*)'},'Select an TXT file...','*.*');
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
[trash,fName,EXT] = fileparts(filename);
fNameParts = regexp(fName,'_','split');

switch lower(EXT)
    case '.sag'
        data = dlmread(filename,'\t');
        
        %[trash,fName] = fileparts(filename);
        %fNameParts = regexp(fName,'_','split');
        
        DataStruct.Version = 1;
        DataStruct.SubjectID = fNameParts{1};
        try, DataStruct.Comment = ['Group: ',fNameParts{3}]; catch; DataStruct.Comment = ['Group: '];end
        try
            DataStruct.StartDate = datenum(fNameParts{2},'mmddyy'); 
        catch
            attr = dir(filename);
            DataStruct.StartDate = attr.datenum; %Use FileDate (only option left);
        end
        DataStruct.FileFormat = 'SageTXT';
        DataStruct.nRecords = [];
        DataStruct.nSeconds = data(end,1)-data(1,1);
        DataStruct.nChannels = 1;
        
        DataStruct.Channel.Name = 'EEG';
        DataStruct.Channel.ChNumber = 1;
        DataStruct.Channel.Units = 'mV';
        DataStruct.Channel.nSamples = size(data,1);
        DataStruct.Channel.Hz = 512;
        DataStruct.Channel.Data = data(:,2);
        DataStruct.Channel.ts = data(:,1);
        
    case '.s2t'
        %get header
        fid = fopen(filename);
        try
            header = fgetl(fid);
            header =  regexprep(header,'"','');
            header = regexp(header,',','split');
            fclose(fid);
        catch
            fclose(fid);
            status = false;
            return;
        end
        data = dlmread(filename,',',1,0);
        
        DataStruct.Version = 1;
        DataStruct.SubjectID = fNameParts{1};
        try, DataStruct.Comment = ['Group: ',fNameParts{3}];catch, DataStruct.Comment = ['Group: '];end
        try, DataStruct.StartDate = datenum(fNameParts{2},'mmddyy'); catch, DataStruct.StartDate = 0; end
        DataStruct.FileFormat = 'Spike2 Spreadsheet TXT';
        DataStruct.nRecords = [];
        DataStruct.nSeconds = data(end,1)-data(1,1);
        
        ChanCounter = 0;
        [nSamples, Channels]=size(data);
        Hz = 1/data(2,1) - data(1,1);
        DataStruct.nChannels = Channels-1;
        for curChan = 2:Channels
            ChanCounter = ChanCounter +1;
            DataStruct.Channel(ChanCounter).Name = header{curChan};
            DataStruct.Channel(ChanCounter).ChNumber = ChanCounter;
            DataStruct.Channel(ChanCounter).Units = 'mV';
            DataStruct.Channel(ChanCounter).nSamples = nSamples;
            DataStruct.Channel(ChanCounter).Hz = Hz;
            DataStruct.Channel(ChanCounter).Data = detrend(data(:,curChan)) * 1000;
            DataStruct.Channel(ChanCounter).ts = data(:,1);
        end
        
    case '.opp'
        %get header
        %contains tab seperated fields
        % 'Filename'  '06220911.EEG'  'Epoch size, sec'  '0' 'Gain' '1'  'x V-sec'
        %needs sampling frequency (current files are 128)
        %needs start time
        
        fid = fopen(filename);
        try
            header = fgetl(fid);
            header =  regexprep(header,'"','');
            header = regexp(header,char(9),'split');
            fclose(fid);
        catch
            fclose(fid);
            status = false;
            return;
        end
        data = dlmread(filename,',',1,0);
        %data = dlmread(filename,'\t');
        
        DataStruct.Version = 1;
        DataStruct.SubjectID = fNameParts{1};
        try, DataStruct.Comment = ['Group: ',fNameParts{3}];catch, DataStruct.Comment = ['Group: '];end
        
        %try, DataStruct.StartDate = datenum(fNameParts{2},'mmddyy'); catch, DataStruct.StartDate = 0; end
        try
            DataStruct.StartDate = datenum(fNameParts{2},'mmddyy'); 
        catch
            attr = dir(filename);
            DataStruct.StartDate = attr.datenum; %Use FileDate (only option left);
        end
        
        DataStruct.FileFormat = 'ICELUSTXT';
        DataStruct.nRecords = [];
        DataStruct.nSeconds = [];
        DataStruct.nChannels = 1;
        
        DataStruct.Channel.Name = 'EEG';
        DataStruct.Channel.ChNumber = 1;
        DataStruct.Channel.Units = 'V';
        DataStruct.Channel.nSamples = size(data,1);
        DataStruct.Channel.Hz = [];
        DataStruct.Channel.Data = data(:,2);
        DataStruct.Channel.ts = [];
        
    otherwise
        disp('data format not specified');
end

status = true;