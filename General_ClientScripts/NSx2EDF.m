function status = NSx2EDF(filename)
% NSx2EDF() - Conversion from blackrock to edf+ format
%
% Inputs:
%   filename            - (string - optional) Path and filename to open
%
% Outputs:
%   status              - (logical) whether the function completed successfully
%
% Dependencies:
%   lab_write_EDF
%   NPMK
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% April 27 2017, Version 0.9 First Beta Release
%

status = false;
try
if nargin == 1
    if ischar(filename)
        if exist(filename, 'file') == 0
            error('NSx2EDF input does not exist.')
        else
            [pathname, filename, ext] = fileparts(filename);
            filename = {[filename, ext]};
        end
    else
        error('NSx2EDF requires a string input or no input.')
    end
elseif nargin == 0
    [filename, pathname] = uigetfile( ...
       {'*.NS*','Blackrock files (*.NSx)'; 
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file', ...
        'MultiSelect', 'on');
    %path = string, filename = cell
    if ischar(filename)
        filename = {filename};
    end
else
     error('NSx2EDF requires a string input or no input.')
end
if ~ischar(pathname)
    warning('off','backtrace');
    warning('No file selected. Terminating NSx2EDF.');
    warning('on','backtrace');
    return;
end


for curFile = 1:length(filename)
    disp(['Reading ',fullfile(pathname,filename{curFile})]);
    NS_Data = openNSx(fullfile(pathname,filename{curFile}) , 'read', 'p:double', 'uV');

    HDR = NSx2EDFheader(NS_Data);
    disp(['Writing ',fullfile(pathname,filename{curFile})]);
    lab_write_edf(fullfile(pathname,filename{curFile}), NS_Data.Data, HDR);
end
catch ME
    disp(['Error:NSx2EDF >> ',ME.message, ' in ',ME.stack(1).name,' line: ',num2str(ME.stack(1).line)]);
end
status = true;

    
function HDR = NSx2EDFheader(NS_Data)

        noNull = @(str) regexprep(str,char(0),char(32));
        HDR = struct();
        HDR.samplingrate = NS_Data.MetaTags.SamplingFreq;
        HDR.channels = {NS_Data.ElectrodesInfo(:).Label};
        HDR.channels = cellfun(noNull,HDR.channels,'UniformOutput', false);
        HDR.channels = cellfun(@strtrim,HDR.channels,'UniformOutput', false);
        HDR.channels = HDR.channels';
        StartTime = datevec(NS_Data.MetaTags.DateTime);
        
        HDR.year         = StartTime(1);
        HDR.month        = StartTime(2);
        HDR.day          = StartTime(3);
        HDR.hour         = StartTime(4);
        HDR.minute       = StartTime(5);
        HDR.second       = StartTime(6);