function [OutStr,OutVal,retVal] = NSB_ConvertVunits(cmd,Unit)
% NSB_ConvertVunits
%helper function to get/set/maintain units actross framework

retVal = false;
OutStr = '';
OutVal = [];
if ischar(Unit) %determine input type
    UnitLabel = Unit;
    Unit = [];
elseif isnumeric(Unit)
    UnitLabel = [];
else
    return;
end

switch lower(cmd)
    case 'get'
        if ~isempty(UnitLabel)
            switch lower(UnitLabel)
                case 'v'
                    OutStr = 'V';
                    OutVal = 1e0;
                case 'mv'
                    OutStr = 'mV';
                    OutVal = -1e3;
                case 'uv'
                    OutStr = 'uV';
                    OutVal = -1e6;
                case 'pv'
                    OutStr = 'pV';
                    OutVal = -1e9;
            end
        else
            switch Unit
                case 1
                    OutStr = 'V';
                    OutVal = 1e0;
                case -1e3
                    OutStr = 'mV';
                    OutVal = -1e3;
                case -1e6
                    OutStr = 'uV';
                    OutVal = -1e6;
                case -1e9
                    OutStr = 'pV';
                    OutVal = -1e9;
            end
        end
end
retVal = true;
        