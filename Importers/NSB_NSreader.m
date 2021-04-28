function [DataStruct,status, msg] = NSB_NSreader(filepath,filename,options)
% Because there is no Animal ID - Use Filename
%
%

status = false; msg = '';
DataStruct = [];
if nargin == 2
    options.progress = true;
    options.logfile = '';
    options.Licensing = [];
else
    
end

clean = @(in_str) (regexprep(in_str, '[_<>:"?*\s]', '-', 'preservecase'));
noNull = @(str) regexprep(str,char(0),char(32));

try
    if ~isempty(options.chans)
        %load header to validate inputs
        NS_Data = openNSx(fullfile(filepath,filename) , 'noread' );
    chanstr = 'c:';
    for n = 1:length(options.chans)
        if isnumeric(options.chans(n).Name)
            if ~isnan(options.chans(n).Name)
                chanstr = [chanstr,num2str(options.chans(n).Name),','];
            else
                %siently skip the channel that was deleted in study design
                %file
                continue;
            end
        else
            %openNSx cannot handle channel names only channel numbers
            if length(options.chans(n).Name) == length(regexp(options.chans(n).Name,'\d'))
                %this is a number formatted as a string
                chanstr = [chanstr,options.chans(n).Name,','];
            else
                %find channel
                electrodeID = [];
                for curChan = 1:length(NS_Data.ElectrodesInfo)
                    if strfind(NS_Data.ElectrodesInfo(curChan).Label,options.chans(n).Name)
                        electrodeID = NS_Data.ElectrodesInfo(curChan).ElectrodeID;
                        %NSx openNSx is broken and reports ElectrodeID as
                        %electrode numbers instead of the inputs needed to
                        %define ChannelIDs
                        electrodeID = find(electrodeID == NS_Data.MetaTags.ChannelID,1,'first');
                        break;
                    end
                end
                if isempty(electrodeID)
                    infostr = ['Warning: NSB_NSreader >> File does not contain channel named: ', options.chans(n).Name];
                    %status = false;
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        disp(infostr);
                    end
                else
                    chanstr = [chanstr,num2str(electrodeID),','];
                end
            end
        end
    end
    chanstr(end) = [];
    NS_Data = openNSx(fullfile(filepath,filename) , 'read', 'p:double', 'uV', chanstr );
    else     
    NS_Data = openNSx(fullfile(filepath,filename) , 'read', 'p:double', 'uV' );
    end
catch ME
    msg = ['ERROR: NSB_NSreader >> ',ME.message];
    if ~isempty(ME.stack)
        msg = [msg,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
    end
    return;
end
if isempty(NS_Data) || isnumeric(NS_Data)
      msg = ['ERROR: openNSx >> Function did not return data. Contact Customer Support.'];
    return;  
end

%map data
try
DataStruct.Version = NS_Data.MetaTags.FileSpec;
DataStruct.SubjectID = clean(NS_Data.MetaTags.Filename);
DataStruct.Comment = NS_Data.MetaTags.Comment;
DataStruct.StartDate = datenum(NS_Data.MetaTags.DateTime);
DataStruct.FileFormat = NS_Data.MetaTags.FileExt;
DataStruct.Hz = NS_Data.MetaTags.SamplingFreq;
DataStruct.nSeconds = NS_Data.MetaTags.DataDurationSec;
DataStruct.nChannels = NS_Data.MetaTags.ChannelCount;
DataStruct.Filename = fullfile(NS_Data.MetaTags.FilePath, [NS_Data.MetaTags.Filename, NS_Data.MetaTags.FileExt]);
for curChan = 1:DataStruct.nChannels
    DataStruct.Channel(curChan).Name = clean( strtrim( noNull(NS_Data.ElectrodesInfo(curChan).Label)));
    DataStruct.Channel(curChan).ChNumber = NS_Data.ElectrodesInfo(curChan).ElectrodeID;
    DataStruct.Channel(curChan).Units = 'uV';
    %DataStruct.Channel.nSamples = [];
    DataStruct.Channel(curChan).Hz = DataStruct.Hz;
    DataStruct.Channel(curChan).Data = NS_Data.Data(curChan,:);
    DataStruct.Channel(curChan).PhysMin = NS_Data.ElectrodesInfo(curChan).MinAnalogValue;
    DataStruct.Channel(curChan).PhysMax = NS_Data.ElectrodesInfo(curChan).MaxAnalogValue;
    DataStruct.Channel(curChan).DigMin = NS_Data.ElectrodesInfo(curChan).MinDigiValue;
    DataStruct.Channel(curChan).DigMax = NS_Data.ElectrodesInfo(curChan).MaxDigiValue;
end
catch ME
    msg = ['ERROR: NSB_NSreader >> Error mapping data. ',ME.message];
    if ~isempty(ME.stack)
        msg = [msg,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
    end
    return;
end

status = true;