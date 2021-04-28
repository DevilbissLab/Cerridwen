function output = NSB_uniqueDiffTS(input)
% input = datenum(s)
% output cell

cfun = @(in) datestr(in,'HH:MM:SS.FFF'); %function to force to ms precision

uDiff = num2cell(unique(diff(input)));
output = unique(cellfun(cfun,uDiff,'UniformOutput',false));