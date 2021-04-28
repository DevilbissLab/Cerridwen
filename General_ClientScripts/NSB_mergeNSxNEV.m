function status = NSB_mergeNSxNEV(filename1,filename2,varargin)
%
% MAke sure to add the following paths: \NPMK and \NPMK\NSx Utilities
%


status = false;
%% Validating the input arguments. Exit with error message if error occurs.
%% Popup the Open File UI. Also, process the file name, path, and extension
%  for later use, and validate the entry.
if nargin < 3
    if exist('filename1','var') == 1
        if exist(filename1,'file') == 0
            fprintf(2, 'The first file %s does not exist.\n',filename1);
            filename1 = '';
        end
    else
        filename1 = '';
    end
    if  exist('filename2','var') == 1
        if exist(filename2,'file') == 0
            fprintf(2, 'The first file %s does not exist.\n',filename2);
            filename2 = '';
        end
    else
        filename2 = '';
    end
    
    if nargin < 2 || isempty(filename2)
        [fname, path] = uigetfile('*.ns1;*.ns2;*.ns3;*.ns4;*.ns5;*.ns6;*.ns6m', 'Choose a NSx file to be concatinated...');
        if fname == 0
            disp('No file was selected.');
            if nargout; varargout{1} = -1; end
            return;
        end
        filename2 = fullfile(path,fname);
        [~, ~, fext2] = fileparts(fname);
    else
        [~, ~, fext2] = fileparts(filename2);
    end
    if nargin < 1 || isempty(filename1)
        [fname, path] = uigetfile('*.ns1;*.ns2;*.ns3;*.ns4;*.ns5;*.ns6;*.ns6m', 'Choose the first NSx file...');
        if fname == 0
            disp('No file was selected.');
            if nargout; varargout{1} = -1; end
            return;
        end
        filename1 = fullfile(path,fname);
        [~, ~, fext1] = fileparts(fname);
    else
        [~, ~, fext1] = fileparts(filename1);
    end
    
%% Loading .x files for multiNSP configuration
%     if strcmpi(fext1(2:4), 'ns6') && length(fext1) == 5
%         path(1) = fname(end);
%         fname(end) = [];
%     end
    
else
    next = '';
    for i=1:length(varargin)
        inputArgument = varargin{i};
        if strcmpi(inputArgument, 'ver')
            varargout{1} = NSx.MetaTags.openNSxver;
            return;
        elseif strcmpi(inputArgument, 'channels')
            next = 'channels';
        elseif strcmpi(inputArgument, 'skipfactor')
            next = 'skipfactor';
        elseif strcmpi(inputArgument, 'electrodes')
            next = 'electrodes';
        elseif strcmpi(inputArgument, 'duration')
            next = 'duration';
        elseif strcmpi(inputArgument, 'precision')
            next = 'precision';
        elseif strcmpi(inputArgument, 'report')
            Report = inputArgument;
        elseif strcmpi(inputArgument, 'noread')
            ReadData = inputArgument;
        elseif strcmpi(inputArgument, 'nomultinsp')
            multinsp = 'no';
        elseif strcmpi(inputArgument, 'uV')
            waveformUnits = 'uV';
        elseif strcmpi(inputArgument, 'read')
            ReadData = inputArgument;
        elseif (strncmp(inputArgument, 't:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'duration')
            if strncmp(inputArgument, 't:', 2)
                inputArgument(1:2) = [];
                inputArgument = str2num(inputArgument);
            end
            modifiedTime = 1;
            StartPacket = inputArgument(1);
            EndPacket = inputArgument(end);
            next = '';
        elseif (strncmp(inputArgument, 'e:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'electrodes')
            if exist('KTUEAMapFile', 'file') == 2
                Mapfile = KTUEAMapFile;
                Elec = str2num(inputArgument(3:end)); %#ok<ST2NM>
                if min(Elec)<1 || max(Elec)>128
                    disp('The electrode number cannot be less than 1 or greater than 128.');
                    if nargout; varargout{1} = -1; end
                    return;
                end
                for chanIDX = 1:length(Elec)
                    userRequestedChannels(chanIDX) = Mapfile.Electrode2Channel(Elec(chanIDX));
                end
                elecReading = 1;
            else
                disp('To read data by ''electrodes'' the function KTUEAMapFile needs to be in path.');
                clear variables;
                if nargout; varargout{1} = -1; end
                return;
            end
            next = '';
        elseif (strncmp(inputArgument, 's:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'skipFactor')
            if strncmp(inputArgument, 's:', 2)
                skipFactor = str2num(inputArgument(3:end)); %#ok<ST2NM>
            else
                if ischar(inputArgument)
                    skipFactor = str2num(inputArgument);
                else
                    skipFactor = inputArgument;
                end
            end
            next = '';
        elseif (strncmp(inputArgument, 'c:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'channels')
            if strncmp(inputArgument, 'c:', 2)
                userRequestedChanRow = str2num(inputArgument(3:end)); %#ok<ST2NM>
            else
                userRequestedChanRow = inputArgument;
            end
            next = '';
        elseif (strncmp(varargin{i}, 'p:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'precision')
            if strncmp(varargin{i}, 'p:', 2)
                precisionTypeRaw = varargin{i}(3:end);
            else
                precisionTypeRaw = varargin{i};
            end
            switch precisionTypeRaw
                case 'int16'
                    precisionType = '*int16=>int16';
                case 'short'
                    precisionType = '*short=>short';
                case 'double'
                    precisionType = '*int16';
                otherwise
                    disp('Read type is not valid. Refer to ''help'' for more information.');
                    if nargout; varargout{1} = -1; end
                    return;
            end
            clear precisionTypeRaw;
            next = '';
        elseif strfind(' hour min sec sample ', [' ' inputArgument ' ']) ~= 0
            TimeScale = inputArgument;
        else
            temp = inputArgument;
            if length(temp)>3 && ...
                    (strcmpi(temp(3),'\') || ...
                    strcmpi(temp(1),'/') || ...
                    strcmpi(temp(2),'/') || ...
                    strcmpi(temp(1:2), '\\'))
                fname = inputArgument;
                if exist(fname, 'file') ~= 2
                    disp('The file does not exist.');
                    if nargout;
                        varargout{1} = -1;
                    end
                    return;
                end
            else
                disp(['Invalid argument ''' inputArgument ''' .']);
                if nargout; varargout{1} = -1; end
                return;
            end
        end
    end
    clear next;
end

%% NSB Code
clean = @(in_str) (regexprep(in_str, '[_<>:"?*]', '-', 'preservecase'));
%noNull = @(str) regexprep(str,char(0),char(32));

%Read headers
NSx1 = openNSx(filename1, 'noread' );
NSx2 = openNSx(filename2, 'noread' );

%calculate time gap between files
NSx1_startTime = datenum(NSx1.MetaTags.DateTime);
NSx1_startTime = addtodate(NSx1_startTime, NSx1.MetaTags.DateTimeRaw(end), 'millisecond');

NSx1_endTime = addtodate(NSx1_startTime, floor(NSx1.MetaTags.DataDurationSec), 'second');
NSx1_endTime = addtodate(NSx1_endTime, floor(rem(NSx1.MetaTags.DataDurationSec,1)*1e3), 'millisecond');

NSx2_startTime = datenum(NSx2.MetaTags.DateTime);
NSx2_startTime = addtodate(NSx2_startTime, NSx2.MetaTags.DateTimeRaw(end), 'millisecond');

NSx_timeGap = etime(datevec(NSx2_startTime),datevec(NSx1_endTime)); %in seconds
NSx_totalTime = NSx1.MetaTags.DataDurationSec + NSx_timeGap;
zerosBuffer = zeros(NSx1.MetaTags.ChannelCount,floor(NSx_timeGap*NSx1.MetaTags.SamplingFreq));

%read files
disp('Reading file data... Please wait.');
%NSx1 = openNSx(filename1, 'read', 'p:double', 'uV' );
NSx1 = openNSx(filename1, 'read', 'p:double');
NSx1.Data = [NSx1.Data, zerosBuffer];
NSx1.MetaTags.DataPoints = NSx_totalTime*NSx1.MetaTags.SamplingFreq;
NSx1.MetaTags.DataDurationSec = NSx_totalTime;

%Clean and update labels
for curChan = 1:NSx1.MetaTags.ChannelCount
    NSx1.ElectrodesInfo(curChan).Label = clean( NSx1.ElectrodesInfo(curChan).Label );
end

%Report Channel names (this is not necessarry but useful and can be better
%vectorized)
Labels = {NSx1.ElectrodesInfo(:).Label};

disp(['File gap is ',num2str(NSx_timeGap/60),' minutes.']);
disp(['Manipulation file start time: ',NSx2.MetaTags.DateTime]);
disp('File channel names:');
disp(Labels);

%Save Appended file
[path, fname, fext] = fileparts(filename1);
filename1a = fullfile(path,[fname,'_buffered',fext]);
disp('Saving appended file... Please wait.');
disp(filename1a);
saveNSx(NSx1,filename1a,'nowarn');

%Free memory
clear zerosBuffer NSx1 NSx2;

%Now do a fast merge
disp('Performing merge... Please wait.');
disp([filename1a, ' and ',filename2]);
mergeNSxNEV(filename1a, filename2, 'nowarning');
disp('Done merging files.');

status = false;

