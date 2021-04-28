function status = NSx2EDF(filename)
% NSx2EDF() - Conversion from blackrock to edf+ format
%
% Inputs:
%   filename            - (string - optional) Path and filename to open
%
% Outputs:
%   status              - (logical) whether the function completed successfully
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
        
        %HDR.subject.ID    = 'X';
        %HDR.subject.sex   = 'X';
        %HDR.subject.name  = 'X';
        %HDR.subject.year  = NaN;
        %HDR.subject.month = NaN;
        %HDR.subject.day   = NaN;
    
% Function for DMD     
% function [dataStruct, status] = NSx2DataStruct(NS_Data)
%     status = false; dataStruct = [];
%     dataStruct.Version = str2double(NS_Data.MetaTags.FileSpec);
%     dataStruct.SubjectID = '';
%     dataStruct.Comment = NS_Data.MetaTags.Comment; %this can contain other impotrant info
%     dataStruct.StartDate = datenum(NS_Data.MetaTags.DateTime);
%     dataStruct.FileFormat = NS_Data.MetaTags.FileTypeID;
%     dataStruct.nSeconds = NS_Data.MetaTags.DataPointsSec;
%     dataStruct.nChannels = NS_Data.MetaTags.ChannelCount;
%     dataStruct.FileName = NS_Data.MetaTags.Filename;
%     for curChan = 1:dataStruct.nChannels
%         dataStruct.Channel(curChan).Name = strtrim(NS_Data.ElectrodesInfo(curChan).Label);
%         dataStruct.Channel(curChan).ChNumber = NS_Data.ElectrodesInfo(curChan).ElectrodeID;
%         dataStruct.Channel(curChan).Units = NS_Data.ElectrodesInfo(curChan).AnalogUnits;
%         dataStruct.Channel(curChan).nSamples = length(NS_Data.Data(:,curChan));
%         dataStruct.Channel(curChan).Hz = NS_Data.MetaTags.SamplingFreq;
%         dataStruct.Channel(curChan).Data = NS_Data.Data(:,curChan);
%         dataStruct.Channel(curChan).MatrixLoc = NS_Data.ElectrodesInfo(curChan).ConnectorBank;
%         dataStruct.Channel(curChan).Type = NS_Data.ElectrodesInfo(curChan).Type;
%         dataStruct.Channel(curChan).Transducer = NS_Data.ElectrodesInfo(curChan).Type;
%         dataStruct.Channel(curChan).PhysMin = NS_Data.ElectrodesInfo(curChan).MinAnalogValue;
%         dataStruct.Channel(curChan).PhysMax = NS_Data.ElectrodesInfo(curChan).MaxAnalogValue;
%         dataStruct.Channel(curChan).DigMin = NS_Data.ElectrodesInfo(curChan).MinDigiValue;
%         dataStruct.Channel(curChan).DigMax = NS_Data.ElectrodesInfo(curChan).MaxDigiValue;
%         dataStruct.Channel(curChan).PreFilter = ['HP:',num2str(NS_Data.ElectrodesInfo(curChan).HighFreqCorner),'Hz LP:',num2str(NS_Data.ElectrodesInfo(curChan).LowFreqCorner),'Hz'];   
%     end
%     dataStruct.Hz = NS_Data.MetaTags.SamplingFreq;
%     %more can be added here    
    
    
    
    
    