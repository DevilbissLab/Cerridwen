function [DataStruct,status, msg] = NSB_Resample(DataStruct, parameters)
% [DataStruct,status, msg] = NSB_Resample(DataStruct, parameters)
%
%

status = false; msg = [];
if nargin < 2
    msg = 'ERROR: NSB_Resample >> Incorrect number of input parameters';
        errordlg(msg,'NSB_Resample');
        return;
end
try
if ~isfield(parameters,'doResample')
parameters.doResample = false;
end

if parameters.doResample
    for n = 1:DataStruct.nChannels
        if DataStruct.Channel(n).Hz > parameters.newSampleRate
         DataStruct.Channel(n).Data = resample( DataStruct.Channel(n).Data, parameters.newSampleRate, DataStruct.Channel(n).Hz, parameters.InterpSamples );
        DataStruct.Channel(n).Hz = parameters.newSampleRate;
        end
    end 
end
catch ME
    msg = ME.message;
    return;
end
status = true;