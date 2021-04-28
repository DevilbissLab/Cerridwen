function [DataStruct, status] = NSB_FIFreader(filename,options)
% NSB_FIFreader - FIFF filetype reader (Elekta Neuromag Functional Image File Format)
%
% Important: Requires NSB_DSILicenseFile.mat Licence key
%
% Inputs:
%   filename           - (string) Path+Filename of file to open
%   options            - (struct) of options
%                           options.logfile - (string) name of logfile
%                           options.chans - (string) channel type to import
%                               {'EEG','MEG','ALL','')
%                           options.progress - (logical) show progressbar
%
% Outputs:
%   DataStruct          - (struct) NSB DataStructure
%   status              - (logical) return value
%
% Dependencies: 
% NSBlog, NSB_FIFFbuildBlockStruct, NSB_FIFFdataTypeDefinitions, NSB_FIFFgetCurTag
% NSB_FIFFgetTagData, NSB_FIFFtagLookup, NSB_FIFreadTagDir
%
% Validated. Same read as NME fiff_setup_read_raw + fiff_read_raw_segment
%
% Known issues:
% 1) timestamps for data (ts vector) not created
% 2) Bad Channels are not detected
% 3) Some fields are not extracted including filtering
% 4) cannot handle data across multiple files
% 5) DataTable is not preallocated (slow)
% 6) Channel names are useless "EEG001"
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% Feb 10 2013, Version 1.0

status = false;
switch nargin
    case 0
        [filename,filepath] = uigetfile({'*.fif','ELEKTA FIF Format (*.fif,*.rec)';},'Select a .fif file...');
        filename = fullfile(filepath,filename);
        options.logfile = '';
        options.chans = '';
        options.progress = true;
    case 1
        options.logfile = '';
        options.chans = '';
        options.progress = true;
end
if exist(filename,'file') ~= 2
    DataStruct = [];
    errorstr = ['ERROR: NSB_FIFreader >> File does not exist: ',filename];
    if ~isempty(options.logfile)
        status = NSBlog(options.logfile,errorstr);
    else
        errordlg(errorstr,'NSB_FIFreader');
    end
    return;
end

FIFFdef = NSB_FIFFdataTypeDefinitions();
try
    fid = fopen(filename,'r','ieee-be');
    if fid < 0
        DataStruct = [];
        errorstr = ['ERROR: NSB_FIFreader >> Cannot open: ',filename];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_FIFreader');
        end
        fclose(fid);
        return;
    end
    
    fpos = fseek(fid,0,'bof');
    [TagDir,FIFF_HDR] = NSB_FIFreadTagDir(fid,options); %Get ray tag directory
    BlockStruct = NSB_FIFFbuildBlockStruct(TagDir, fid); %Build the Block structure
    
    %% Populate experimental and Subject information
    %file format version
    DataStruct.Version = str2double([num2str(FIFF_HDR.version(1)),'.',num2str(FIFF_HDR.version(2))]);
    %recording date (this is a hack and FIFF dosnt guarantee these data
    DataStruct.StartDate = datestr(datenum([0 0 0 0 0 FIFF_HDR.time_sec])+datenum('01-Jan-1970 00:00:00'));
        
    %Find Subject Block
    FirstName = '';
    MidName = '';
    LastName = '';
    BlockIDs = cell2mat({BlockStruct(:).BlockID});
    
    SubBlock = find(BlockIDs == FIFFdef.block.subject);
    for curTag = BlockStruct(SubBlock).TagIDXs
        [data,fpos,status] = NSB_FIFFgetTagData(fid,TagDir(curTag));
        switch data.kind %Tag ID
            case FIFFdef.tag.subj_id
                DataStruct.SubjectUID = num2str(data.data);
            case FIFFdef.tag.subj_first_name
                FirstName = data.data;
            case FIFFdef.tag.subj_middle_name
                MidName = data.data;
            case FIFFdef.tag.subj_last_name
                LastName = data.data;
            case FIFFdef.tag.subj_birth_day
                DataStruct.BirthDate = num2str(data.data);  %broken: This is a Julian date
            case FIFFdef.tag.subj_sex
                DataStruct.Gender = data.data; %this is enumerated
            case FIFFdef.tag.subj_hand
                DataStruct.Handed = data.data; %this is enumerated
            case FIFFdef.tag.subj_weight
                DataStruct.Weight = data.data;
            case FIFFdef.tag.subj_height
                DataStruct.Height = data.data;
            case FIFFdef.tag.subj_comment
                DataStruct.Comment = data.data;
            case FIFFdef.tag.subj_his_id
                DataStruct.HospID = data.data;
        end
    end
    DataStruct.SubjectName = strtrim([LastName,', ',FirstName,' ',MidName]);
    DataStruct.FileFormat = '.fif';
    DataStruct.FileName = filename;
    [trash1, name, trash2] = fileparts(DataStruct.FileName); 
    DataStruct.SubjectID = strcat(regexprep(DataStruct.SubjectName, '\W*', ','),',',name);
    DataStruct.nRecords = [];
    
    %Validate Manditory Fields for NSB Struct
    if ~isfield(DataStruct,'Version'), DataStruct.Version = []; end;
    if ~isfield(DataStruct,'SubjectID'), DataStruct.SubjectID = ''; end;
    if ~isfield(DataStruct,'Comment'), DataStruct.Comment = ''; end;
    
    %Find Measurement Info Block
    SubBlock = find(BlockIDs == FIFFdef.block.meas_info);
    for curTag = BlockStruct(SubBlock).TagIDXs
        [data,fpos,status] = NSB_FIFFgetTagData(fid,TagDir(curTag));
        switch data.kind %Tag ID
            case FIFFdef.tag.nchan
                DataStruct.nChannels = data.data;
            case FIFFdef.tag.sfreq
                DataStruct.Hz = data.data;
            case FIFFdef.tag.meas_date %unix Date format
                %There is a second number here but undefined....
                DataStruct.StartDate = datestr(datenum([0 0 0 0 0 double(data.data(1))])+datenum('01-Jan-1970 00:00:00'));
            case FIFFdef.tag.bad_chs
                disp('bad channel data found in block.meas_info');
            case FIFFdef.tag.coord_trans
                disp('coord_trans data found in block.meas_info');
                
        end
    end
    %This has to be done in a seperate loop because you need to make sure you
    %have the Hz and other information 1st
    ChCounter = 0;
    for curTag = BlockStruct(SubBlock).TagIDXs
        [data,fpos,status] = NSB_FIFFgetTagData(fid,TagDir(curTag));
        switch data.kind %Tag ID
            case FIFFdef.tag.ch_info
                ChCounter = ChCounter +1;
                DataStruct.Channel(ChCounter).Name = data.data.ch_name;
                DataStruct.Channel(ChCounter).ChNumber = data.data.Channel;
                DataStruct.Channel(ChCounter).Type = NSB_FIFFtagLookup(data.data.ChannelType,'ch_type');
                DataStruct.Channel(ChCounter).Units = NSB_FIFFtagLookup(data.data.unit,'units');
                DataStruct.Channel(ChCounter).nSamples = [];
                DataStruct.Channel(ChCounter).Hz = DataStruct.Hz;
                DataStruct.Channel(ChCounter).Data = [];
                DataStruct.Channel(ChCounter).Tag = data.data;
        end
    end
    
    %Get 3D coordinates if avalable (this is different than data in .Tag
    ChCounter = 0;
    SubBlock = find(BlockIDs == FIFFdef.block.isotrak);
    for curTag = BlockStruct(SubBlock).TagIDXs
        [data,fpos,status] = NSB_FIFFgetTagData(fid,TagDir(curTag));
        if data.kind == FIFFdef.tag.dig_point
            switch data.type %Tag ID
                case FIFFdef.dig_point_struct
                    ChCounter = ChCounter +1;
                    DataStruct.Coord3D(ChCounter) = data.data;
            end
        end
    end
    
    %Get calibration info
    % Get Events ?
    %Determine MaxShield?
    
    %% Create data table and deal to channels.
    % data can be in one of several blocks
    MaxShield = false;
    SubBlock = find(BlockIDs == FIFFdef.block.raw_data);
    if isempty(SubBlock)
        SubBlock = find(BlockIDs == FIFFdef.block.continuous_data);
        if isempty(SubBlock)
            SubBlock = find(BlockIDs == FIFFdef.block.maxshield_raw_data);
            MaxShield = true;
            errorstr = ['ERROR: NSB_FIFreader >> MaxShield active shielding used. MaxFilter unavalable and data may be distorted. ',filename];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_FIFreader');
            end
        else
            errorstr = ['ERROR: NSB_FIFreader >> File does not contain readable raw data: ',filename];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_FIFreader');
            end
        end
    end
    %we can now fill in nRecords
    DataStruct.nRecords = length(BlockStruct(SubBlock).TagIDXs);
    
    %read samples and data This could get retardedly big so may want to cull by
    %only adding EEG variables??
    TagCounter = 0;
    curSample = 0;
    SkippedBuffers = false;
    DataTable = [];
    if options.progress
        options.hWaitbar = waitbar(0,'Current Record = ','Name','Importing Data ... ');
    end
    for curTag = BlockStruct(SubBlock).TagIDXs
        [data,fpos,status] = NSB_FIFFgetTagData(fid,TagDir(curTag));
        if data.kind == FIFFdef.tag.block_start;
            continue; %Because we always include the block header
        end
        
        TagCounter = TagCounter +1;
        if options.progress
            waitbar(TagCounter/length(BlockStruct(SubBlock).TagIDXs),options.hWaitbar,['Current Record = ',num2str(TagCounter)]);
        end
        if TagCounter == 1
            %Check for 1st sample tag
            if data.kind == FIFFdef.tag.first_sample
                DataStruct.FirstSample = data.data;
                %Check for Skiped data
            elseif data.kind == FIFFdef.tag.data_skip
                SkippedBuffers = data.data;
            elseif data.kind == FIFFdef.tag.data_buffer
                %get samples/buffer
                RecordSamples = getRecordnSamples(data.type,data.size,DataStruct.nChannels,FIFFdef);
                DataTable = double(reshape(data.data,DataStruct.nChannels,RecordSamples))'; %chan in cols
                DataStruct.Channel(ChCounter).nSamples(TagCounter) = RecordSamples;
                SkippedBuffers = false;
            else
                errorstr = ['ERROR: NSB_FIFreader >> Unprocessed 1st data segment with tag: ',num2str(data.type)];
                if ~isempty(options.logfile)
                    status = NSBlog(options.logfile,errorstr);
                else
                    errordlg(errorstr,'NSB_FIFreader');
                end
            end
        else
        
        %Now processes the rest tof the file
        if data.kind == FIFFdef.tag.data_skip
            %there could be multiple skips
            SkippedBuffers = SkippedBuffers + data.data;
        elseif data.kind == FIFFdef.tag.data_buffer
            if SkippedBuffers ~= false %this means that ther are skipped bufers pending
                %buffer with zeros
                RecordSamples = getRecordnSamples(data.type,data.size,DataStruct.nChannels,FIFFdef);
                if ~isempty(DataTable)
                    DataTable = [DataTable; NaN(RecordSamples * SkippedBuffers,DataStruct.nChannels)]; %insert NaN buffer
                    DataTable = [DataTable; double(reshape(data.data,DataStruct.nChannels,RecordSamples))']; %chan in cols
                    DataStruct.Channel(ChCounter).nSamples(TagCounter) = RecordSamples;
                    SkippedBuffers = false;
                else
                    DataTable = NaN(RecordSamples * SkippedBuffers,DataStruct.nChannels); %Start with NaN buffer
                    DataTable = [DataTable; double(reshape(data.data,DataStruct.nChannels,RecordSamples))']; %chan in cols
                    DataStruct.Channel(ChCounter).nSamples(TagCounter) = RecordSamples;
                    SkippedBuffers = false;
                end
            else
                RecordSamples = getRecordnSamples(data.type,data.size,DataStruct.nChannels,FIFFdef);
                DataTable = [DataTable; double(reshape(data.data,DataStruct.nChannels,RecordSamples))']; %chan in cols
                DataStruct.Channel(ChCounter).nSamples(TagCounter) = RecordSamples;
                SkippedBuffers = false;
            end
        end
        end
    end
    close(options.hWaitbar);
    fclose(fid);
    
    %Deal Data table to Struct
    %If there is a projection then the compensation needs to be handled
    %differently
    for ChCounter = size(DataTable,2):-1:1 %this is done in reverse because you are triming off bad channels
        switch lower(options.chans)
            case {'','all'}
                Calibration = DataStruct.Channel(ChCounter).Tag.range * DataStruct.Channel(ChCounter).Tag.cal;
                DataStruct.Channel(ChCounter).Data = DataTable(:,ChCounter) * Calibration;
                DataStruct.Channel(ChCounter).nSamples = length(DataStruct.Channel(ChCounter).Data);
            otherwise
                if strcmpi(DataStruct.Channel(ChCounter).Type,options.chans)
                    Calibration = DataStruct.Channel(ChCounter).Tag.range * DataStruct.Channel(ChCounter).Tag.cal;
                    DataStruct.Channel(ChCounter).Data = DataTable(:,ChCounter) * Calibration;
                    DataStruct.Channel(ChCounter).nSamples = length(DataStruct.Channel(ChCounter).Data);
                else
                    DataStruct.Channel(ChCounter) = []; %rempve channel
                    DataStruct.nChannels = DataStruct.nChannels -1;
                end
        end
    end
catch ME
    fclose(fid);
    errorstr = ['ERROR: NSB_FIFreader >> : ',ME.message];
    if ~isempty(options.logfile)
        status = NSBlog(options.logfile,errorstr);
    else
        errordlg(errorstr,'NSB_FIFreader');
    end
end

function RecordSamples = getRecordnSamples(type,size,channels,FIFFdef)
switch type
    case FIFFdef.dau_pac16
        RecordSamples = size/(2*channels);
    case FIFFdef.int16
        RecordSamples = size/(2*channels);
    case FIFFdef.float
        RecordSamples = size/(4*channels);
    case FIFF.FIFFT_INT
        RecordSamples = size/(4*channels);
    otherwise
        RecordSamples = [];
end


