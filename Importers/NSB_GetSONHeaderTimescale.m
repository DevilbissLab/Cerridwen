function timescale = NSB_GetSONHeaderTimescale(string)
%Helper function for access into SON Library
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% October 20 2007
% Version 1.0
% =========================================================================


if iscell(string)
    string = char(string);
end

switch lower(string)
    case 'seconds'
        timescale = 1e6;
    case 'milliseconds'
        timescale = 1e3;
    case 'microseconds'
        timescale = 1e3;
    otherwise
        disp([lower(string), ' is not supported.'])
end